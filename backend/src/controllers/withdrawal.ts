import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { notifyUser } from "../lib/notify";

export const MIN_WITHDRAWAL_UGX = 5000;

// Withdrawals that still hold money back from the doctor's balance.
const OUTSTANDING = ["requested", "approved", "paid"];

type Db = Pick<typeof prisma, "appointment" | "withdrawal">;

/** Completed-visit earnings minus money already requested or paid out. */
export async function balancesFor(doctorId: string, db: Db = prisma) {
  const [earned, held, pending] = await Promise.all([
    db.appointment.aggregate({
      where: { doctorId, status: "completed" },
      _sum: { fee: true },
    }),
    db.withdrawal.aggregate({
      where: { doctorId, status: { in: OUTSTANDING } },
      _sum: { amount: true },
    }),
    db.withdrawal.aggregate({
      where: { doctorId, status: { in: ["requested", "approved"] } },
      _sum: { amount: true },
    }),
  ]);
  const total = earned._sum.fee ?? 0;
  return {
    available: Math.max(0, total - (held._sum.amount ?? 0)),
    pending: pending._sum.amount ?? 0,
  };
}

export const requestWithdrawal = async (req: Request, res: Response) => {
  try {
    const doctor = (req as any).user;
    const { amount, method, provider, accountName, accountNumber } = req.body;
    const parsed = parseInt(amount);

    if (!["mobile_money", "bank"].includes(method)) {
      return res.status(400).json({ message: "Choose mobile money or bank" });
    }
    if (!provider || !accountName?.trim() || !accountNumber?.trim()) {
      return res.status(400).json({ message: "Enter the account details" });
    }
    if (!(parsed >= MIN_WITHDRAWAL_UGX)) {
      return res
        .status(400)
        .json({ message: `The minimum withdrawal is UGX ${MIN_WITHDRAWAL_UGX.toLocaleString()}` });
    }

    // Balance check and insert in one transaction so two quick requests
    // can't both spend the same balance.
    const withdrawal = await prisma.$transaction(async (tx) => {
      const { available } = await balancesFor(doctor.id, tx);
      if (parsed > available) return null;
      return tx.withdrawal.create({
        data: {
          doctorId: doctor.id,
          doctorName: doctor.name,
          amount: parsed,
          method,
          provider,
          accountName: accountName.trim(),
          accountNumber: accountNumber.trim(),
        },
      });
    }, { isolationLevel: "Serializable" });
    if (!withdrawal) {
      return res.status(400).json({ message: "That is more than your available balance" });
    }

    const io = req.app.get("io");
    if (io) io.emit("withdrawal_updated");
    res.status(201).json(withdrawal);
  } catch (error) {
    console.error("Error requesting withdrawal:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getMyWithdrawals = async (req: Request, res: Response) => {
  try {
    const doctor = (req as any).user;
    const withdrawals = await prisma.withdrawal.findMany({
      where: { doctorId: doctor.id },
      orderBy: { createdAt: "desc" },
    });
    res.json(withdrawals);
  } catch (error) {
    console.error("Error fetching withdrawals:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const listWithdrawals = async (req: Request, res: Response) => {
  try {
    const status = req.query.status as string | undefined;
    const withdrawals = await prisma.withdrawal.findMany({
      where: status && status !== "all" ? { status } : {},
      orderBy: { createdAt: "desc" },
    });
    res.json(withdrawals);
  } catch (error) {
    console.error("Error listing withdrawals:", error);
    res.status(500).json({ message: "Server error" });
  }
};

const NEXT_STATUSES: Record<string, string[]> = {
  requested: ["approved", "rejected"],
  approved: ["paid", "rejected"],
};

export const updateWithdrawal = async (req: Request, res: Response) => {
  try {
    const { status, adminNote } = req.body;
    const withdrawal = await prisma.withdrawal.findUnique({
      where: { id: req.params.id as string },
    });
    if (!withdrawal) {
      return res.status(404).json({ message: "Withdrawal not found" });
    }
    if (!NEXT_STATUSES[withdrawal.status]?.includes(status)) {
      return res
        .status(400)
        .json({ message: `Can't move a ${withdrawal.status} withdrawal to ${status}` });
    }
    const updated = await prisma.withdrawal.update({
      where: { id: withdrawal.id },
      data: {
        status,
        adminNote: adminNote ?? withdrawal.adminNote,
        processedAt: status === "paid" || status === "rejected" ? new Date() : null,
      },
    });
    const amount = `UGX ${updated.amount.toLocaleString()}`;
    const text: Record<string, { title: string; message: string }> = {
      approved: { title: "Payout approved", message: `Your ${amount} withdrawal was approved and will be sent soon.` },
      paid: { title: "Payout sent", message: `${amount} was sent to your ${updated.provider} account.` },
      rejected: {
        title: "Payout rejected",
        message: `Your ${amount} withdrawal was rejected${updated.adminNote ? `: ${updated.adminNote}` : "."} The amount is back in your balance.`,
      },
    };
    const note = text[status];
    if (note) await notifyUser(updated.doctorId, { type: "payout", link: "/doctor-home/earnings", ...note });
    const io = req.app.get("io");
    if (io) io.emit("withdrawal_updated");
    res.json(updated);
  } catch (error) {
    console.error("Error updating withdrawal:", error);
    res.status(500).json({ message: "Server error" });
  }
};
