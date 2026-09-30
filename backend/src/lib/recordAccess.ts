import { prisma } from "./prisma";

// Record-access audit log (E23.3). Called by every endpoint that returns a
// patient's records to someone other than that patient. Required by the
// Ministry of Health data guidelines ("who accessed what") and promised in
// the Privacy Policy.

export type RecordResource = "full_history" | "lab_results" | "prescriptions" | "profile";

/**
 * Repeat views of the same records by the same person within this window
 * count once — a screen refreshing, or a list reloaded, isn't a new access.
 */
const DEDUPE_WINDOW_MS = 30 * 60 * 1000;

interface Viewer {
  id: string;
  name?: string | null;
  role?: string | null;
}

/** Never throws: failing to log must not block care. */
export async function logRecordAccess(
  viewer: Viewer,
  patientIds: string | (string | null | undefined)[],
  resource: RecordResource,
) {
  try {
    const ids = [
      ...new Set((Array.isArray(patientIds) ? patientIds : [patientIds]).filter(Boolean) as string[]),
    ].filter((id) => id !== viewer.id);
    if (!ids.length) return;

    const recent = await prisma.recordAccess.findMany({
      where: {
        viewerId: viewer.id,
        resource,
        patientId: { in: ids },
        createdAt: { gte: new Date(Date.now() - DEDUPE_WINDOW_MS) },
      },
      select: { patientId: true },
    });
    const seen = new Set(recent.map((r) => r.patientId));
    const fresh = ids.filter((id) => !seen.has(id));
    if (!fresh.length) return;

    await prisma.recordAccess.createMany({
      data: fresh.map((patientId) => ({
        patientId,
        viewerId: viewer.id,
        viewerName: viewer.name || "Unknown",
        viewerRole: viewer.role || "unknown",
        resource,
      })),
    });
  } catch (error) {
    console.error("Error logging record access:", error);
  }
}
