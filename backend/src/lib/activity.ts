import { prisma } from "./prisma";

export const logActivity = async (
  userId: string,
  action: string,
  details: string,
) => {
  try {
    await prisma.activityLog.create({ data: { user: userId, action, details } });
  } catch (error) {
    console.error("Error logging activity:", error);
  }
};
