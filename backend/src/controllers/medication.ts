import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { logActivity } from "../lib/activity";

const normalizeMedicationInput = (body: any) => {
  const { expiryDate, ...rest } = body;
  return {
    ...rest,
    ...(expiryDate !== undefined && {
      expiryDate: expiryDate ? new Date(expiryDate) : null,
    }),
  };
};

export const getMedications = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;
    const search = (req.query.search as string) || "";

    const where: any = {};
    if (search) where.name = { contains: search };

    const [total, medications] = await Promise.all([
      prisma.medication.count({ where }),
      prisma.medication.findMany({
        where,
        orderBy: { name: "asc" },
        skip,
        take: limit,
      }),
    ]);

    res.json({
      res: medications,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalData: total,
        limit,
      },
    });
  } catch (error) {
    console.error("Error fetching medications:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const createMedication = async (req: Request, res: Response) => {
  try {
    const medication = await prisma.medication.create({
      data: normalizeMedicationInput(req.body),
    });
    const io = req.app.get("io");
    if (io) io.emit("medication_updated");
    await logActivity(
      (req as any).user.id,
      "Added Medication",
      `Added ${medication.name} to inventory`,
    );
    res.status(201).json(medication);
  } catch (error) {
    console.error("Error creating medication:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const updateMedication = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const medication = await prisma.medication
      .update({ where: { id }, data: normalizeMedicationInput(req.body) })
      .catch(() => null);
    if (!medication) {
      return res.status(404).json({ message: "Medication not found" });
    }
    const io = req.app.get("io");
    if (io) io.emit("medication_updated");
    await logActivity(
      (req as any).user.id,
      "Updated Medication",
      `Updated ${medication.name}`,
    );
    res.json(medication);
  } catch (error) {
    console.error("Error updating medication:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const deleteMedication = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const medication = await prisma.medication.delete({ where: { id } }).catch(() => null);
    if (!medication) {
      return res.status(404).json({ message: "Medication not found" });
    }
    const io = req.app.get("io");
    if (io) io.emit("medication_updated");
    await logActivity(
      (req as any).user.id,
      "Removed Medication",
      `Removed ${medication.name} from inventory`,
    );
    res.json({ message: "Medication deleted" });
  } catch (error) {
    console.error("Error deleting medication:", error);
    res.status(500).json({ message: "Server error" });
  }
};
