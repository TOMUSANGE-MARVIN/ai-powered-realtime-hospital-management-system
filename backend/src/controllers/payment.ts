import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

// SIMULATED payment rail. The initiate → confirm shape is provider-agnostic:
// swapping in a real provider (e.g. MarzPay MoMo collections) later means
// initiate triggers the real prompt and confirm becomes a webhook/status
// poll — the mobile app's flow doesn't change.

// Patient starts a payment for a doctor's consultation fee before booking.
export const initiatePayment = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const { doctorId, method, phoneNumber } = req.body;

    if (!doctorId || !method) {
      return res.status(400).json({ message: "doctorId and method are required" });
    }

    const doctor = await prisma.user.findFirst({
      where: { id: doctorId, role: "doctor" },
      select: { consultationFee: true },
    });
    if (!doctor) {
      return res.status(404).json({ message: "Doctor not found" });
    }
    if (!doctor.consultationFee) {
      return res
        .status(400)
        .json({ message: "This doctor has no consultation fee configured" });
    }

    const payment = await prisma.payment.create({
      data: {
        patientId: patient.id,
        doctorId,
        amount: doctor.consultationFee,
        method,
        phoneNumber: phoneNumber || null,
        status: "pending",
      },
    });

    res.status(201).json(payment);
  } catch (error) {
    console.error("Error initiating payment:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Simulated confirmation — marks the pending payment as paid.
export const confirmPayment = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const id = req.params.id as string;

    const payment = await prisma.payment.findFirst({
      where: { id, patientId: patient.id },
    });
    if (!payment) {
      return res.status(404).json({ message: "Payment not found" });
    }
    if (payment.status !== "pending") {
      return res
        .status(400)
        .json({ message: `Payment is already ${payment.status}` });
    }

    const updated = await prisma.payment.update({
      where: { id },
      data: { status: "paid", reference: `SIM-${Date.now()}` },
    });

    res.json(updated);
  } catch (error) {
    console.error("Error confirming payment:", error);
    res.status(500).json({ message: "Server error" });
  }
};
