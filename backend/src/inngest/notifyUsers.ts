import { getIO } from "../lib/socket";
import { prisma } from "../lib/prisma";

export const notifyUsers = async (
  doctorId: string,
  nurseId: string,
  title: string,
  message: string,
  link: string,
  type: "system" | "assignment" | "lab_result" | "alert",
) => {
  // 1. Create DB Notification for the Doctor
  await prisma.notification.create({
    data: { user: doctorId, title, message, type, link },
  });

  // 2. Create DB Notification for the Nurse
  await prisma.notification.create({
    data: { user: nurseId, title, message, type, link },
  });

  //later // 3. Emit a Socket event specifically to update their Bell Icon instantly!
  getIO().emit(`new_notification_${doctorId}`);
  getIO().emit(`new_notification_${nurseId}`);
};
