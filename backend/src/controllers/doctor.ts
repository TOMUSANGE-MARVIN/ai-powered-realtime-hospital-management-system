import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

const DOCTOR_SELECT = {
  id: true,
  name: true,
  email: true,
  image: true,
  specialization: true,
  department: true,
  bio: true,
  hospitalName: true,
  hospitalAddress: true,
  consultationFee: true,
  status: true,
  createdAt: true,
  updatedAt: true,
};

// Attach {rating, reviewCount} to a set of doctors with one groupBy query.
async function withRatings<T extends { id: string }>(doctors: T[]) {
  if (doctors.length === 0) return [];
  const groups = await prisma.review.groupBy({
    by: ["doctorId"],
    where: { doctorId: { in: doctors.map((d) => d.id) } },
    _avg: { rating: true },
    _count: { rating: true },
  });
  const byDoctor = new Map(groups.map((g) => [g.doctorId, g]));
  return doctors.map((d) => {
    const g = byDoctor.get(d.id);
    return {
      ...d,
      rating: g?._avg.rating ?? null,
      reviewCount: g?._count.rating ?? 0,
    };
  });
}

// Patient-accessible list of doctors — used by the mobile app's search screen
// and, with ?featured=true, the home dashboard's top-rated carousel.
export const listDoctors = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;
    const search = (req.query.search as string) || "";
    const specialization = req.query.specialization as string;
    const featured = req.query.featured === "true";

    const where: any = { role: "doctor" };
    if (specialization && specialization !== "all") {
      where.specialization = specialization;
    }
    if (search) {
      where.name = { contains: search };
    }

    if (featured) {
      // Rating order lives in the review table, so pick the top-rated doctor
      // IDs first, then fetch those doctors. Unrated doctors fill any
      // remaining slots so a fresh install still shows a carousel.
      const topRated = await prisma.review.groupBy({
        by: ["doctorId"],
        _avg: { rating: true },
        orderBy: { _avg: { rating: "desc" } },
        take: limit,
      });
      const ratedIds = topRated.map((g) => g.doctorId);

      const ratedDoctors = await prisma.user.findMany({
        where: { ...where, id: { in: ratedIds } },
        select: DOCTOR_SELECT,
      });
      const ratedOrdered = ratedIds
        .map((id) => ratedDoctors.find((d) => d.id === id))
        .filter((d): d is NonNullable<typeof d> => d != null);

      const filler =
        ratedOrdered.length < limit
          ? await prisma.user.findMany({
              where: { ...where, id: { notIn: ratedIds } },
              select: DOCTOR_SELECT,
              orderBy: { name: "asc" },
              take: limit - ratedOrdered.length,
            })
          : [];

      const doctors = await withRatings([...ratedOrdered, ...filler]);
      return res.json({
        res: doctors,
        pagination: {
          currentPage: 1,
          totalPages: 1,
          totalData: doctors.length,
          limit,
        },
      });
    }

    const [total, doctors] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        select: DOCTOR_SELECT,
        orderBy: { name: "asc" },
        skip,
        take: limit,
      }),
    ]);

    res.json({
      res: await withRatings(doctors),
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalData: total,
        limit,
      },
    });
  } catch (error) {
    console.error("Error listing doctors:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Distinct specialties with doctor counts, for filter chips
export const getDoctorSpecialties = async (req: Request, res: Response) => {
  try {
    const groups = await prisma.user.groupBy({
      by: ["specialization"],
      where: { role: "doctor", specialization: { not: null } },
      _count: { specialization: true },
      orderBy: { specialization: "asc" },
    });

    const specialties = groups
      .filter((g) => g.specialization)
      .map((g) => ({ specialization: g.specialization, count: g._count.specialization }));

    res.json(specialties);
  } catch (error) {
    console.error("Error fetching specialties:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getDoctorById = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const doctor = await prisma.user.findFirst({
      where: { id, role: "doctor" },
      select: DOCTOR_SELECT,
    });

    if (!doctor) {
      return res.status(404).json({ message: "Doctor not found" });
    }

    const [withRating] = await withRatings([doctor]);
    res.json(withRating);
  } catch (error) {
    console.error("Error fetching doctor:", error);
    res.status(500).json({ message: "Server error" });
  }
};
