import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

// Admin pages: Reviews & Ratings moderation, announcement history, and
// Reports & Analytics.

const PERIOD_DAYS: Record<string, number> = { week: 7, month: 30, quarter: 91, year: 365 };

// --- Reviews & Ratings -------------------------------------------------------

export const listReviews = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit as string) || 20));
    const rating = parseInt(req.query.rating as string);
    const replied = req.query.replied as string | undefined;
    const visibility = req.query.visibility as string | undefined;
    const search = ((req.query.search as string) || "").trim();
    const days = PERIOD_DAYS[req.query.period as string];

    const base: any = {};
    if (days) base.createdAt = { gte: new Date(Date.now() - days * 86400_000) };

    const where: any = { ...base };
    if (rating >= 1 && rating <= 5) where.rating = rating;
    if (replied === "yes") where.doctorReply = { not: null };
    if (replied === "no") where.doctorReply = null;
    if (visibility === "hidden") where.hidden = true;
    if (visibility === "visible") where.hidden = false;
    if (search) {
      const doctors = await prisma.user.findMany({
        where: { role: "doctor", name: { contains: search } },
        select: { id: true },
      });
      where.OR = [
        { patientName: { contains: search } },
        { comment: { contains: search } },
        { doctorId: { in: doctors.map((d) => d.id) } },
      ];
    }

    const [total, reviews, distribution, visibleAgg, repliedCount, hiddenCount] =
      await Promise.all([
        prisma.review.count({ where }),
        prisma.review.findMany({
          where,
          orderBy: { createdAt: "desc" },
          skip: (page - 1) * limit,
          take: limit,
        }),
        prisma.review.groupBy({
          by: ["rating"],
          where: { ...base, hidden: false },
          _count: { _all: true },
        }),
        prisma.review.aggregate({
          where: { ...base, hidden: false },
          _avg: { rating: true },
          _count: { _all: true },
        }),
        prisma.review.count({ where: { ...base, doctorReply: { not: null } } }),
        prisma.review.count({ where: { ...base, hidden: true } }),
      ]);

    const doctorIds = [...new Set(reviews.map((r) => r.doctorId))];
    const doctors = await prisma.user.findMany({
      where: { id: { in: doctorIds } },
      select: { id: true, name: true, specialization: true, image: true },
    });
    const doctorById = new Map(doctors.map((d) => [d.id, d]));
    const counts = Object.fromEntries(distribution.map((d) => [d.rating, d._count._all]));
    const all = visibleAgg._count._all + hiddenCount;

    res.json({
      summary: {
        average: visibleAgg._avg.rating === null ? null : Math.round(visibleAgg._avg.rating * 10) / 10,
        total: visibleAgg._count._all,
        hidden: hiddenCount,
        lowRatings: (counts[1] ?? 0) + (counts[2] ?? 0),
        replyRate: all ? Math.round((repliedCount / all) * 100) : null,
        distribution: [5, 4, 3, 2, 1].map((stars) => ({ stars, count: counts[stars] ?? 0 })),
      },
      reviews: reviews.map((r) => ({
        ...r,
        doctor: doctorById.get(r.doctorId) ?? null,
      })),
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error("Error listing reviews:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const moderateReview = async (req: Request, res: Response) => {
  try {
    const { hidden, reason } = req.body;
    if (typeof hidden !== "boolean") {
      return res.status(400).json({ message: "hidden must be true or false" });
    }
    if (hidden && !reason?.trim()) {
      return res.status(400).json({ message: "Give a reason for hiding this review" });
    }
    const review = await prisma.review.update({
      where: { id: req.params.id as string },
      data: hidden
        ? { hidden: true, hiddenReason: reason.trim(), hiddenAt: new Date() }
        : { hidden: false, hiddenReason: null, hiddenAt: null },
    });
    res.json(review);
  } catch (error: any) {
    if (error?.code === "P2025") {
      return res.status(404).json({ message: "Review not found" });
    }
    console.error("Error moderating review:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// --- Announcements -------------------------------------------------------------

const AUDIENCES = ["all", "patients", "doctors"];

const audienceWhere = (audience: string) =>
  audience === "patients"
    ? { role: "patient" }
    : audience === "doctors"
      ? { role: "doctor" }
      : {};

export const countRecipients = async (req: Request, res: Response) => {
  try {
    const audience = AUDIENCES.includes(req.query.audience as string)
      ? (req.query.audience as string)
      : "all";
    res.json({ count: await prisma.user.count({ where: audienceWhere(audience) }) });
  } catch (error) {
    console.error("Error counting recipients:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Records the announcement, then gives every recipient a notification.
export const sendAnnouncement = async (req: Request, res: Response) => {
  try {
    const admin = (req as any).user;
    const { audience = "all", title, message, link } = req.body;
    if (!AUDIENCES.includes(audience)) {
      return res.status(400).json({ message: "Unknown audience" });
    }
    if (!title?.trim() || !message?.trim()) {
      return res.status(400).json({ message: "title and message are required" });
    }
    const cleanLink = typeof link === "string" && link.trim() ? link.trim() : null;
    if (cleanLink && !/^(https?:\/\/|\/)/.test(cleanLink)) {
      return res.status(400).json({ message: "Link must start with http(s):// or /" });
    }

    const users = await prisma.user.findMany({
      where: audienceWhere(audience),
      select: { id: true },
    });
    const announcement = await prisma.$transaction(async (tx) => {
      const created = await tx.announcement.create({
        data: {
          title: title.trim(),
          message: message.trim(),
          audience,
          link: cleanLink,
          sentCount: users.length,
          sentById: admin.id,
          sentByName: admin.name,
        },
      });
      await tx.notification.createMany({
        data: users.map((u) => ({
          user: u.id,
          title: created.title,
          message: created.message,
          link: cleanLink,
          type: "system" as const,
          announcementId: created.id,
        })),
      });
      return created;
    });

    const io = req.app.get("io");
    if (io) io.emit("notification_created");
    res.status(201).json({ ...announcement, sent: users.length });
  } catch (error) {
    console.error("Error sending announcement:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const listAnnouncements = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = 20;
    const [total, announcements] = await Promise.all([
      prisma.announcement.count(),
      prisma.announcement.findMany({
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
    ]);
    const reads = await prisma.notification.groupBy({
      by: ["announcementId"],
      where: { announcementId: { in: announcements.map((a) => a.id) }, isRead: true },
      _count: { _all: true },
    });
    const readBy = new Map(reads.map((r) => [r.announcementId, r._count._all]));
    res.json({
      announcements: announcements.map((a) => ({ ...a, readCount: readBy.get(a.id) ?? 0 })),
      pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
    });
  } catch (error) {
    console.error("Error listing announcements:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// --- Reports & Analytics ---------------------------------------------------------

type Granularity = "day" | "week" | "month";

/** Bucket start for a date: the day, the Monday of its week, or the 1st. */
function bucketStart(d: Date, g: Granularity) {
  const day = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  if (g === "day") return day;
  if (g === "week") {
    const offset = (day.getUTCDay() + 6) % 7;
    return new Date(day.getTime() - offset * 86400_000);
  }
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1));
}

function nextBucket(d: Date, g: Granularity) {
  if (g === "day") return new Date(d.getTime() + 86400_000);
  if (g === "week") return new Date(d.getTime() + 7 * 86400_000);
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 1));
}

const key = (d: Date) => d.toISOString().slice(0, 10);

export const getReports = async (req: Request, res: Response) => {
  try {
    const to = req.query.to ? new Date(`${req.query.to}T23:59:59.999Z`) : new Date();
    const from = req.query.from
      ? new Date(`${req.query.from}T00:00:00.000Z`)
      : new Date(to.getTime() - 29 * 86400_000);
    if (isNaN(from.getTime()) || isNaN(to.getTime()) || from > to) {
      return res.status(400).json({ message: "Invalid date range" });
    }
    const spanDays = (to.getTime() - from.getTime()) / 86400_000;
    const requested = req.query.granularity as Granularity;
    const granularity: Granularity = ["day", "week", "month"].includes(requested)
      ? requested
      : spanDays > 120
        ? "month"
        : spanDays > 31
          ? "week"
          : "day";
    if (granularity === "day" && spanDays > 400) {
      return res.status(400).json({ message: "Use weekly or monthly for ranges over a year" });
    }

    const [appointments, payments, users, reviews, withdrawals] = await Promise.all([
      prisma.appointment.findMany({
        where: { date: { gte: from, lte: to }, doctorId: { not: null } },
        select: { id: true, date: true, status: true, doctorId: true, paymentId: true },
      }),
      prisma.payment.findMany({
        where: { createdAt: { gte: from, lte: to }, status: "paid" },
        select: { id: true, amount: true, discount: true, tax: true, voucherCode: true, doctorId: true, createdAt: true },
      }),
      prisma.user.findMany({
        where: { createdAt: { gte: from, lte: to }, role: { in: ["patient", "doctor"] } },
        select: { role: true, createdAt: true },
      }),
      prisma.review.findMany({
        where: { hidden: false, createdAt: { gte: from, lte: to } },
        select: { doctorId: true, rating: true },
      }),
      prisma.withdrawal.findMany({
        where: { createdAt: { gte: from, lte: to } },
        select: { amount: true, status: true },
      }),
    ]);

    // Empty buckets for the whole range so charts have no gaps.
    const buckets: string[] = [];
    for (let b = bucketStart(from, granularity); b <= to; b = nextBucket(b, granularity)) {
      buckets.push(key(b));
    }
    const series = <T extends Record<string, number>>(zero: () => T) =>
      new Map(buckets.map((k) => [k, zero()]));

    const consultations = series(() => ({ completed: 0, cancelled: 0, other: 0 }));
    for (const a of appointments) {
      const row = consultations.get(key(bucketStart(a.date, granularity)));
      if (!row) continue;
      if (a.status === "completed") row.completed++;
      else if (a.status === "cancelled") row.cancelled++;
      else row.other++;
    }

    const revenue = series(() => ({ revenue: 0, discounts: 0, tax: 0 }));
    for (const p of payments) {
      const row = revenue.get(key(bucketStart(p.createdAt, granularity)));
      if (!row) continue;
      row.revenue += p.amount;
      row.discounts += p.discount;
      row.tax += p.tax;
    }

    const signups = series(() => ({ patients: 0, doctors: 0 }));
    for (const u of users) {
      const row = signups.get(key(bucketStart(u.createdAt, granularity)));
      if (!row) continue;
      if (u.role === "doctor") row.doctors++;
      else row.patients++;
    }

    const doctorIds = [
      ...new Set([
        ...appointments.map((a) => a.doctorId!),
        ...payments.map((p) => p.doctorId),
        ...reviews.map((r) => r.doctorId),
      ]),
    ];
    const doctors = await prisma.user.findMany({
      where: { id: { in: doctorIds } },
      select: { id: true, name: true, specialization: true },
    });
    const board = new Map(
      doctors.map((d) => [
        d.id,
        {
          id: d.id,
          name: d.name,
          specialization: d.specialization || "General",
          consultations: 0,
          completed: 0,
          revenue: 0,
          ratingSum: 0,
          ratings: 0,
        },
      ]),
    );
    for (const a of appointments) {
      const row = board.get(a.doctorId!);
      if (!row) continue;
      row.consultations++;
      if (a.status === "completed") row.completed++;
    }
    for (const p of payments) {
      const row = board.get(p.doctorId);
      if (row) row.revenue += p.amount;
    }
    for (const r of reviews) {
      const row = board.get(r.doctorId);
      if (!row) continue;
      row.ratingSum += r.rating;
      row.ratings++;
    }
    const leaderboard = [...board.values()]
      .map(({ ratingSum, ratings, ...rest }) => ({
        ...rest,
        rating: ratings ? Math.round((ratingSum / ratings) * 10) / 10 : null,
        ratings,
      }))
      .sort((a, b) => b.revenue - a.revenue || b.consultations - a.consultations);

    const specialties = new Map<string, { name: string; consultations: number; revenue: number }>();
    for (const row of leaderboard) {
      const s = specialties.get(row.specialization) ?? {
        name: row.specialization,
        consultations: 0,
        revenue: 0,
      };
      s.consultations += row.consultations;
      s.revenue += row.revenue;
      specialties.set(row.specialization, s);
    }

    const vouchers = new Map<string, { code: string; uses: number; discount: number }>();
    for (const p of payments) {
      if (!p.voucherCode) continue;
      const v = vouchers.get(p.voucherCode) ?? { code: p.voucherCode, uses: 0, discount: 0 };
      v.uses++;
      v.discount += p.discount;
      vouchers.set(p.voucherCode, v);
    }

    const sum = (xs: number[]) => xs.reduce((a, b) => a + b, 0);
    const completed = appointments.filter((a) => a.status === "completed").length;
    const cancelled = appointments.filter((a) => a.status === "cancelled").length;

    res.json({
      range: { from: key(from), to: key(to), granularity },
      totals: {
        consultations: appointments.length,
        completed,
        cancelled,
        cancellationRate: completed + cancelled
          ? Math.round((cancelled / (completed + cancelled)) * 100)
          : null,
        revenue: sum(payments.map((p) => p.amount)),
        discounts: sum(payments.map((p) => p.discount)),
        tax: sum(payments.map((p) => p.tax)),
        newPatients: users.filter((u) => u.role === "patient").length,
        newDoctors: users.filter((u) => u.role === "doctor").length,
        averageRating: reviews.length
          ? Math.round((sum(reviews.map((r) => r.rating)) / reviews.length) * 10) / 10
          : null,
      },
      consultations: [...consultations].map(([period, v]) => ({ period, ...v })),
      revenue: [...revenue].map(([period, v]) => ({ period, ...v })),
      signups: [...signups].map(([period, v]) => ({ period, ...v })),
      specialties: [...specialties.values()].sort((a, b) => b.consultations - a.consultations),
      doctors: leaderboard,
      vouchers: [...vouchers.values()].sort((a, b) => b.uses - a.uses),
      payouts: {
        requested: sum(withdrawals.filter((w) => w.status === "requested").map((w) => w.amount)),
        approved: sum(withdrawals.filter((w) => w.status === "approved").map((w) => w.amount)),
        paid: sum(withdrawals.filter((w) => w.status === "paid").map((w) => w.amount)),
        rejected: sum(withdrawals.filter((w) => w.status === "rejected").map((w) => w.amount)),
      },
    });
  } catch (error) {
    console.error("Error building reports:", error);
    res.status(500).json({ message: "Server error" });
  }
};
