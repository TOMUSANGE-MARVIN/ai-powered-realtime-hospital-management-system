import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

// Doctors block whole days (leave, conferences). Dates are calendar days,
// stored at midnight UTC to match how appointment dates are stored.

const dayOf = (value: unknown) => {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
  const d = new Date(`${value}T00:00:00.000Z`);
  return isNaN(d.getTime()) ? null : d;
};

/** Upcoming time off for a doctor (ranges that haven't ended yet). */
export const upcomingTimeOff = (doctorId: string) => {
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  return prisma.doctorTimeOff.findMany({
    where: { doctorId, endDate: { gte: today } },
    orderBy: { startDate: "asc" },
    select: { id: true, startDate: true, endDate: true, reason: true },
  });
};

export const listMyTimeOff = async (req: Request, res: Response) => {
  try {
    res.json(await upcomingTimeOff((req as any).user.id));
  } catch (error) {
    console.error("Error listing time off:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const addTimeOff = async (req: Request, res: Response) => {
  try {
    const doctor = (req as any).user;
    const start = dayOf(req.body.startDate);
    const end = dayOf(req.body.endDate ?? req.body.startDate);
    if (!start || !end) {
      return res.status(400).json({ message: "Dates must be YYYY-MM-DD" });
    }
    if (end < start) {
      return res.status(400).json({ message: "The end date is before the start date" });
    }
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);
    if (end < today) {
      return res.status(400).json({ message: "That time off is already in the past" });
    }
    if ((end.getTime() - start.getTime()) / 86400_000 > 180) {
      return res.status(400).json({ message: "Time off can be at most 6 months at a time" });
    }
    const entry = await prisma.doctorTimeOff.create({
      data: {
        doctorId: doctor.id,
        startDate: start,
        endDate: end,
        reason: typeof req.body.reason === "string" ? req.body.reason.trim().slice(0, 190) || null : null,
      },
    });
    // Existing bookings in the range aren't touched; the app lists them so
    // the doctor can reschedule or cancel each one with a reason.
    const clashes = await prisma.appointment.findMany({
      where: {
        doctorId: doctor.id,
        status: { in: ["requested", "scheduled", "confirmed"] },
        date: { gte: start, lt: new Date(end.getTime() + 86400_000) },
      },
      select: { id: true, patientName: true, date: true, time: true },
    });
    res.status(201).json({ timeOff: entry, clashes });
  } catch (error) {
    console.error("Error adding time off:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const deleteTimeOff = async (req: Request, res: Response) => {
  try {
    const { count } = await prisma.doctorTimeOff.deleteMany({
      where: { id: req.params.id as string, doctorId: (req as any).user.id },
    });
    if (!count) return res.status(404).json({ message: "Not found" });
    res.status(204).end();
  } catch (error) {
    console.error("Error deleting time off:", error);
    res.status(500).json({ message: "Server error" });
  }
};
