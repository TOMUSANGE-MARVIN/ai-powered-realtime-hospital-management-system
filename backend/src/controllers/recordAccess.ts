import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

// GET /api/record-access/mine — who has opened my records (patients).
export const getMyRecordAccess = async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const entries = await prisma.recordAccess.findMany({
      where: { patientId: user.id },
      orderBy: { createdAt: "desc" },
      take: 200,
      select: {
        id: true,
        viewerName: true,
        viewerRole: true,
        resource: true,
        createdAt: true,
      },
    });
    res.json(entries);
  } catch (error) {
    console.error("Error fetching record access:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// GET /api/admin/record-access?patientId=&viewerId=&search=&page=&limit=
export const listRecordAccess = async (req: Request, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit as string) || 50));
    const where: any = {};
    if (req.query.patientId) where.patientId = req.query.patientId;
    if (req.query.viewerId) where.viewerId = req.query.viewerId;
    const search = ((req.query.search as string) || "").trim();
    if (search) {
      // Match the viewer's name, or any patient whose name matches.
      const patients = await prisma.user.findMany({
        where: { name: { contains: search } },
        select: { id: true },
        take: 200,
      });
      where.OR = [
        { viewerName: { contains: search } },
        { patientId: { in: patients.map((p) => p.id) } },
      ];
    }

    const [total, entries] = await Promise.all([
      prisma.recordAccess.count({ where }),
      prisma.recordAccess.findMany({
        where,
        orderBy: { createdAt: "desc" },
        skip: (page - 1) * limit,
        take: limit,
      }),
    ]);
    const patients = await prisma.user.findMany({
      where: { id: { in: [...new Set(entries.map((e) => e.patientId))] } },
      select: { id: true, name: true, email: true },
    });
    const byId = new Map(patients.map((p) => [p.id, p]));
    res.json({
      total,
      page,
      limit,
      res: entries.map((e) => ({
        ...e,
        patientName: byId.get(e.patientId)?.name ?? "Deleted patient",
        patientEmail: byId.get(e.patientId)?.email ?? null,
      })),
    });
  } catch (error) {
    console.error("Error listing record access:", error);
    res.status(500).json({ message: "Server error" });
  }
};
