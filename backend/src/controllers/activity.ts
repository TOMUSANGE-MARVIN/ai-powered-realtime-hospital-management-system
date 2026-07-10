import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { logActivity } from "../lib/activity";

// Controller to add an activity log
export const addActivityLog = async (req: Request, res: Response) => {
  try {
    const { userId, action, details } = req.body;
    await logActivity(userId, action, details);
    res.status(201).json({ message: "Activity logged successfully" });
  } catch (error) {
    console.error("Error adding activity log:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

// Controller to fetch activity logs for a user
export const getActivityLogs = async (req: Request, res: Response) => {
  try {
    // parse pagination parameters
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 10);
    const skip = (page - 1) * limit;

    // fetch activity logs
    const [totalLogs, logs] = await Promise.all([
      prisma.activityLog.count(),
      prisma.activityLog.findMany({
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
      }),
    ]);

    // get user details for each log
    const users = await prisma.user.findMany();
    const userMap = new Map(users.map((user) => [user.id, user]));

    // attach user details to each log
    const logsWithUserDetails = logs.map((log) => ({
      ...log,
      user: (log.user && userMap.get(log.user)) || null,
    }));

    // total pages for pagination
    const totalPages = Math.ceil(totalLogs / limit);

    // return logs with pagination info
    res.json({
      res: logsWithUserDetails,
      pagination: {
        currentPage: page,
        totalPages,
        totalData: totalLogs,
        limit,
      },
    });
  } catch (error) {
    console.error("Error fetching activity logs:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};
