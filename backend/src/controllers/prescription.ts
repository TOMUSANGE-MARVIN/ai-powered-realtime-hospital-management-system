import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
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
    const { patient, patientName, items, notes } = req.body;

    const prescription = await prisma.prescription.create({
      data: {
        patient,
        patientName,
        doctor: currentUser.id,
        doctorName: currentUser.name,
        notes,
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
