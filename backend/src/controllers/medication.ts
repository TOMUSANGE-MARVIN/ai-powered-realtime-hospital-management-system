import type { Request, Response } from "express";
import Medication from "../models/medication";
import { logActivity } from "../lib/activity";

export const getMedications = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;
    const search = (req.query.search as string) || "";

    const filter: any = {};
    if (search) filter.name = { $regex: search, $options: "i" };

    const total = await Medication.countDocuments(filter);
    const res_ = await Medication.find(filter)
      .sort({ name: 1 })
      .skip(skip)
      .limit(limit);

    res.json({
      res: res_,
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
    const medication = await Medication.create(req.body);
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
    const { id } = req.params;
    const medication = await Medication.findByIdAndUpdate(id, req.body, {
      new: true,
    });
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
    const { id } = req.params;
    const medication = await Medication.findByIdAndDelete(id);
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
