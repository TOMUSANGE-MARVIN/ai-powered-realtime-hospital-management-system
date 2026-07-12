import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

// Patient reviews a completed appointment. One review per appointment —
// submitting again replaces the previous rating/comment.
export const createReview = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const { appointmentId, rating, comment } = req.body;

    const parsedRating = parseInt(rating);
    if (!appointmentId || !parsedRating || parsedRating < 1 || parsedRating > 5) {
      return res
        .status(400)
        .json({ message: "appointmentId and a rating between 1 and 5 are required" });
    }

    const appointment = await prisma.appointment.findFirst({
      where: { id: appointmentId, patientId: patient.id },
    });
    if (!appointment) {
      return res.status(404).json({ message: "Appointment not found" });
    }
    if (appointment.status !== "completed") {
      return res
        .status(400)
        .json({ message: "You can only review completed appointments" });
    }
    if (!appointment.doctorId) {
      return res.status(400).json({ message: "Appointment has no doctor to review" });
    }

    const review = await prisma.review.upsert({
      where: { appointmentId },
      create: {
        appointmentId,
        patientId: patient.id,
        patientName: patient.name,
        doctorId: appointment.doctorId,
        rating: parsedRating,
        comment: comment || null,
      },
      update: { rating: parsedRating, comment: comment || null },
    });

    res.status(201).json(review);
  } catch (error) {
    console.error("Error creating review:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Doctor replies to a review left on one of their own appointments.
// Re-submitting replaces the previous reply.
export const replyToReview = async (req: Request, res: Response) => {
  try {
    const doctor = (req as any).user;
    const reviewId = req.params.id as string;
    const { reply } = req.body;

    if (!reply || !reply.trim()) {
      return res.status(400).json({ message: "reply text is required" });
    }

    const review = await prisma.review.findUnique({ where: { id: reviewId } });
    if (!review) {
      return res.status(404).json({ message: "Review not found" });
    }
    if (review.doctorId !== doctor.id) {
      return res.status(403).json({ message: "You can only reply to your own reviews" });
    }

    const updated = await prisma.review.update({
      where: { id: reviewId },
      data: { doctorReply: reply.trim(), doctorRepliedAt: new Date() },
    });

    res.json(updated);
  } catch (error) {
    console.error("Error replying to review:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// The authenticated doctor's own reviews — same shape as getDoctorReviews,
// used by the doctor-side screen where they reply.
export const getMyReviews = async (req: Request, res: Response) => {
  req.params.doctorId = (req as any).user.id;
  return getDoctorReviews(req, res);
};

// Reviews for a doctor's public profile, newest first, with the aggregate.
export const getDoctorReviews = async (req: Request, res: Response) => {
  try {
    const doctorId = req.params.doctorId as string;
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 20);
    const skip = (page - 1) * limit;

    const [total, reviews, aggregate] = await Promise.all([
      prisma.review.count({ where: { doctorId } }),
      prisma.review.findMany({
        where: { doctorId },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
      }),
      prisma.review.aggregate({
        where: { doctorId },
        _avg: { rating: true },
      }),
    ]);

    res.json({
      res: reviews,
      averageRating: aggregate._avg.rating,
      totalReviews: total,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalData: total,
        limit,
      },
    });
  } catch (error) {
    console.error("Error fetching doctor reviews:", error);
    res.status(500).json({ message: "Server error" });
  }
};
