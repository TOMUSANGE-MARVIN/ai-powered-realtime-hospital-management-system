import type { Request, Response } from "express";
import crypto from "crypto";
import Appointment from "../models/appointment";
import { logActivity } from "../lib/activity";

// Public endpoint — used by the marketing "Book Appointment" form (no auth)
export const requestAppointment = async (req: Request, res: Response) => {
  try {
    const {
      patientName,
      patientEmail,
      patientPhone,
      department,
      date,
      time,
      reason,
    } = req.body;

    if (!patientName || !patientEmail || !department || !date) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const appointment = await Appointment.create({
      patientName,
      patientEmail,
      patientPhone,
      department,
      date,
      time,
      reason,
      status: "requested",
    });

    const io = req.app.get("io");
    if (io) io.emit("appointment_updated");

    res.status(201).json(appointment);
  } catch (error) {
    console.error("Error requesting appointment:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getAppointments = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;
    const status = req.query.status as string;
    const isVirtual = req.query.isVirtual as string;

    const filter: any = {};
    if (status && status !== "all") filter.status = status;
    if (isVirtual === "true") filter.isVirtual = true;

    const total = await Appointment.countDocuments(filter);
    const results = await Appointment.find(filter)
      .sort({ date: 1 })
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
    console.error("Error fetching appointments:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Staff creates an appointment directly (e.g. for a walk-in or phone booking)
export const createAppointment = async (req: Request, res: Response) => {
  try {
    const appointment = await Appointment.create({
      ...req.body,
      status: req.body.status || "scheduled",
    });
    const io = req.app.get("io");
    if (io) io.emit("appointment_updated");
    await logActivity(
      (req as any).user.id,
      "Created Appointment",
      `Scheduled appointment for ${appointment.patientName}`,
    );
    res.status(201).json(appointment);
  } catch (error) {
    console.error("Error creating appointment:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const updateAppointment = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { status, doctorId, doctorName, nurseId, isVirtual, ...rest } =
      req.body;

    const update: any = { ...rest };
    if (status) update.status = status;
    if (doctorId !== undefined) update.doctorId = doctorId;
    if (doctorName !== undefined) update.doctorName = doctorName;
    if (nurseId !== undefined) update.nurseId = nurseId;
    if (isVirtual !== undefined) update.isVirtual = isVirtual;

    // Generate a meeting id the first time a virtual appointment is confirmed
    if (isVirtual && (status === "confirmed" || status === "in-progress")) {
      const existing = await Appointment.findById(id);
      if (existing && !existing.meetingId) {
        update.meetingId = crypto.randomUUID();
      }
    }

    const appointment = await Appointment.findByIdAndUpdate(id, update, {
      new: true,
    });
    if (!appointment) {
      return res.status(404).json({ message: "Appointment not found" });
    }

    const io = req.app.get("io");
    if (io) io.emit("appointment_updated");
    await logActivity(
      (req as any).user.id,
      "Updated Appointment",
      `Updated appointment for ${appointment.patientName} (${status || "details"})`,
    );
    res.json(appointment);
  } catch (error) {
    console.error("Error updating appointment:", error);
    res.status(500).json({ message: "Server error" });
  }
};
