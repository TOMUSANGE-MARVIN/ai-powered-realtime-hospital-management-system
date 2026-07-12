import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

const sumFees = async (doctorId: string, from?: Date) => {
  const where: any = { doctorId, status: "completed" };
  if (from) where.date = { gte: from };
  const result = await prisma.appointment.aggregate({
    where,
    _sum: { fee: true },
    _count: true,
  });
  return { total: result._sum.fee ?? 0, count: result._count };
};

// Doctor's own earnings summary (mobile doctor app Earnings screen)
export const getMyEarnings = async (req: Request, res: Response) => {
  try {
    const doctor = (req as any).user;
    const now = new Date();

    const todayStart = new Date(now);
    todayStart.setHours(0, 0, 0, 0);

    const weekStart = new Date(now);
    weekStart.setDate(weekStart.getDate() - 7);

    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const yearStart = new Date(now.getFullYear(), 0, 1);

    const [today, week, month, year, allTime, virtual, inPerson, recent] =
      await Promise.all([
        sumFees(doctor.id, todayStart),
        sumFees(doctor.id, weekStart),
        sumFees(doctor.id, monthStart),
        sumFees(doctor.id, yearStart),
        sumFees(doctor.id),
        prisma.appointment.aggregate({
          where: { doctorId: doctor.id, status: "completed", isVirtual: true },
          _sum: { fee: true },
          _count: true,
        }),
        prisma.appointment.aggregate({
          where: {
            doctorId: doctor.id,
            status: "completed",
            isVirtual: false,
          },
          _sum: { fee: true },
          _count: true,
        }),
        prisma.appointment.findMany({
          where: { doctorId: doctor.id, status: "completed" },
          orderBy: { date: "desc" },
          take: 10,
        }),
      ]);

    res.json({
      totalEarnings: allTime.total,
      today: today.total,
      thisWeek: week.total,
      thisMonth: month.total,
      thisYear: year.total,
      availableBalance: allTime.total,
      pendingPayments: 0,
      consultationStats: {
        total: allTime.count,
        virtual: virtual._count,
        inPerson: inPerson._count,
      },
      revenueBreakdown: {
        virtual: virtual._sum.fee ?? 0,
        inPerson: inPerson._sum.fee ?? 0,
      },
      recentTransactions: recent.map((a) => ({
        id: a.id,
        patientName: a.patientName,
        amount: a.fee ?? 0,
        date: a.date,
        isVirtual: a.isVirtual,
      })),
    });
  } catch (error) {
    console.error("Error fetching earnings:", error);
    res.status(500).json({ message: "Server error" });
  }
};
