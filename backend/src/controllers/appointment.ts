import type { Request, Response } from "express";
import crypto from "crypto";
import { prisma } from "../lib/prisma";
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

export const updateAppointment = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { status, doctorId, doctorName, nurseId, isVirtual, date, ...rest } =
      req.body;

    const update: any = { ...rest };
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
      const alreadyUsed = await prisma.appointment.findFirst({
        where: { paymentId },
        select: { id: true },
      });
      if (alreadyUsed) {
        return res
          .status(409)
          .json({ message: "This payment is already linked to an appointment" });
      }
    }

    // Emergencies need immediate attention — the date is always today.
    const appointmentDate = isEmergency ? new Date() : new Date(date);

    const appointment = await prisma.appointment.create({
      data: {
        patientId: patient.id,
        patientName: patient.name,
        patientEmail: patient.email,
        doctorId,
        doctorName: doctor.name,
        department: department || doctor.department,
        date: appointmentDate,
        time,
        reason,
        consultationType,
        isVirtual: consultationType !== "in_person" && consultationType !== "physical",
        isEmergency: !!isEmergency,
        paymentId: doctor.consultationFee ? paymentId : undefined,
        status: "requested",
        fee: doctor.consultationFee ?? undefined,
      },
    });

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

    const updated = await prisma.appointment.update({
      where: { id },
      data: { status: "cancelled" },
    });

    const io = req.app.get("io");
    if (io) io.emit("appointment_updated");

    res.json(updated);
  } catch (error) {
    console.error("Error cancelling appointment:", error);
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
