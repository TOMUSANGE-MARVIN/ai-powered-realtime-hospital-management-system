import type { Request, Response } from "express";
import Prescription from "../models/prescription";
import Medication from "../models/medication";
import { logActivity } from "../lib/activity";

export const getPrescriptions = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;
    const status = req.query.status as string;

    const filter: any = {};
    if (status && status !== "all") filter.status = status;

    const total = await Prescription.countDocuments(filter);
    const results = await Prescription.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

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

    const prescription = await Prescription.create({
      patient,
      patientName,
      doctor: currentUser.id,
      doctorName: currentUser.name,
      items,
      notes,
      status: "pending",
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
    const { id } = req.params;
    const currentUser = (req as any).user;

    const prescription = await Prescription.findById(id);
    if (!prescription) {
      return res.status(404).json({ message: "Prescription not found" });
    }
    if (prescription.status === "dispensed") {
      return res.status(400).json({ message: "Already dispensed" });
    }

    // Decrement stock for each item that references a real medication
    for (const item of prescription.items) {
      if (item.medication) {
        await Medication.findByIdAndUpdate(item.medication, {
          $inc: { stock: -Math.abs(item.quantity) },
        });
      }
    }

    prescription.status = "dispensed";
    prescription.dispensedBy = currentUser.name;
    prescription.dispensedAt = new Date();
    await prescription.save();

    const io = req.app.get("io");
    if (io) {
      io.emit("prescription_updated");
      io.emit("medication_updated");
    }
    await logActivity(
      currentUser.id,
      "Dispensed Prescription",
      `Dispensed prescription for ${prescription.patientName}`,
    );
    res.json(prescription);
  } catch (error) {
    console.error("Error dispensing prescription:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const cancelPrescription = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const prescription = await Prescription.findByIdAndUpdate(
      id,
      { status: "cancelled" },
      { new: true },
    );
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
