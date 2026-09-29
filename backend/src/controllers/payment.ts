import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import {
  getTransactionStatus,
  isPesapalConfigured,
  PesapalError,
  submitOrder,
} from "../lib/pesapal";
import { VoucherError } from "./voucher";
import { priceConsultation } from "../lib/pricing";

// Pay-before-book via Pesapal. The patient pays on Pesapal's hosted checkout
// (cards + mobile money), so this server never sees card details. Payment
// status is only ever taken from Pesapal's GetTransactionStatus.

type PaymentRecord = NonNullable<Awaited<ReturnType<typeof prisma.payment.findFirst>>>;

// Pesapal status_code → our payment.status. 0 (INVALID) also covers "not paid
// yet", so it leaves a pending payment pending.
const STATUS_BY_CODE: Record<number, string> = { 1: "paid", 2: "failed", 3: "reversed" };

/** Pulls the latest status from Pesapal and persists it. Never throws. */
async function syncWithPesapal(payment: PaymentRecord): Promise<PaymentRecord> {
  if (payment.status !== "pending" || !payment.orderTrackingId) return payment;
  try {
    const tx = await getTransactionStatus(payment.orderTrackingId);
    const status = STATUS_BY_CODE[tx.status_code];
    if (!status) return payment;
    const updated = await prisma.payment.update({
      where: { id: payment.id },
      data: {
        status,
        method: tx.payment_method || payment.method,
        reference: tx.confirmation_code || payment.reference,
      },
    });
    // A voucher counts as used only once its payment actually goes through.
    if (status === "paid" && payment.voucherCode) {
      await prisma.voucher.updateMany({
        where: { code: payment.voucherCode },
        data: { usedCount: { increment: 1 } },
      });
    }
    return updated;
  } catch (error) {
    // Pesapal answers unpaid orders with an error body — that's still "pending".
    if (!(error instanceof PesapalError)) console.error("Error syncing payment:", error);
    return payment;
  }
}

const toClient = (payment: PaymentRecord, redirectUrl?: string) => ({
  id: payment.id,
  amount: payment.amount,
  discount: payment.discount,
  tax: payment.tax,
  voucherCode: payment.voucherCode,
  currency: payment.currency,
  status: payment.status,
  method: payment.method,
  reference: payment.reference,
  ...(redirectUrl ? { redirectUrl } : {}),
});

// Patient starts paying a doctor's consultation fee; returns the Pesapal
// checkout URL for the app to open.
export const initiatePayment = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const { doctorId, phoneNumber, voucherCode } = req.body;

    if (!doctorId) {
      return res.status(400).json({ message: "doctorId is required" });
    }
    if (!isPesapalConfigured()) {
      return res.status(503).json({ message: "Online payments are not available right now" });
    }

    const doctor = await prisma.user.findFirst({
      where: { id: doctorId, role: "doctor" },
      select: { name: true, consultationFee: true },
    });
    if (!doctor) {
      return res.status(404).json({ message: "Doctor not found" });
    }
    if (!doctor.consultationFee) {
      return res
        .status(400)
        .json({ message: "This doctor has no consultation fee configured" });
    }

    // Re-price on the server — never trust an amount sent by the app.
    let price;
    try {
      price = await priceConsultation(doctor.consultationFee, voucherCode);
    } catch (error) {
      if (error instanceof VoucherError) {
        return res.status(400).json({ message: error.message });
      }
      throw error;
    }

    const payment = await prisma.payment.create({
      data: {
        patientId: patient.id,
        doctorId,
        amount: price.total,
        discount: price.discount,
        tax: price.tax,
        voucherCode: price.voucherCode,
        method: "pesapal",
        phoneNumber: phoneNumber || null,
        status: "pending",
      },
    });

    const [firstName, ...rest] = String(patient.name || "").trim().split(/\s+/);
    try {
      const order = await submitOrder({
        merchantReference: payment.id,
        amount: payment.amount,
        currency: payment.currency,
        description: `Consultation with ${doctor.name}`,
        email: patient.email,
        phone: phoneNumber,
        firstName: firstName || undefined,
        lastName: rest.join(" ") || undefined,
      });
      const updated = await prisma.payment.update({
        where: { id: payment.id },
        data: { orderTrackingId: order.order_tracking_id },
      });
      res.status(201).json(toClient(updated, order.redirect_url));
    } catch (error) {
      await prisma.payment.update({ where: { id: payment.id }, data: { status: "failed" } });
      throw error;
    }
  } catch (error) {
    console.error("Error initiating payment:", error);
    res.status(502).json({ message: "Could not start the payment. Please try again." });
  }
};

// What the patient will pay for a doctor, before any voucher — lets the app
// show tax up front. Vouchers are priced through /api/vouchers/validate.
export const getQuote = async (req: Request, res: Response) => {
  try {
    const doctor = await prisma.user.findFirst({
      where: { id: req.query.doctorId as string, role: "doctor" },
      select: { consultationFee: true },
    });
    if (!doctor?.consultationFee) {
      return res.status(400).json({ message: "This doctor has no consultation fee" });
    }
    res.json(await priceConsultation(doctor.consultationFee));
  } catch (error) {
    console.error("Error pricing consultation:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Patient's app polls this after returning from the Pesapal checkout.
export const getPaymentStatus = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const payment = await prisma.payment.findFirst({
      where: { id: req.params.id as string, patientId: patient.id },
    });
    if (!payment) {
      return res.status(404).json({ message: "Payment not found" });
    }
    res.json(toClient(await syncWithPesapal(payment)));
  } catch (error) {
    console.error("Error fetching payment status:", error);
    res.status(500).json({ message: "Server error" });
  }
};

async function syncByTrackingId(orderTrackingId: unknown) {
  if (typeof orderTrackingId !== "string" || !orderTrackingId) return null;
  const payment = await prisma.payment.findUnique({ where: { orderTrackingId } });
  return payment ? syncWithPesapal(payment) : null;
}

// Pesapal's server-to-server notification (registered as GET; POST accepted too).
export const pesapalIpn = async (req: Request, res: Response) => {
  const params = { ...req.query, ...(req.body || {}) } as Record<string, unknown>;
  const orderTrackingId = params.OrderTrackingId;
  const merchantReference = params.OrderMerchantReference;
  try {
    await syncByTrackingId(orderTrackingId);
    res.json({
      orderNotificationType: params.OrderNotificationType ?? "IPNCHANGE",
      orderTrackingId,
      orderMerchantReference: merchantReference,
      status: 200,
    });
  } catch (error) {
    console.error("Error handling Pesapal IPN:", error);
    res.status(500).json({
      orderNotificationType: params.OrderNotificationType ?? "IPNCHANGE",
      orderTrackingId,
      orderMerchantReference: merchantReference,
      status: 500,
    });
  }
};

// Where Pesapal sends the customer after checkout. The app's WebView closes as
// soon as it sees this URL; the page is only a fallback for a real browser.
export const pesapalCallback = async (req: Request, res: Response) => {
  let paid = false;
  try {
    const payment = await syncByTrackingId(req.query.OrderTrackingId);
    paid = payment?.status === "paid";
  } catch (error) {
    console.error("Error handling Pesapal callback:", error);
  }
  res
    .type("html")
    .send(
      `<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1">` +
        `<body style="font-family:system-ui,sans-serif;text-align:center;padding:48px 24px;color:#102828">` +
        `<h2>${paid ? "Payment received" : "Payment processing"}</h2>` +
        `<p>You can return to the Ask Musawo app.</p></body>`,
    );
};
