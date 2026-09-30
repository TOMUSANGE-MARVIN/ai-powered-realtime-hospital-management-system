import { prisma } from "./prisma";
import { getIO } from "./socket";

// In-app notifications for things that happen to a user's appointments,
// prescriptions, payments and payouts. Saved for the inbox and pushed live to
// any of the user's open sessions. (Phone push delivery plugs in here later.)

type NotificationType =
  | "system"
  | "appointment"
  | "prescription"
  | "payment"
  | "review"
  | "payout"
  | "lab_result";

export interface NotifyInput {
  title: string;
  message: string;
  type?: NotificationType;
  /** In-app route to open when tapped, e.g. "/home/appointments". */
  link?: string;
}

/** Never throws: a failed notification must not fail the action behind it. */
export async function notifyUser(userId: string | null | undefined, input: NotifyInput) {
  if (!userId) return;
  try {
    const notification = await prisma.notification.create({
      data: {
        user: userId,
        title: input.title,
        message: input.message,
        type: input.type ?? "system",
        link: input.link ?? null,
      },
    });
    try {
      getIO().to(`user_${userId}`).emit("notification:new", notification);
    } catch {
      // Socket server not running (scripts, tests) — the inbox still has it.
    }
  } catch (error) {
    console.error("Error creating notification:", error);
  }
}

/**
 * Appointment dates are stored as the booked wall-clock time (see
 * Appointment.date), so format them in UTC to show the time that was picked.
 */
export function formatVisit(date: Date, time?: string | null) {
  const day = date.toLocaleDateString("en-GB", {
    weekday: "short",
    day: "numeric",
    month: "short",
    timeZone: "UTC",
  });
  return time ? `${day} at ${time}` : day;
}
