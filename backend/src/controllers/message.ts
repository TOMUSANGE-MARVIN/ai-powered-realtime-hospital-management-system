import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

// Inbox: one row per counterpart the user has ever messaged, most recent
// conversation first — the WhatsApp-style chat list.
export const getConversations = async (req: Request, res: Response) => {
  try {
    const me = (req as any).user;

    const recentMessages = await prisma.message.findMany({
      where: { OR: [{ senderId: me.id }, { receiverId: me.id }] },
      orderBy: { createdAt: "desc" },
      take: 500,
    });

    const lastByCounterpart = new Map<string, (typeof recentMessages)[number]>();
    for (const message of recentMessages) {
      const counterpartId = message.senderId === me.id ? message.receiverId : message.senderId;
      if (!lastByCounterpart.has(counterpartId)) {
        lastByCounterpart.set(counterpartId, message);
      }
    }

    const counterpartIds = [...lastByCounterpart.keys()];
    if (counterpartIds.length === 0) {
      return res.json({ res: [] });
    }

    const [users, unreadGroups] = await Promise.all([
      prisma.user.findMany({
        where: { id: { in: counterpartIds } },
        select: { id: true, name: true, image: true, role: true },
      }),
      prisma.message.groupBy({
        by: ["senderId"],
        where: { receiverId: me.id, readAt: null, senderId: { in: counterpartIds } },
        _count: { senderId: true },
      }),
    ]);

    const usersById = new Map(users.map((u) => [u.id, u]));
    const unreadByCounterpart = new Map(unreadGroups.map((g) => [g.senderId, g._count.senderId]));

    const conversations = counterpartIds
      .map((id) => {
        const last = lastByCounterpart.get(id)!;
        const user = usersById.get(id);
        return {
          otherUserId: id,
          otherUserName: user?.name ?? "Unknown",
          otherUserImage: user?.image ?? null,
          otherUserRole: user?.role ?? null,
          lastMessageText: last.text,
          lastMessageAttachmentType: last.attachmentType,
          lastMessageAt: last.createdAt,
          lastMessageFromMe: last.senderId === me.id,
          unreadCount: unreadByCounterpart.get(id) ?? 0,
        };
      })
      .sort((a, b) => b.lastMessageAt.getTime() - a.lastMessageAt.getTime());

    res.json({ res: conversations });
  } catch (error) {
    console.error("Error fetching conversations:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Full 1:1 conversation between the authenticated user and otherUserId,
// oldest first. Either a patient or a doctor can be on either side.
export const getConversation = async (req: Request, res: Response) => {
  try {
    const me = (req as any).user;
    const otherUserId = req.params.otherUserId as string;

    const messages = await prisma.message.findMany({
      where: {
        OR: [
          { senderId: me.id, receiverId: otherUserId },
          { senderId: otherUserId, receiverId: me.id },
        ],
      },
      orderBy: { createdAt: "asc" },
      take: 200,
    });

    // Mark messages sent to me as read (and, as a safety net, delivered —
    // covers the case where the sender's socket check at send time missed
    // it) now that I've fetched the thread.
    const unread = messages.filter(
      (m) => m.senderId === otherUserId && m.receiverId === me.id && !m.readAt,
    );
    if (unread.length > 0) {
      const now = new Date();
      await prisma.message.updateMany({
        where: { id: { in: unread.map((m) => m.id) } },
        data: { deliveredAt: now, readAt: now },
      });
      const io = req.app.get("io");
      if (io) {
        io.to(`user_${otherUserId}`).emit(
          "messages_updated",
          unread.map((m) => ({ ...m, deliveredAt: now, readAt: now })),
        );
      }
    }

    res.json({ res: messages });
  } catch (error) {
    console.error("Error fetching conversation:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const sendMessage = async (req: Request, res: Response) => {
  try {
    const me = (req as any).user;
    const { receiverId, text, attachmentUrl, attachmentType, attachmentName, replyToId } =
      req.body;

    const trimmedText = (text ?? "").trim();
    if (!receiverId || (!trimmedText && !attachmentUrl)) {
      return res
        .status(400)
        .json({ message: "receiverId and either text or an attachment are required" });
    }

    const receiver = await prisma.user.findUnique({ where: { id: receiverId } });
    if (!receiver) {
      return res.status(404).json({ message: "Recipient not found" });
    }

    // Snapshot the replied-to message's content at reply time rather than a
    // live relation — it still shows correctly even if that message is
    // later deleted, and needs no join to render.
    let replySnapshot: {
      replyToId: string;
      replyToText: string;
      replyToSenderId: string;
      replyToAttachmentType: string | null;
    } | null = null;
    if (replyToId) {
      const original = await prisma.message.findFirst({
        where: {
          id: replyToId,
          OR: [
            { senderId: me.id, receiverId },
            { senderId: receiverId, receiverId: me.id },
          ],
        },
      });
      if (!original) {
        return res.status(404).json({ message: "Message being replied to was not found" });
      }
      replySnapshot = {
        replyToId: original.id,
        replyToText: original.deletedAt
          ? "This message was deleted"
          : original.text ||
            (original.attachmentType === "image"
              ? "📷 Photo"
              : original.attachmentType === "audio"
                ? "🎤 Voice message"
                : "📎 Document"),
        replyToSenderId: original.senderId,
        replyToAttachmentType: original.deletedAt ? null : original.attachmentType,
      };
    }

    let message = await prisma.message.create({
      data: {
        senderId: me.id,
        receiverId,
        text: trimmedText,
        attachmentUrl: attachmentUrl || undefined,
        attachmentType: attachmentType || undefined,
        attachmentName: attachmentName || undefined,
        ...replySnapshot,
      },
    });

    const io = req.app.get("io");
    // Receiver's app is already connected (socket joined `user_<id>` on
    // connect) — safe to mark delivered immediately rather than waiting for
    // them to open this specific chat. If they're offline, this stays null
    // until socket.ts's join_user_room reconnect handler catches up.
    if (io?.sockets.adapter.rooms.get(`user_${receiverId}`)?.size) {
      message = await prisma.message.update({
        where: { id: message.id },
        data: { deliveredAt: new Date() },
      });
    }

    // Push to both sides' user rooms so any open chat screen updates live —
    // the sender too, in case they have the conversation open on another
    // device/session.
    if (io) {
      io.to(`user_${receiverId}`).emit("new_message", message);
      io.to(`user_${me.id}`).emit("new_message", message);
    }

    res.status(201).json(message);
  } catch (error) {
    console.error("Error sending message:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Soft delete — only the sender can delete their own message. Content is
// wiped server-side (not just hidden client-side) and both sides get a
// live "message_deleted" push so an already-open chat updates instantly.
export const deleteMessage = async (req: Request, res: Response) => {
  try {
    const me = (req as any).user;
    const id = req.params.id as string;

    const message = await prisma.message.findUnique({ where: { id } });
    if (!message) {
      return res.status(404).json({ message: "Message not found" });
    }
    if (message.senderId !== me.id) {
      return res.status(403).json({ message: "You can only delete your own messages" });
    }

    const updated = await prisma.message.update({
      where: { id },
      data: {
        text: "",
        attachmentUrl: null,
        attachmentType: null,
        attachmentName: null,
        deletedAt: new Date(),
      },
    });

    const io = req.app.get("io");
    if (io) {
      io.to(`user_${message.receiverId}`).emit("message_deleted", updated);
      io.to(`user_${me.id}`).emit("message_deleted", updated);
    }

    res.json(updated);
  } catch (error) {
    console.error("Error deleting message:", error);
    res.status(500).json({ message: "Server error" });
  }
};
