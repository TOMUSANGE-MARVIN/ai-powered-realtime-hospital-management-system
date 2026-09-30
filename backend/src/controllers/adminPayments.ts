import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { notifyUser } from "../lib/notify";
import { isPesapalConfigured, PesapalError, requestRefund } from "../lib/pesapal";
import { syncWithPesapal } from "./payment";

// Admin Payments page: every Pesapal transaction, status re-checks and refunds.

const PERIOD_DAYS: Record<string, number> = { week: 7, month: 30, quarter: 91, year: 365 };

/** Pesapal lets card payments be partly refunded; mobile money only in full. */
export const isCardMethod = (method: string | null) =>
  !!method && /visa|master|card|amex|american express|union ?pay/i.test(method);

export const listPayments = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit as string) || 20));
    const status = req.query.status as string | undefined;
    const methodType = req.query.method as string | undefined;
    const search = ((req.query.search as string) || "").trim();
    const days = PERIOD_DAYS[req.query.period as string];

    const base: any = {};
    if (days) base.createdAt = { gte: new Date(Date.now() - days * 86400_000) };

    const where: any = { ...base };
    if (status === "refund_requested") where.refundStatus = "requested";
    else if (status && status !== "all") where.status = status;
    if (search) {
      const users = await prisma.user.findMany({
        where: { name: { contains: search } },
        select: { id: true },
      });
      const ids = users.map((u) => u.id);
      where.OR = [
        { patientId: { in: ids } },
        { doctorId: { in: ids } },
        { reference: { contains: search } },
        { voucherCode: { contains: search } },
        { id: search },
      ];
    }

    const [all, bySum] = await Promise.all([
      prisma.payment.findMany({ where, orderBy: { createdAt: "desc" } }),
      prisma.payment.groupBy({
        by: ["status"],
        where: base,
        _sum: { amount: true, discount: true, tax: true },
        _count: { _all: true },
      }),
    ]);
    // Method type isn't a column, so filter it in memory before paging.
    const filtered =
      methodType === "card"
        ? all.filter((p) => isCardMethod(p.method))
        : methodType === "mobile"
          ? all.filter((p) => p.method !== "pesapal" && !isCardMethod(p.method))
          : all;
    const rows = filtered.slice((page - 1) * limit, page * limit);

    const userIds = [...new Set(rows.flatMap((p) => [p.patientId, p.doctorId]))];
    const [users, appointments, refundsRequested] = await Promise.all([
      prisma.user.findMany({
        where: { id: { in: userIds } },
        select: { id: true, name: true, email: true },
      }),
      prisma.appointment.findMany({
        where: { paymentId: { in: rows.map((p) => p.id) } },
        select: { id: true, paymentId: true, date: true, time: true, status: true, consultationType: true },
      }),
      prisma.payment.aggregate({
        where: { ...base, refundStatus: "requested" },
        _sum: { refundAmount: true },
        _count: { _all: true },
      }),
    ]);
    const userById = new Map(users.map((u) => [u.id, u]));
    const apptByPayment = new Map(appointments.map((a) => [a.paymentId, a]));
    const stat = (s: string) => bySum.find((g) => g.status === s);

    res.json({
      pesapalConfigured: isPesapalConfigured(),
      summary: {
        collected: stat("paid")?._sum.amount ?? 0,
        paidCount: stat("paid")?._count._all ?? 0,
        pendingCount: stat("pending")?._count._all ?? 0,
        failedCount: stat("failed")?._count._all ?? 0,
        refunded: stat("reversed")?._sum.amount ?? 0,
        refundedCount: stat("reversed")?._count._all ?? 0,
        refundsRequested: refundsRequested._count._all,
        refundsRequestedAmount: refundsRequested._sum.refundAmount ?? 0,
        discounts: (stat("paid")?._sum.discount ?? 0) + (stat("reversed")?._sum.discount ?? 0),
        tax: stat("paid")?._sum.tax ?? 0,
      },
      payments: rows.map((p) => ({
        ...p,
        methodType: p.method === "pesapal" ? null : isCardMethod(p.method) ? "card" : "mobile",
        patient: userById.get(p.patientId) ?? null,
        doctor: userById.get(p.doctorId) ?? null,
        appointment: apptByPayment.get(p.id) ?? null,
      })),
      pagination: { page, limit, total: filtered.length, totalPages: Math.ceil(filtered.length / limit) },
    });
  } catch (error) {
    console.error("Error listing payments:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const syncPayment = async (req: Request, res: Response) => {
  try {
    const payment = await prisma.payment.findUnique({ where: { id: req.params.id as string } });
    if (!payment) return res.status(404).json({ message: "Payment not found" });
    if (!isPesapalConfigured()) {
      return res.status(503).json({ message: "Pesapal isn't configured on this server" });
    }
    const updated = await syncWithPesapal(payment);
    res.json({ changed: updated.status !== payment.status, payment: updated });
  } catch (error) {
    console.error("Error syncing payment:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const refundPayment = async (req: Request, res: Response) => {
  try {
    const admin = (req as any).user;
    const { amount, reason, cancelAppointment } = req.body;
    const payment = await prisma.payment.findUnique({ where: { id: req.params.id as string } });
    if (!payment) return res.status(404).json({ message: "Payment not found" });

    // Pesapal's rules, checked here so the admin gets a clear answer.
    if (payment.status !== "paid") {
      return res.status(400).json({ message: "Only completed payments can be refunded" });
    }
    if (payment.refundStatus) {
      return res
        .status(400)
        .json({ message: "A refund was already requested — Pesapal allows one per payment" });
    }
    if (!payment.reference) {
      return res
        .status(400)
        .json({ message: "This payment has no Pesapal confirmation code yet. Sync it first." });
    }
    const value = amount === undefined ? payment.amount : Number(amount);
    if (!Number.isInteger(value) || value <= 0) {
      return res.status(400).json({ message: "Enter a whole UGX amount above 0" });
    }
    if (value > payment.amount) {
      return res
        .status(400)
        .json({ message: `You can't refund more than the UGX ${payment.amount.toLocaleString()} collected` });
    }
    if (value < payment.amount && !isCardMethod(payment.method)) {
      return res
        .status(400)
        .json({ message: "Mobile money payments can only be refunded in full" });
    }
    if (!reason?.trim()) {
      return res.status(400).json({ message: "Give a reason for the refund" });
    }
    if (!isPesapalConfigured()) {
      return res.status(503).json({ message: "Pesapal isn't configured on this server" });
    }

    try {
      await requestRefund({
        confirmationCode: payment.reference,
        amount: value,
        username: admin.email || admin.name,
        remarks: reason.trim(),
      });
    } catch (error) {
      if (error instanceof PesapalError) {
        return res.status(502).json({ message: error.message });
      }
      throw error;
    }

    const updated = await prisma.payment.update({
      where: { id: payment.id },
      data: {
        refundStatus: "requested",
        refundAmount: value,
        refundReason: reason.trim(),
        refundRequestedAt: new Date(),
        refundRequestedBy: admin.name,
      },
    });
    await notifyUser(payment.patientId, {
      type: "payment",
      title: "Refund on its way",
      message: `A refund of UGX ${value.toLocaleString()} has been requested. You'll receive it once Pesapal completes the refund.`,
      link: "/home/appointments",
    });
    if (cancelAppointment === true) {
      await prisma.appointment.updateMany({
        where: { paymentId: payment.id, status: { notIn: ["completed", "cancelled"] } },
        data: { status: "cancelled" },
      });
      const io = req.app.get("io");
      if (io) io.emit("appointment_updated");
    }
    res.json(updated);
  } catch (error) {
    console.error("Error refunding payment:", error);
    res.status(500).json({ message: "Server error" });
  }
};
