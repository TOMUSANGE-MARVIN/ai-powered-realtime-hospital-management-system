import { prisma } from "./prisma";
import { priceWithVoucher } from "../controllers/voucher";

/** Billing tax rate set by the admin (Settings → Billing), in percent. */
async function taxRatePercent(): Promise<number> {
  const setting = await prisma.setting.findUnique({ where: { key: "billing" } });
  const rate = Number((setting?.data as any)?.taxRatePercent ?? 0);
  return Number.isFinite(rate) && rate > 0 ? rate : 0;
}

/**
 * What a patient pays for a consultation: the doctor's fee, minus any
 * voucher, plus tax on the discounted amount. Throws `VoucherError` for an
 * unusable code.
 */
export async function priceConsultation(fee: number, voucherCode?: unknown) {
  let discount = 0;
  let appliedCode: string | null = null;
  if (voucherCode) {
    const priced = await priceWithVoucher(voucherCode, fee);
    discount = priced.discount;
    appliedCode = priced.voucher.code;
  }
  const rate = await taxRatePercent();
  const tax = Math.round(((fee - discount) * rate) / 100);
  return {
    amount: fee,
    discount,
    tax,
    taxRatePercent: rate,
    total: fee - discount + tax,
    voucherCode: appliedCode,
  };
}
