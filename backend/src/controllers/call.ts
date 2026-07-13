import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

const VALID_STATUSES = ["answered", "missed", "declined", "busy", "cancelled"];

// Records the outcome of a call (voice calls now connect via WebRTC,
// signaled over Socket.IO — see lib/socket.ts's call:* events; the mobile
// app calls this once per call, from the caller's device, once the
// terminal outcome/duration is known) so the Calls tab has real history.
export const recordCall = async (req: Request, res: Response) => {
  try {
    const me = (req as any).user;
    const { calleeId, type, status, durationSeconds } = req.body;

    if (!calleeId || (type !== "voice" && type !== "video")) {
      return res.status(400).json({ message: "calleeId and a valid type are required" });
    }
    if (status !== undefined && !VALID_STATUSES.includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const callee = await prisma.user.findUnique({ where: { id: calleeId } });
    if (!callee) {
      return res.status(404).json({ message: "Recipient not found" });
    }

    const call = await prisma.callLog.create({
      data: {
        callerId: me.id,
        callerName: me.name,
        calleeId,
        calleeName: callee.name,
        type,
        status: status || "answered",
        durationSeconds:
          typeof durationSeconds === "number" ? durationSeconds : null,
      },
    });

    res.status(201).json(call);
  } catch (error) {
    console.error("Error recording call:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// The authenticated user's call history, either side, most recent first.
export const getMyCalls = async (req: Request, res: Response) => {
  try {
    const me = (req as any).user;

    const calls = await prisma.callLog.findMany({
      where: { OR: [{ callerId: me.id }, { calleeId: me.id }] },
      orderBy: { createdAt: "desc" },
      take: 100,
    });

    const results = calls.map((call) => ({
      id: call.id,
      type: call.type,
      status: call.status,
      durationSeconds: call.durationSeconds,
      createdAt: call.createdAt,
      isOutgoing: call.callerId === me.id,
      otherUserId: call.callerId === me.id ? call.calleeId : call.callerId,
      otherUserName: call.callerId === me.id ? call.calleeName : call.callerName,
    }));

    res.json({ res: results });
  } catch (error) {
    console.error("Error fetching call history:", error);
    res.status(500).json({ message: "Server error" });
  }
};
