import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { logActivity } from "../lib/activity";
import { notifyUser } from "../lib/notify";

// Doctor licence verification (E23.1). A doctor — whether they signed up in
// the app or an admin created the account — submits their Uganda Medical and
// Dental Practitioners Council licence and practising facility. Until an admin
// approves it they are hidden from patients and can't consult (see
// lib/doctorVerification.ts and middleware/checkRole.ts).

const VERIFICATION_SELECT = {
  id: true,
  name: true,
  email: true,
  image: true,
  gender: true,
  phoneNumber: true,
  specialization: true,
  hospitalName: true,
  hospitalAddress: true,
  yearsOfExperience: true,
  qualifications: true,
  doctorVerificationStatus: true,
  licenseNumber: true,
  licenseDocumentUrl: true,
  verificationSubmittedAt: true,
  verificationReviewedAt: true,
  verificationNote: true,
  createdAt: true,
};

const text = (value: unknown) =>
  typeof value === "string" && value.trim() ? value.trim() : null;

async function notifyAdmins(title: string, message: string) {
  const admins = await prisma.user.findMany({
    where: { role: "admin" },
    select: { id: true },
  });
  await Promise.all(
    admins.map((a) => notifyUser(a.id, { title, message, link: "/doctors?tab=verification" })),
  );
}

// POST /api/doctors/apply — a freshly registered account (which better-auth
// always creates as a patient) becomes a doctor awaiting verification.
// Refused for accounts that already have patient history, so a patient can't
// silently turn their records into a doctor account.
export const applyAsDoctor = async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    if (user.role === "doctor") {
      return res.status(400).json({ message: "This account is already a doctor account." });
    }
    if (user.role !== "patient") {
      return res.status(403).json({ message: "Only new accounts can apply as a doctor." });
    }
    const history = await prisma.appointment.count({ where: { patientId: user.id } });
    if (history > 0) {
      return res.status(400).json({
        message:
          "This account already has appointments as a patient. Register a separate account for your doctor practice.",
      });
    }

    const specialization = text(req.body.specialization);
    if (!specialization) {
      return res.status(400).json({ message: "Choose your specialty." });
    }

    const updated = await prisma.user.update({
      where: { id: user.id },
      data: {
        role: "doctor",
        specialization,
        doctorVerificationStatus: "pending",
      },
      select: VERIFICATION_SELECT,
    });
    await logActivity(user.id, "Doctor Application", `${user.name} applied as a ${specialization} doctor`);
    res.json(updated);
  } catch (error) {
    console.error("Error applying as doctor:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// GET /api/doctors/me/verification
export const getMyVerification = async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const me = await prisma.user.findUnique({
      where: { id: user.id },
      select: VERIFICATION_SELECT,
    });
    res.json(me);
  } catch (error) {
    console.error("Error fetching verification:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// PUT /api/doctors/me/verification — submit or resubmit licence details.
export const submitMyVerification = async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    if (user.role !== "doctor") {
      return res.status(403).json({ message: "Only doctor accounts are verified." });
    }
    const current = await prisma.user.findUnique({
      where: { id: user.id },
      select: { doctorVerificationStatus: true },
    });
    if (current?.doctorVerificationStatus === "approved") {
      return res.status(400).json({
        message: "Your licence is already approved. Contact support to change it.",
      });
    }

    const licenseNumber = text(req.body.licenseNumber);
    const licenseDocumentUrl = text(req.body.licenseDocumentUrl);
    const hospitalName = text(req.body.hospitalName);
    const hospitalAddress = text(req.body.hospitalAddress);
    const specialization = text(req.body.specialization);
    const years = Number.parseInt(req.body.yearsOfExperience, 10);

    const missing = [
      !licenseNumber && "licence number",
      !licenseDocumentUrl && "a photo or PDF of your practising licence",
      !hospitalName && "the licensed facility you practise at",
    ].filter(Boolean);
    if (missing.length) {
      return res.status(400).json({ message: `Add ${missing.join(", ")}.` });
    }

    const updated = await prisma.user.update({
      where: { id: user.id },
      data: {
        licenseNumber,
        licenseDocumentUrl,
        hospitalName,
        hospitalAddress,
        ...(specialization ? { specialization } : {}),
        ...(Number.isFinite(years) && years >= 0 ? { yearsOfExperience: years } : {}),
        doctorVerificationStatus: "pending",
        verificationSubmittedAt: new Date(),
        verificationReviewedAt: null,
        verificationReviewedBy: null,
        verificationNote: null,
      },
      select: VERIFICATION_SELECT,
    });

    await logActivity(user.id, "Licence Submitted", `${user.name} submitted licence ${licenseNumber}`);
    await notifyAdmins(
      "Doctor awaiting verification",
      `${user.name} submitted licence ${licenseNumber} for review.`,
    );
    res.json(updated);
  } catch (error) {
    console.error("Error submitting verification:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// GET /api/admin/doctor-verifications?status=pending|approved|rejected|none|all
// ("none" = doctor accounts that haven't submitted a licence yet).
export const listVerifications = async (req: Request, res: Response) => {
  try {
    const status = (req.query.status as string) || "pending";
    const statusWhere =
      status === "all" ? {} : { doctorVerificationStatus: status === "none" ? null : status };
    const doctors = await prisma.user.findMany({
      where: { role: "doctor", ...statusWhere },
      select: VERIFICATION_SELECT,
      orderBy: [{ verificationSubmittedAt: "desc" }, { createdAt: "desc" }],
    });
    res.json(doctors);
  } catch (error) {
    console.error("Error listing verifications:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// POST /api/admin/doctor-verifications/:id  { decision: "approve" | "reject", reason? }
export const reviewVerification = async (req: Request, res: Response) => {
  try {
    const admin = (req as any).user;
    const id = req.params.id as string;
    const decision = req.body.decision;
    const reason = text(req.body.reason);

    if (decision !== "approve" && decision !== "reject") {
      return res.status(400).json({ message: "Decision must be approve or reject." });
    }
    if (decision === "reject" && !reason) {
      return res.status(400).json({ message: "Give the doctor a reason so they can fix it." });
    }

    const doctor = await prisma.user.findFirst({
      where: { id, role: "doctor" },
      select: { id: true, name: true, licenseDocumentUrl: true },
    });
    if (!doctor) return res.status(404).json({ message: "Doctor not found" });
    if (decision === "approve" && !doctor.licenseDocumentUrl) {
      return res.status(400).json({ message: "This doctor hasn't uploaded a licence yet." });
    }

    const approved = decision === "approve";
    const updated = await prisma.user.update({
      where: { id },
      data: {
        doctorVerificationStatus: approved ? "approved" : "rejected",
        verificationReviewedAt: new Date(),
        verificationReviewedBy: admin.id,
        verificationNote: approved ? null : reason,
      },
      select: VERIFICATION_SELECT,
    });

    await logActivity(
      admin.id,
      approved ? "Doctor Approved" : "Doctor Rejected",
      `${admin.name} ${approved ? "approved" : "rejected"} ${doctor.name}${reason ? `: ${reason}` : ""}`,
    );
    await notifyUser(id, {
      title: approved ? "You're verified" : "Licence not approved",
      message: approved
        ? "Your licence has been approved. Patients can now find and book you."
        : `Your licence wasn't approved: ${reason}. Update your details and submit again.`,
      link: approved ? "/doctor-home" : "/doctor-verification",
    });
    res.json(updated);
  } catch (error) {
    console.error("Error reviewing verification:", error);
    res.status(500).json({ message: "Server error" });
  }
};
