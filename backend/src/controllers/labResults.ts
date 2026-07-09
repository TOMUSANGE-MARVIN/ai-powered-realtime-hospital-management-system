import type { Request, Response } from "express";
import mongoose from "mongoose";
import LabResult from "../models/labResults";
import { inngest } from "../inngest/client";
import { logActivity } from "../lib/activity";

// Create a new lab result
export const createLabResult = async (req: Request, res: Response) => {
  try {
    const { patientId, testType, bodyPart, imageUrl } = req.body;
    const currentUserId = (req as any).user?.id;

    const newLabResult = await LabResult.create({
      patient: patientId,
      testType,
      bodyPart,
      imageUrl,
      status: "pending",
      uploadedBy: currentUserId,
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
          labResultId: newLabResult._id.toString(),
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

    const filter: any = {};
    if (status && status !== "all") filter.status = status;

    const total = await LabResult.countDocuments(filter);
    const results = await LabResult.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    // Denormalize patient name/email since "user" isn't a registered Mongoose model
    const patientIds = [
      ...new Set(results.map((r) => r.patient?.toString()).filter(Boolean)),
    ];
    const patientQueryIds: (string | mongoose.Types.ObjectId)[] = patientIds.map(
      (id) => (id.length === 24 ? new mongoose.Types.ObjectId(id) : id),
    );

    const patients = await mongoose.connection
      .collection("user")
      .find(
        { _id: { $in: patientQueryIds } as any },
        { projection: { name: 1, email: 1 } },
      )
      .toArray();
    const patientMap = new Map(patients.map((p) => [p._id.toString(), p]));

    const enriched = results.map((r) => ({
      ...r,
      patientName: patientMap.get(r.patient?.toString())?.name || "Unknown",
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
    const { patientId } = req.params;
    const results = await LabResult.find({ patient: patientId }).sort({
      createdAt: -1,
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
    const { id } = req.params;
    const { aiAnalysis, doctorNotes, status } = req.body;
    const updatedResult = await LabResult.findByIdAndUpdate(
      id,
      {
        $set: {
          ...(aiAnalysis && { aiAnalysis }),
          ...(doctorNotes && { doctorNotes }),
          ...(status && { status }),
        },
      },
      { new: true }, // Return the updated document
    );

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
