import { Server as SocketIOServer } from "socket.io";
import { Server as HttpServer } from "http";
import { prisma } from "./prisma";

let io: SocketIOServer;

// In-memory call-signaling state — not persisted, doesn't survive a
// server restart or scale across multiple instances (this app runs a
// single Socket.IO instance with no Redis adapter, so that's consistent
// with the rest of the architecture). Purely for busy-detection and
// notifying the other party on an unexpected disconnect mid-call/mid-ring.
const activeCalls = new Map<string, { callerId: string; calleeId: string }>();
const userBusy = new Map<string, string>(); // userId -> callId

const clearCall = (callId: string) => {
  const call = activeCalls.get(callId);
  if (!call) return;
  if (userBusy.get(call.callerId) === callId) userBusy.delete(call.callerId);
  if (userBusy.get(call.calleeId) === callId) userBusy.delete(call.calleeId);
  activeCalls.delete(callId);
};

// Presence — userId -> count of currently-connected sockets for that user
// (a user can have more than one open session/device/tab; only a 0<->positive
// transition is a real online/offline change worth broadcasting). Same
// in-memory, single-instance caveat as the call-signaling state above.
const onlineUsers = new Map<string, number>();

export const isUserOnline = (userId: string) => (onlineUsers.get(userId) ?? 0) > 0;

const markOnline = (userId: string) => {
  const count = onlineUsers.get(userId) ?? 0;
  onlineUsers.set(userId, count + 1);
  if (count === 0) io.emit("presence_changed", { userId, online: true });
};

const markOffline = (userId: string) => {
  const count = onlineUsers.get(userId) ?? 0;
  if (count <= 1) {
    onlineUsers.delete(userId);
    io.emit("presence_changed", { userId, online: false });
  } else {
    onlineUsers.set(userId, count - 1);
  }
};

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
      socket.data.userId = userId;
      socket.join(`user_${userId}`);

      if (!socket.data.presenceCounted) {
        socket.data.presenceCounted = true;
        markOnline(userId);
      }

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

    // --- Voice call signaling ---
    // Server only relays SDP/ICE payloads between the same `user_${id}`
    // rooms chat already uses, plus a minimal busy-check. It never
    // inspects offer/answer/candidate contents.
    socket.on(
      "call:invite",
      (data: {
        callId: string;
        calleeId: string;
        callerId: string;
        callerName: string;
        callerImage?: string;
        sdp: unknown;
      }) => {
        const { callId, calleeId, callerId } = data;
        if (!callId || !calleeId || !callerId) return;

        if (userBusy.has(calleeId)) {
          io.to(`user_${callerId}`).emit("call:busy", { callId });
          return;
        }

        userBusy.set(callerId, callId);
        userBusy.set(calleeId, callId);
        activeCalls.set(callId, { callerId, calleeId });

        io.to(`user_${calleeId}`).emit("call:incoming", data);
        io.to(`user_${callerId}`).emit("call:status", {
          callId,
          calleeOnline: isUserOnline(calleeId),
        });
      },
    );

    socket.on("call:answer", (data: { callId: string; sdp: unknown }) => {
      const call = activeCalls.get(data.callId);
      if (!call) return;
      io.to(`user_${call.callerId}`).emit("call:answered", data);
    });

    socket.on("call:decline", (data: { callId: string }) => {
      const call = activeCalls.get(data.callId);
      if (!call) return;
      io.to(`user_${call.callerId}`).emit("call:declined", data);
      clearCall(data.callId);
    });

    socket.on("call:cancel", (data: { callId: string }) => {
      const call = activeCalls.get(data.callId);
      if (!call) return;
      io.to(`user_${call.calleeId}`).emit("call:cancelled", data);
      clearCall(data.callId);
    });

    socket.on("call:hangup", (data: { callId: string }) => {
      const call = activeCalls.get(data.callId);
      if (!call) return;
      const otherRoom =
        socket.data.userId === call.callerId
          ? `user_${call.calleeId}`
          : `user_${call.callerId}`;
      io.to(otherRoom).emit("call:ended", { ...data, reason: "hangup" });
      clearCall(data.callId);
    });

    socket.on(
      "call:ice-candidate",
      (data: { callId: string; targetUserId: string; candidate: unknown }) => {
        if (!data.targetUserId) return;
        io.to(`user_${data.targetUserId}`).emit("call:ice-candidate", data);
      },
    );

    socket.on("disconnect", () => {
      const userId = socket.data.userId as string | undefined;
      if (userId && socket.data.presenceCounted) markOffline(userId);

      if (!userId) return;
      const callId = userBusy.get(userId);
      if (!callId) return;
      const call = activeCalls.get(callId);
      if (!call) return;
      const otherUserId =
        userId === call.callerId ? call.calleeId : call.callerId;
      io.to(`user_${otherUserId}`).emit("call:ended", {
        callId,
        reason: "peer-disconnected",
      });
      clearCall(callId);
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
