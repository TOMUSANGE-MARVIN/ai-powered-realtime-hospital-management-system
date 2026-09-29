import type { Request, Response } from "express";
import os from "node:os";
import { prisma } from "../lib/prisma";

// Admin "Platform Overview" dashboard. Every figure is computed from the
// database on request — nothing is cached or hard-coded.

type Period = "today" | "week" | "month" | "year";

const startOfDay = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
const startOfMonth = (d: Date) => new Date(d.getFullYear(), d.getMonth(), 1);
const startOfQuarter = (d: Date) =>
  new Date(d.getFullYear(), Math.floor(d.getMonth() / 3) * 3, 1);

/** % change from `before` to `now`, or null when there is no baseline. */
const change = (now: number, before: number) =>
  before > 0 ? Math.round(((now - before) / before) * 1000) / 10 : null;

/** Start of the dashboard's selected period. */
function periodStart(period: Period, now: Date) {
  if (period === "today") return startOfDay(now);
  if (period === "week") return startOfDay(new Date(now.getTime() - 6 * 86400_000));
  if (period === "month") return startOfMonth(now);
  return new Date(now.getFullYear(), 0, 1);
}

async function revenueSeries(period: Period, now: Date) {
  let from: Date;
  let buckets: { label: string; start: Date; end: Date }[] = [];
  if (period === "today") {
    from = startOfDay(now);
    for (let h = 0; h < 24; h += 3) {
      const start = new Date(from.getTime() + h * 3600_000);
      buckets.push({
        label: `${String(h).padStart(2, "0")}:00`,
        start,
        end: new Date(start.getTime() + 3 * 3600_000),
      });
    }
  } else if (period === "week") {
    from = startOfDay(new Date(now.getTime() - 6 * 86400_000));
    for (let i = 0; i < 7; i++) {
      const start = new Date(from.getTime() + i * 86400_000);
      buckets.push({
        label: start.toLocaleDateString("en-GB", { weekday: "short" }),
        start,
        end: new Date(start.getTime() + 86400_000),
      });
    }
  } else if (period === "month") {
    from = startOfMonth(now);
    const days = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
    for (let i = 0; i < days; i++) {
      const start = new Date(now.getFullYear(), now.getMonth(), i + 1);
      buckets.push({
        label: String(i + 1),
        start,
        end: new Date(now.getFullYear(), now.getMonth(), i + 2),
      });
    }
  } else {
    from = new Date(now.getFullYear(), 0, 1);
    for (let m = 0; m < 12; m++) {
      buckets.push({
        label: new Date(now.getFullYear(), m, 1).toLocaleDateString("en-GB", {
          month: "short",
        }),
        start: new Date(now.getFullYear(), m, 1),
        end: new Date(now.getFullYear(), m + 1, 1),
      });
    }
  }

  const payments = await prisma.payment.findMany({
    where: { status: "paid", createdAt: { gte: from } },
    select: { amount: true, createdAt: true },
  });
  return buckets.map((b) => ({
    label: b.label,
    revenue: payments
      .filter((p) => p.createdAt >= b.start && p.createdAt < b.end)
      .reduce((sum, p) => sum + p.amount, 0),
  }));
}

