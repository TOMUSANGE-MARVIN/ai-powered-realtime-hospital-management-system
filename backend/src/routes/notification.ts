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

notificationRouter.post("/read-all", requireAuth, async (req, res) => {
  try {
    const { count } = await prisma.notification.updateMany({
      where: { user: (req as any).user.id, isRead: false },
      data: { isRead: true },
    });
    res.json({ updated: count });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

notificationRouter.post("/:id/read", requireAuth, async (req, res) => {
  try {
    const id = req.params.id as string;

    // Only the owner can mark their notification read.
    const { count } = await prisma.notification.updateMany({
      where: { id, user: (req as any).user.id },
      data: { isRead: true },
    });
    if (count === 0) return res.status(404).json({ message: "Notification not found" });
    res.json({ message: "Notification marked as read" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

export default notificationRouter;
