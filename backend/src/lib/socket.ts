import { Server as SocketIOServer } from "socket.io";
import { Server as HttpServer } from "http";
import { prisma } from "./prisma";

let io: SocketIOServer;

export const initSocket = (server: HttpServer) => {
  io = new SocketIOServer(server, {
    cors: {
      // "askmusawo://mobile" mirrors the better-auth trustedOrigins fix in
      // lib/auth.ts — native Socket.IO clients don't have a real browser
      // origin either, so the Flutter app sends this static value.
      origin: [
        process.env.FRONTEND_URL || "http://localhost:5173",
        "askmusawo://mobile",
      ],
      credentials: true,
    },
  });

  io.on("connection", (socket) => {
    socket.on("join_role_room", (role) =>
      socket.join(role === "admin" ? "admin_room" : "medical_room"),
    );
    // Chat delivery room — one per user, joined right after connecting so
    // sendMessage's io.to(`user_${id}`) reaches any of that user's open
    // sessions/devices.
    socket.on("join_user_room", async (userId: string) => {
      if (!userId) return;
      socket.join(`user_${userId}`);

      // Any messages that arrived while this user was offline are now
      // deliverable — mark them and tell each sender so their tick updates
      // live instead of waiting for the receiver to open that chat.
      try {
        const pending = await prisma.message.findMany({
          where: { receiverId: userId, deliveredAt: null, deletedAt: null },
        });
        if (pending.length === 0) return;

        const now = new Date();
        await prisma.message.updateMany({
          where: { id: { in: pending.map((m) => m.id) } },
          data: { deliveredAt: now },
        });

        const bySender = new Map<string, typeof pending>();
        for (const message of pending) {
          const list = bySender.get(message.senderId) ?? [];
          list.push(message);
          bySender.set(message.senderId, list);
        }
        for (const [senderId, messages] of bySender) {
          io.to(`user_${senderId}`).emit(
            "messages_updated",
            messages.map((m) => ({ ...m, deliveredAt: now })),
          );
        }
      } catch (error) {
        console.error("Error marking pending messages delivered:", error);
      }
    });
    socket.on("notify_user_created", () => {
      console.log(`notify_user_created from ${socket.id}`);
      // broadcast to everyone except sender
      socket.emit("notify_user_created");
    });
  });
  return io;
};

export const getIO = () => {
  if (!io) {
    throw new Error("Socket.io not initialized");
  }
  return io;
};
