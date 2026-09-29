import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { priceConsultation } from "../lib/pricing";

// Pesapal can't take a zero-amount order, so a voucher never takes the
// charge below this.
export const MIN_CHARGE_UGX = 1000;

export class VoucherError extends Error {}

const normalize = (code: unknown) =>
  typeof code === "string" ? code.trim().toUpperCase() : "";

/**
 * Looks up `code` and works out its discount on `amount`. Throws
 * [VoucherError] with a patient-facing message when it can't be used.
 */
export async function priceWithVoucher(code: unknown, amount: number) {
  const normalized = normalize(code);
  if (!normalized) throw new VoucherError("Enter a voucher code");

  const voucher = await prisma.voucher.findUnique({ where: { code: normalized } });
  if (!voucher || !voucher.active) throw new VoucherError("This voucher code is not valid");
  if (voucher.expiresAt && voucher.expiresAt < new Date()) {
    throw new VoucherError("This voucher has expired");
  }
  if (voucher.maxUses != null && voucher.usedCount >= voucher.maxUses) {
    throw new VoucherError("This voucher has already been used up");
  }

  const raw =
    voucher.discountType === "percent"
      ? Math.round((amount * Math.min(voucher.value, 100)) / 100)
      : voucher.value;
  const discount = Math.max(0, Math.min(raw, amount - MIN_CHARGE_UGX));
  return { voucher, discount, total: amount - discount };
}

// Patient checks a code against a doctor's fee before paying.
export const validateVoucher = async (req: Request, res: Response) => {
  try {
    const { code, doctorId } = req.body;
    const doctor = await prisma.user.findFirst({
      where: { id: doctorId, role: "doctor" },
      select: { consultationFee: true },
    });
    if (!doctor?.consultationFee) {
      return res.status(400).json({ message: "This doctor has no consultation fee" });
    }
    if (!normalize(code)) {
      return res.status(400).json({ message: "Enter a voucher code" });
    }
    const price = await priceConsultation(doctor.consultationFee, code);
    res.json({ ...price, code: price.voucherCode });
  } catch (error) {
    if (error instanceof VoucherError) {
      return res.status(400).json({ message: error.message });
    }
    console.error("Error validating voucher:", error);
    res.status(500).json({ message: "Server error" });
  }
};

const parseVoucherBody = (body: any) => {
  const data: Record<string, unknown> = {};
  if (body.code !== undefined) data.code = normalize(body.code);
  if (body.discountType !== undefined) {
    if (!["fixed", "percent"].includes(body.discountType)) {
      throw new VoucherError('discountType must be "fixed" or "percent"');
    }
    data.discountType = body.discountType;
  }
  if (body.value !== undefined) {
    const value = parseInt(body.value);
    if (!(value > 0)) throw new VoucherError("value must be a positive number");
    data.value = value;
  }
  if (body.expiresAt !== undefined) {
    data.expiresAt = body.expiresAt ? new Date(body.expiresAt) : null;
  }
  if (body.maxUses !== undefined) {
    data.maxUses = body.maxUses === null || body.maxUses === "" ? null : parseInt(body.maxUses);
  }
  if (body.active !== undefined) data.active = Boolean(body.active);
  return data;
};

export const listVouchers = async (_req: Request, res: Response) => {
  try {
    const vouchers = await prisma.voucher.findMany({ orderBy: { createdAt: "desc" } });
    res.json(vouchers);
  } catch (error) {
    console.error("Error listing vouchers:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const createVoucher = async (req: Request, res: Response) => {
  try {
    const data = parseVoucherBody(req.body);
    if (!data.code || !data.discountType || !data.value) {
      return res
        .status(400)
        .json({ message: "code, discountType and value are required" });
    }
    const existing = await prisma.voucher.findUnique({
      where: { code: data.code as string },
    });
    if (existing) {
      return res.status(409).json({ message: "A voucher with this code already exists" });
    }
    const voucher = await prisma.voucher.create({ data: data as any });
    res.status(201).json(voucher);
  } catch (error) {
    if (error instanceof VoucherError) {
      return res.status(400).json({ message: error.message });
    }
    console.error("Error creating voucher:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const updateVoucher = async (req: Request, res: Response) => {
  try {
    const data = parseVoucherBody(req.body);
    const voucher = await prisma.voucher.update({
      where: { id: req.params.id as string },
      data,
    });
    res.json(voucher);
  } catch (error) {
    if (error instanceof VoucherError) {
      return res.status(400).json({ message: error.message });
    }
    console.error("Error updating voucher:", error);
    res.status(500).json({ message: "Server error" });
  }
};
