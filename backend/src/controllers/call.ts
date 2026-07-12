import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

// Records that a call was attempted — there's no real WebRTC connection
// yet (voice/video buttons are a UI-only stub), but the log itself is real
// so the Calls tab has genuine history, same as any missed/placed call log.
export const recordCall = async (req: Request, res: Response) => {
  try {
    const me = (req as any).user;
    const { calleeId, type } = req.body;

    if (!calleeId || (type !== "voice" && type !== "video")) {
      return res.status(400).json({ message: "calleeId and a valid type are required" });
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
