import { prisma } from "./prisma";

export type DoctorVerificationStatus = "pending" | "approved" | "rejected";

/**
 * Prisma `where` for doctors patients may see, book, pay or message: only
 * those whose licence an admin has approved. Use this in every
 * patient-facing doctor query instead of a bare `role: "doctor"`.
 */
export const APPROVED_DOCTOR = {
  role: "doctor",
  doctorVerificationStatus: "approved",
} as const;

/** True when [userId] is a doctor an admin has approved. */
export async function isApprovedDoctor(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { role: true, doctorVerificationStatus: true },
  });
  return user?.role === "doctor" && user.doctorVerificationStatus === "approved";
}
