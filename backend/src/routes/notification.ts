import { Router } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";

const notificationRouter = Router();

notificationRouter.get("/", requireAuth, async (req, res) => {
  try {
    const currentUserId = (req as any).user.id;
    const [notifications, unreadCount] = await Promise.all([
      prisma.notification.findMany({
        where: { user: currentUserId },
        orderBy: { createdAt: "desc" },
        take: 20,
      }),
      prisma.notification.count({
        where: { user: currentUserId, isRead: false },
      }),
    ]);
    res.json({ notifications, unreadCount });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

notificationRouter.post("/:id/read", requireAuth, async (req, res) => {
  try {
    const id = req.params.id as string;

    await prisma.notification.update({ where: { id }, data: { isRead: true } });
    res.json({ message: "Notification marked as read" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

export default notificationRouter;