export const getOverview = async (req: Request, res: Response) => {
  const started = Date.now();
  try {
    const now = new Date();
    const period = (["today", "week", "month", "year"].includes(req.query.period as string)
      ? req.query.period
      : "month") as Period;
    const monthStart = startOfMonth(now);
    const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const todayStart = startOfDay(now);
    const tomorrow = new Date(todayStart.getTime() + 86400_000);
    const sameDayLastMonth = new Date(
      now.getFullYear(),
      now.getMonth() - 1,
      now.getDate(),
    );
    const quarterStart = startOfQuarter(now);
    const lastQuarterStart = new Date(quarterStart.getFullYear(), quarterStart.getMonth() - 3, 1);
    const from = periodStart(period, now);

    const dbStart = Date.now();
    await prisma.$queryRawUnsafe("SELECT 1");
    const dbLatencyMs = Date.now() - dbStart;

    const [
      patients,
      patientsBeforeMonth,
      doctors,
      doctorsBeforeMonth,
      activeConsultations,
      appointmentsToday,
      appointmentsSameDayLastMonth,
      revenueThisMonth,
      revenueLastMonth,
      signupsThisQuarter,
      signupsLastQuarter,
      series,
      recentAppointments,
      ratings,
      incompleteDoctors,
      tickets,
      openTickets,
    ] = await Promise.all([
      prisma.user.count({ where: { role: "patient" } }),
      prisma.user.count({ where: { role: "patient", createdAt: { lt: monthStart } } }),
      prisma.user.count({ where: { role: "doctor" } }),
      prisma.user.count({ where: { role: "doctor", createdAt: { lt: monthStart } } }),
      prisma.appointment.count({ where: { status: "in_progress" } }),
      prisma.appointment.count({ where: { date: { gte: todayStart, lt: tomorrow } } }),
      prisma.appointment.count({
        where: {
          date: {
            gte: sameDayLastMonth,
            lt: new Date(sameDayLastMonth.getTime() + 86400_000),
          },
        },
      }),
      prisma.payment.aggregate({
        where: { status: "paid", createdAt: { gte: monthStart } },
        _sum: { amount: true },
      }),
      prisma.payment.aggregate({
        where: { status: "paid", createdAt: { gte: lastMonthStart, lt: monthStart } },
        _sum: { amount: true },
      }),
      prisma.user.count({ where: { createdAt: { gte: quarterStart } } }),
      prisma.user.count({
        where: { createdAt: { gte: lastQuarterStart, lt: quarterStart } },
      }),
      revenueSeries(period, now),
      prisma.appointment.groupBy({
        by: ["doctorId"],
        where: { date: { gte: from }, doctorId: { not: null } },
        _count: { _all: true },
      }),
      prisma.review.groupBy({
        by: ["doctorId"],
        _avg: { rating: true },
        _count: { _all: true },
      }),
      prisma.user.findMany({
        where: {
          role: "doctor",
          OR: [
            { consultationFee: null },
            { qualifications: null },
            { hospitalName: null },
            { availabilityDays: null },
          ],
        },
        orderBy: { createdAt: "desc" },
        take: 5,
        select: {
          id: true,
          name: true,
          image: true,
          specialization: true,
          createdAt: true,
          consultationFee: true,
          qualifications: true,
          hospitalName: true,
          availabilityDays: true,
        },
      }),
      prisma.supportTicket.findMany({ orderBy: { createdAt: "desc" }, take: 3 }),
      prisma.supportTicket.count({ where: { status: { not: "resolved" } } }),
    ]);

    // Doctors referenced by appointments or reviews, looked up once.
    const doctorIds = [
      ...new Set([
        ...recentAppointments.map((a) => a.doctorId!),
        ...ratings.map((r) => r.doctorId),
      ]),
    ];
    const doctorRows = await prisma.user.findMany({
      where: { id: { in: doctorIds } },
      select: { id: true, name: true, image: true, specialization: true, banned: true },
    });
    const doctorById = new Map(doctorRows.map((d) => [d.id, d]));

    const specialtyCounts = new Map<string, number>();
    for (const a of recentAppointments) {
      const specialty = doctorById.get(a.doctorId!)?.specialization || "General";
      specialtyCounts.set(specialty, (specialtyCounts.get(specialty) ?? 0) + a._count._all);
    }

    const cpuLoadPercent = Math.min(
      100,
      Math.round(((os.loadavg()[0] ?? 0) / Math.max(1, os.cpus().length)) * 100),
    );

    res.json({
      kpis: {
        totalPatients: { value: patients, change: change(patients, patientsBeforeMonth) },
        totalDoctors: { value: doctors, change: change(doctors, doctorsBeforeMonth) },
        activeConsultations: { value: activeConsultations, change: null },
        appointmentsToday: {
          value: appointmentsToday,
          change: change(appointmentsToday, appointmentsSameDayLastMonth),
        },
        monthlyRevenue: {
          value: revenueThisMonth._sum.amount ?? 0,
          change: change(revenueThisMonth._sum.amount ?? 0, revenueLastMonth._sum.amount ?? 0),
        },
        platformGrowth: {
          value: change(signupsThisQuarter, signupsLastQuarter),
          signupsThisQuarter,
        },
      },
      revenue: { period, series },
      specialties: [...specialtyCounts.entries()]
        .map(([name, count]) => ({ name, count }))
        .sort((a, b) => b.count - a.count),
      doctorPerformance: ratings
        .filter((r) => doctorById.has(r.doctorId))
        .map((r) => {
          const d = doctorById.get(r.doctorId)!;
          return {
            id: d.id,
            name: d.name,
            image: d.image,
            specialization: d.specialization,
            rating: Math.round((r._avg.rating ?? 0) * 10) / 10,
            reviews: r._count._all,
            status: d.banned ? "suspended" : "active",
          };
        })
        .sort((a, b) => b.rating - a.rating || b.reviews - a.reviews)
        .slice(0, 5),
      incompleteProfiles: incompleteDoctors.map((d) => ({
        id: d.id,
        name: d.name,
        image: d.image,
        specialization: d.specialization,
        joinedAt: d.createdAt,
        completed: [d.consultationFee, d.qualifications, d.hospitalName, d.availabilityDays].filter(
          (v) => v !== null && v !== "",
        ).length,
        total: 4,
      })),
      supportTickets: { recent: tickets, open: openTickets },
      systemHealth: {
        serverLoadPercent: cpuLoadPercent,
        database: "healthy",
        databaseLatencyMs: dbLatencyMs,
        apiLatencyMs: Date.now() - started,
      },
    });
  } catch (error) {
    console.error("Error building admin overview:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Sends an in-app notification to everyone in the chosen audience.
export const sendAnnouncement = async (req: Request, res: Response) => {
  try {
    const { audience, title, message } = req.body;
    if (!title?.trim() || !message?.trim()) {
      return res.status(400).json({ message: "title and message are required" });
    }
    const where =
      audience === "patients"
        ? { role: "patient" }
        : audience === "doctors"
          ? { role: "doctor" }
          : {};
    const users = await prisma.user.findMany({ where, select: { id: true } });
    await prisma.notification.createMany({
      data: users.map((u) => ({
        user: u.id,
        title: title.trim(),
        message: message.trim(),
        type: "system" as const,
      })),
    });
    const io = req.app.get("io");
    if (io) io.emit("notification_created");
    res.status(201).json({ sent: users.length });
  } catch (error) {
    console.error("Error sending announcement:", error);
    res.status(500).json({ message: "Server error" });
  }
};
