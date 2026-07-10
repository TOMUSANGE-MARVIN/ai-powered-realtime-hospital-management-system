import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { inngest } from "../inngest/client";
import { logActivity } from "../lib/activity";

// Create a new lab result
export const createLabResult = async (req: Request, res: Response) => {
  try {
    const { patientId, testType, bodyPart, imageUrl } = req.body;
    const currentUserId = (req as any).user?.id;

    const newLabResult = await prisma.labResult.create({
      data: {
        patient: patientId,
        testType,
        bodyPart,
        imageUrl,
        status: "pending",
        uploadedBy: currentUserId,
        aiAnalysis: "Pending Analysis...",
      },
    });
    if (!newLabResult) {
      return res.status(400).json({ message: "Failed to create lab result" });
    }
    const io = req.app.get("io");
    if (io) {
      io.emit("lab_result_added");
    }
    if (testType === "X-Ray" && imageUrl && newLabResult) {
      // trigger an event in Inngest(analyze-xray) to analyze the x-ray image
      await inngest.send({
        name: "labResult/created",
        data: {
          labResultId: newLabResult.id,
          imageUrl: newLabResult.imageUrl,
          bodyPart: newLabResult.bodyPart,
        },
      });
      // trigger an event for billing
      await inngest.send({
        name: "billing/charge.added",
        data: {
          patientId: newLabResult.patient,
          description: `Radiology: ${newLabResult.bodyPart} X-Ray Analysis`,
          priceInCents: 15000, // $150.00
        },
      });
      await logActivity(
        currentUserId,
        "Uploaded Lab Result",
        `Uploaded ${testType} for ${bodyPart}`,
      );
    }
    res.status(201).json(newLabResult);
  } catch (error) {
    console.error("Error creating lab result:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

// 2b. Get all Lab Results across all patients (paginated, filterable) — used by Lab Requests/Results Entry pages
export const getAllLabResults = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;
    const status = req.query.status as string;

    const where: any = {};
    if (status && status !== "all") where.status = status;

    const [total, results] = await Promise.all([
      prisma.labResult.count({ where }),
      prisma.labResult.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
      }),
    ]);

    // Denormalize patient name/email
    const patientIds = [...new Set(results.map((r) => r.patient).filter(Boolean))];
    const patients = await prisma.user.findMany({
      where: { id: { in: patientIds } },
      select: { id: true, name: true, email: true },
    });
    const patientMap = new Map(patients.map((p) => [p.id, p]));

    const enriched = results.map((r) => ({
      ...r,
      patientName: patientMap.get(r.patient)?.name || "Unknown",
    }));

    res.json({
      res: enriched,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalData: total,
        limit,
      },
    });
  } catch (error) {
    console.error("Error fetching all lab results:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

// 2. Get all Lab Results for a specific patient
export const getPatientLabResults = async (req: Request, res: Response) => {
  try {
    const patientId = req.params.patientId as string;
    const results = await prisma.labResult.findMany({
      where: { patient: patientId },
      orderBy: { createdAt: "desc" },
    });
    res.status(200).json(results);
  } catch (error) {
    console.error("Error fetching lab results:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

// 3. Update Lab Result (Used for saving AI Analysis or Doctor Notes)
export const updateLabResult = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { aiAnalysis, doctorNotes, status } = req.body;

    const updatedResult = await prisma.labResult
      .update({
        where: { id },
        data: {
          ...(aiAnalysis && { aiAnalysis }),
          ...(doctorNotes && { doctorNotes }),
          ...(status && { status }),
        },
      })
      .catch(() => null);

    if (!updatedResult) {
      return res.status(404).json({ message: "Lab result not found" });
    }
    const io = req.app.get("io");
    if (io) {
      io.emit("lab_result_updated", updatedResult);
    }
    // TODO: notify users
    await logActivity(
      (req as any).user.id,
      "Updated Lab Result",
      `Updated lab result ${id} with status ${status || "N/A"}`,
    );
    res.status(200).json(updatedResult);
  } catch (error) {
    console.log(error);
    res.status(500).json({ message: "Internal server error" });
  }
};
