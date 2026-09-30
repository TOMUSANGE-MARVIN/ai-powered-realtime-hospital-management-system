import type { Request, Response } from "express";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { prisma } from "../lib/prisma";
import { notifyUser } from "../lib/notify";
import { logActivity } from "../lib/activity";

export const getPrescriptions = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;
    const status = req.query.status as string;

    const where: any = {};
    if (status && status !== "all") where.status = status;

    const [total, results] = await Promise.all([
      prisma.prescription.count({ where }),
      prisma.prescription.findMany({
        where,
        include: { items: true },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
      }),
    ]);

    res.json({
      res: results,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalData: total,
        limit,
      },
    });
  } catch (error) {
    console.error("Error fetching prescriptions:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const createPrescription = async (req: Request, res: Response) => {
  try {
    const currentUser = (req as any).user;
    const {
      patient,
      patientName,
      items,
      notes,
      imageUrl,
      signatureUrl,
      appointmentId,
      licenseNo,
      dateIssued,
    } = req.body;

    const prescription = await prisma.prescription.create({
      data: {
        patient,
        patientName,
        doctor: currentUser.id,
        doctorName: currentUser.name,
        notes,
        imageUrl,
        signatureUrl,
        appointmentId: appointmentId || null,
        licenseNo: licenseNo || null,
        dateIssued: dateIssued || null,
        status: "pending",
        items: {
          create: (items || []).map((item: any) => ({
            medication: item.medication || null,
            medicationName: item.medicationName,
            dosage: item.dosage,
            quantity: item.quantity ?? 1,
            instructions: item.instructions,
          })),
        },
      },
      include: { items: true },
    });

    await notifyUser(patient, {
      type: "prescription",
      title: "New prescription",
      message: `${currentUser.name} sent you a prescription with ${prescription.items.length} item${prescription.items.length === 1 ? "" : "s"}.`,
      link: "/home/profile",
    });
    const io = req.app.get("io");
    if (io) io.emit("prescription_updated");
    await logActivity(
      currentUser.id,
      "Created Prescription",
      `Prescribed ${items?.length || 0} item(s) for ${patientName}`,
    );
    res.status(201).json(prescription);
  } catch (error) {
    console.error("Error creating prescription:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Dispense: decrements medication stock and marks prescription as dispensed
export const dispensePrescription = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const currentUser = (req as any).user;

    const prescription = await prisma.prescription.findUnique({
      where: { id },
      include: { items: true },
    });
    if (!prescription) {
      return res.status(404).json({ message: "Prescription not found" });
    }
    if (prescription.status === "dispensed") {
      return res.status(400).json({ message: "Already dispensed" });
    }

    const updated = await prisma.$transaction(async (tx) => {
      // Decrement stock for each item that references a real medication
      for (const item of prescription.items) {
        if (item.medication) {
          await tx.medication.update({
            where: { id: item.medication },
            data: { stock: { decrement: Math.abs(item.quantity) } },
          });
        }
      }

      return tx.prescription.update({
        where: { id },
        data: {
          status: "dispensed",
          dispensedBy: currentUser.name,
          dispensedAt: new Date(),
        },
        include: { items: true },
      });
    });

    const io = req.app.get("io");
    if (io) {
      io.emit("prescription_updated");
      io.emit("medication_updated");
    }
    await logActivity(
      currentUser.id,
      "Dispensed Prescription",
      `Dispensed prescription for ${updated.patientName}`,
    );
    res.json(updated);
  } catch (error) {
    console.error("Error dispensing prescription:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Patient's own prescriptions (mobile app profile screen)
export const getMyPrescriptions = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;

    const where = { patient: patient.id };
    const [total, results] = await Promise.all([
      prisma.prescription.count({ where }),
      prisma.prescription.findMany({
        where,
        include: { items: true },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
      }),
    ]);

    res.json({
      res: results,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalData: total,
        limit,
      },
    });
  } catch (error) {
    console.error("Error fetching my prescriptions:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const cancelPrescription = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const prescription = await prisma.prescription
      .update({ where: { id }, data: { status: "cancelled" }, include: { items: true } })
      .catch(() => null);
    if (!prescription) {
      return res.status(404).json({ message: "Prescription not found" });
    }
    const io = req.app.get("io");
    if (io) io.emit("prescription_updated");
    res.json(prescription);
  } catch (error) {
    console.error("Error cancelling prescription:", error);
    res.status(500).json({ message: "Server error" });
  }
};

const genAI = new GoogleGenerativeAI(process.env.GEMINI_KEY!);
// Same folder src/routes/upload.ts writes to.
const UPLOADS_DIR = path.join(__dirname, "../../uploads");

// Doctor photographs a paper prescription; Gemini reads the header fields and
// medications so the doctor only has to check them. Nothing is saved here.
export const extractPrescription = async (req: Request, res: Response) => {
  try {
    const { imageUrl } = req.body;
    if (!imageUrl || typeof imageUrl !== "string") {
      return res.status(400).json({ message: "imageUrl is required" });
    }

    // Only photos the app uploaded to this server (/uploads/<file>) — read
    // from disk rather than fetching an arbitrary URL.
    let pathname = "";
    try {
      pathname = new URL(imageUrl).pathname;
    } catch {
      return res.status(400).json({ message: "Invalid imageUrl" });
    }
    if (!pathname.startsWith("/uploads/")) {
      return res.status(400).json({ message: "Upload the photo through the app first" });
    }
    const filePath = path.join(UPLOADS_DIR, path.basename(pathname));
    let buffer: Buffer;
    try {
      buffer = await readFile(filePath);
    } catch {
      return res.status(404).json({ message: "Photo not found" });
    }
    const ext = path.extname(filePath).toLowerCase();
    const mimeType =
      ext === ".png" ? "image/png" : ext === ".webp" ? "image/webp" : "image/jpeg";
    const data = buffer.toString("base64");

    const model = genAI.getGenerativeModel({
      model: "gemini-3-flash-preview",
      generationConfig: { responseMimeType: "application/json" },
    });
    const prompt = `This is a photo of a handwritten or printed medical prescription.
Read it and return JSON exactly in this shape:
{"quality": "good" | "poor", "dateIssued": "YYYY-MM-DD" | null, "doctorName": string | null, "licenseNo": string | null, "patientName": string | null, "medications": [{"name": string, "dosage": string, "quantity": number, "instructions": string | null}]}
"quality" is "poor" when the photo is blurry, dark, cut off or hard to read.
Use null for anything you cannot read with confidence. Never guess.`;

    const result = await model.generateContent([
      prompt,
      { inlineData: { data, mimeType } },
    ]);
    const text = result.response.text().replace(/```json/g, "").replace(/```/g, "").trim();
    const parsed = JSON.parse(text);

    res.json({
      quality: parsed.quality === "poor" ? "poor" : "good",
      dateIssued: parsed.dateIssued ?? null,
      doctorName: parsed.doctorName ?? null,
      licenseNo: parsed.licenseNo ?? null,
      patientName: parsed.patientName ?? null,
      medications: Array.isArray(parsed.medications)
        ? parsed.medications
            .filter((m: any) => m && typeof m.name === "string" && m.name.trim())
            .map((m: any) => ({
              name: m.name.trim(),
              dosage: typeof m.dosage === "string" ? m.dosage : "",
              quantity: Number.isInteger(m.quantity) && m.quantity > 0 ? m.quantity : 1,
              instructions: typeof m.instructions === "string" ? m.instructions : null,
            }))
        : [],
    });
  } catch (error) {
    console.error("Error extracting prescription:", error);
    res.status(502).json({ message: "Couldn't read the prescription. Fill in the details by hand." });
  }
};

// A doctor's own issued prescriptions, newest first.
export const getIssuedPrescriptions = async (req: Request, res: Response) => {
  try {
    const doctor = (req as any).user;
    const prescriptions = await prisma.prescription.findMany({
      where: { doctor: doctor.id },
      orderBy: { createdAt: "desc" },
      take: 100,
      include: { items: true },
    });
    res.json(prescriptions);
  } catch (error) {
    console.error("Error fetching issued prescriptions:", error);
    res.status(500).json({ message: "Server error" });
  }
};
