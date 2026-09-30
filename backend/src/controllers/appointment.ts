import type { Request, Response } from "express";
import crypto from "crypto";
import { prisma } from "../lib/prisma";
import { bookPaidPayment, insertAppointment } from "../lib/booking";
import { formatVisit, notifyUser } from "../lib/notify";
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

    const appointment = await prisma.appointment.create({
      data: {
        patientName,
        patientEmail,
        patientPhone,
        department,
        date: new Date(date),
        time,
        reason,
        status: "requested",
      },
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

    const where: any = {};
    if (status && status !== "all") where.status = status;
    if (isVirtual === "true") where.isVirtual = true;

    const [total, results] = await Promise.all([
      prisma.appointment.count({ where }),
      prisma.appointment.findMany({
        where,
        orderBy: { date: "asc" },
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
    console.error("Error fetching appointments:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Staff creates an appointment directly (e.g. for a walk-in or phone booking)
export const createAppointment = async (req: Request, res: Response) => {
  try {
    const { date, ...rest } = req.body;
    const appointment = await prisma.appointment.create({
      data: {
        ...rest,
        date: new Date(date),
        status: req.body.status || "scheduled",
      },
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

type AppointmentRow = NonNullable<Awaited<ReturnType<typeof prisma.appointment.findUnique>>>;

/** Tells the patient what changed about their appointment. */
async function notifyPatientOfChange(before: AppointmentRow, after: AppointmentRow) {
  const doctor = after.doctorName || "Your doctor";
  const visit = formatVisit(after.date, after.time);
  const link = "/home/appointments";
  if (after.status !== before.status) {
    const byStatus: Record<string, { title: string; message: string }> = {
      confirmed: { title: "Appointment confirmed", message: `${doctor} confirmed your visit on ${visit}.` },
      cancelled: {
        title: "Appointment cancelled",
        message: `${doctor} ${before.status === "requested" ? "declined" : "cancelled"} your visit on ${visit}.${after.cancellationReason ? ` Reason: ${after.cancellationReason}` : ""}${after.paymentId ? " Contact support about your payment." : ""}`,
      },
      in_progress: { title: "Your consultation has started", message: `${doctor} is ready for your visit now.` },
      completed: {
        title: "How was your visit?",
        message: after.notes
          ? `${doctor} added a visit summary. Read it and rate your consultation.`
          : `Rate your consultation with ${doctor}.`,
      },
    };
    const text = byStatus[after.status];
    if (text) await notifyUser(after.patientId, { type: "appointment", link, ...text });
    return;
  }
  if (after.date.getTime() !== before.date.getTime() || after.time !== before.time) {
    await notifyUser(after.patientId, {
      type: "appointment",
      title: "Appointment rescheduled",
      message: `${doctor} moved your visit to ${visit}.`,
      link,
    });
  }
}

// Status changes a doctor may make on their own appointments.
const DOCTOR_TRANSITIONS: Record<string, string[]> = {
  requested: ["confirmed", "cancelled"],
  scheduled: ["confirmed", "cancelled"],
  confirmed: ["in_progress", "completed", "cancelled"],
  in_progress: ["completed"],
};

export const updateAppointment = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const user = (req as any).user;

    const before = await prisma.appointment.findUnique({ where: { id } });

    // Doctors (mobile app) may only touch their own appointments, only these
    // fields, and only along the normal consultation flow. Admins and nurses
    // keep full access from the web.
    if (user.role === "doctor") {
      const current = before;
      if (!current || current.doctorId !== user.id) {
        return res.status(404).json({ message: "Appointment not found" });
      }
      const allowed = ["status", "date", "time", "notes", "cancellationReason"];
      const extra = Object.keys(req.body).filter((k) => !allowed.includes(k));
      if (extra.length) {
        return res.status(400).json({ message: `Doctors can't change: ${extra.join(", ")}` });
      }
      const { status } = req.body;
      if (status && status !== current.status) {
        if (!DOCTOR_TRANSITIONS[current.status]?.includes(status)) {
          return res.status(400).json({
            message: `Can't move a ${current.status.replace("_", " ")} appointment to ${String(status).replace("_", " ")}`,
          });
        }
      }
      if ((req.body.date !== undefined || req.body.time !== undefined) &&
          !["requested", "scheduled", "confirmed"].includes(current.status)) {
        return res.status(400).json({ message: "Only upcoming appointments can be rescheduled" });
      }
    }

    const { status, doctorId, doctorName, nurseId, isVirtual, date, ...rest } =
      req.body;

    const update: any = { ...rest };
    if (status === "cancelled" && before?.status !== "cancelled") {
      update.cancelledBy = user.role === "doctor" ? "doctor" : "admin";
      if (typeof req.body.cancellationReason === "string") {
        update.cancellationReason = req.body.cancellationReason.trim().slice(0, 500) || null;
      }
    }
    if (date !== undefined) update.date = new Date(date);
    if (status) update.status = status;
    if (doctorId !== undefined) update.doctorId = doctorId;
    if (doctorName !== undefined) update.doctorName = doctorName;
    if (nurseId !== undefined) update.nurseId = nurseId;
    if (isVirtual !== undefined) update.isVirtual = isVirtual;

    // Generate a meeting id the first time a virtual appointment is confirmed
    if (isVirtual && (status === "confirmed" || status === "in_progress")) {
      const existing = await prisma.appointment.findUnique({ where: { id } });
      if (existing && !existing.meetingId) {
        update.meetingId = crypto.randomUUID();
      }
    }

    const appointment = await prisma.appointment
      .update({ where: { id }, data: update })
      .catch(() => null);
    if (!appointment) {
      return res.status(404).json({ message: "Appointment not found" });
    }

    if (before) await notifyPatientOfChange(before, appointment);

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

// Authenticated patient books an appointment with a specific doctor (mobile app)
export const bookAppointment = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const {
      doctorId,
      date,
      time,
      reason,
      consultationType,
      department,
      isEmergency,
      paymentId,
    } = req.body;

    if (!doctorId || !date) {
      return res
        .status(400)
        .json({ message: "doctorId and date are required" });
    }

    const doctor = await prisma.user.findFirst({
      where: { id: doctorId, role: "doctor" },
      select: { name: true, department: true, consultationFee: true },
    });

    if (!doctor) {
      return res.status(404).json({ message: "Doctor not found" });
    }

    // Pay-before-book: if the doctor charges a fee, the booking must carry a
    // paid, unused payment belonging to this patient for this doctor.
    if (doctor.consultationFee) {
      if (!paymentId) {
        return res
          .status(402)
          .json({ message: "Payment is required before booking this doctor" });
      }
      const payment = await prisma.payment.findFirst({
        where: { id: paymentId, patientId: patient.id, doctorId },
      });
      if (!payment) {
        return res.status(404).json({ message: "Payment not found" });
      }
      if (payment.status !== "paid") {
        return res.status(402).json({ message: "Payment has not been completed" });
      }
      // The server may already have booked it when Pesapal confirmed the
      // payment; hand that appointment back instead of failing.
      const existing = await prisma.appointment.findUnique({ where: { paymentId } });
      if (existing) return res.status(200).json(existing);
    }

    let appointment;
    try {
      appointment = await insertAppointment({
        patient,
        doctor: { id: doctorId, ...doctor },
        details: { date, time, reason, consultationType, department, isEmergency },
        paymentId: doctor.consultationFee ? paymentId : null,
      });
    } catch (error: any) {
      // Lost a race with the server-side booking for the same payment.
      if (error?.code === "P2002" && paymentId) {
        const linked = await bookPaidPayment(paymentId);
        if (linked) return res.status(200).json(linked);
      }
      throw error;
    }

    const io = req.app.get("io");
    if (io) io.emit("appointment_updated");
    await logActivity(
      patient.id,
      "Booked Appointment",
      `Booked appointment with ${doctor.name}`,
    );

    res.status(201).json(appointment);
  } catch (error) {
    console.error("Error booking appointment:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Authenticated patient's own appointments (mobile app "My Appointments")
export const getMyAppointments = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;

    const where = { patientId: patient.id };
    const [total, results] = await Promise.all([
      prisma.appointment.count({ where }),
      prisma.appointment.findMany({
        where,
        orderBy: { date: "desc" },
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
    console.error("Error fetching my appointments:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Patient cancels their own appointment
export const cancelMyAppointment = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const id = req.params.id as string;

    const appointment = await prisma.appointment.findUnique({ where: { id } });
    if (!appointment) {
      return res.status(404).json({ message: "Appointment not found" });
    }
    if (appointment.patientId !== patient.id) {
      return res.status(403).json({ message: "Forbidden" });
    }
    if (!["requested", "scheduled", "confirmed"].includes(appointment.status)) {
      return res.status(400).json({ message: "Only upcoming appointments can be cancelled" });
    }

    const reason =
      typeof req.body?.reason === "string" ? req.body.reason.trim().slice(0, 500) : "";
    const updated = await prisma.appointment.update({
      where: { id },
      data: { status: "cancelled", cancelledBy: "patient", cancellationReason: reason || null },
    });
    await notifyUser(updated.doctorId, {
      type: "appointment",
      title: "Appointment cancelled",
      message: `${updated.patientName} cancelled their visit on ${formatVisit(updated.date, updated.time)}.${updated.cancellationReason ? ` Reason: ${updated.cancellationReason}` : ""}`,
      link: "/doctor-home/appointments",
    });

    const io = req.app.get("io");
    if (io) io.emit("appointment_updated");

    res.json(updated);
  } catch (error) {
    console.error("Error cancelling appointment:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Patient moves one of their own upcoming appointments. It goes back to
// "requested" so the doctor confirms the new slot.
export const rescheduleMyAppointment = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const id = req.params.id as string;
    const { date, time } = req.body;

    const newDate = date ? new Date(date) : null;
    if (!newDate || isNaN(newDate.getTime())) {
      return res.status(400).json({ message: "A valid date is required" });
    }
    if (newDate < new Date()) {
      return res.status(400).json({ message: "Choose a time in the future" });
    }

    const appointment = await prisma.appointment.findUnique({ where: { id } });
    if (!appointment) {
      return res.status(404).json({ message: "Appointment not found" });
    }
    if (appointment.patientId !== patient.id) {
      return res.status(403).json({ message: "Forbidden" });
    }
    if (!["requested", "scheduled", "confirmed"].includes(appointment.status)) {
      return res
        .status(400)
        .json({ message: "Only upcoming appointments can be rescheduled" });
    }

    const updated = await prisma.appointment.update({
      where: { id },
      data: { date: newDate, time: time || null, status: "requested" },
    });
    await notifyUser(updated.doctorId, {
      type: "appointment",
      title: "Reschedule request",
      message: `${updated.patientName} asked to move their visit to ${formatVisit(updated.date, updated.time)}. Please confirm the new time.`,
      link: "/doctor-home/appointments",
    });

    const io = req.app.get("io");
    if (io) io.emit("appointment_updated");

    res.json(updated);
  } catch (error) {
    console.error("Error rescheduling appointment:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Doctor's own assigned appointments (mobile doctor app dashboard/appointments tab)
export const getAssignedAppointments = async (req: Request, res: Response) => {
  try {
    const doctor = (req as any).user;
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;
    const status = req.query.status as string;
    const date = req.query.date as string;

    const where: any = { doctorId: doctor.id };
    if (status && status !== "all") where.status = status;
    if (date) {
      const start = new Date(date);
      start.setHours(0, 0, 0, 0);
      const end = new Date(date);
      end.setHours(23, 59, 59, 999);
      where.date = { gte: start, lte: end };
    }

    const [total, results] = await Promise.all([
      prisma.appointment.count({ where }),
      prisma.appointment.findMany({
        where,
        // Emergencies surface first so the doctor sees them immediately.
        orderBy: [{ isEmergency: "desc" }, { date: "asc" }],
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
    console.error("Error fetching assigned appointments:", error);
    res.status(500).json({ message: "Server error" });
  }
};
