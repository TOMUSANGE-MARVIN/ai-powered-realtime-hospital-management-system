import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { logActivity } from "../lib/activity";

export const getTickets = async (req: Request, res: Response) => {
  try {
    const currentUser = (req as any).user;
    const isAdmin = currentUser.role === "admin";
    const where = isAdmin ? {} : { userId: currentUser.id };

    const tickets = await prisma.supportTicket.findMany({
      where,
      orderBy: { createdAt: "desc" },
    });
    res.json(tickets);
  } catch (error) {
    console.error("Error fetching tickets:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const createTicket = async (req: Request, res: Response) => {
  try {
    const currentUser = (req as any).user;
    const { subject, message, priority } = req.body;

    const ticket = await prisma.supportTicket.create({
      data: {
        userId: currentUser.id,
        userName: currentUser.name,
        subject,
        message,
        priority,
      },
    });

    const io = req.app.get("io");
    if (io) io.emit("support_ticket_updated");
    res.status(201).json(ticket);
  } catch (error) {
    console.error("Error creating ticket:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const updateTicketStatus = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { status } = req.body;

    const ticket = await prisma.supportTicket
      .update({ where: { id }, data: { status } })
      .catch(() => null);
    if (!ticket) {
      return res.status(404).json({ message: "Ticket not found" });
    }

    const io = req.app.get("io");
    if (io) io.emit("support_ticket_updated");
    await logActivity(
      (req as any).user.id,
      "Updated Support Ticket",
      `Marked ticket "${ticket.subject}" as ${status}`,
    );
    res.json(ticket);
  } catch (error) {
    console.error("Error updating ticket:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getFeedback = async (req: Request, res: Response) => {
  try {
    const feedback = await prisma.feedback.findMany({
      orderBy: { createdAt: "desc" },
      take: 100,
    });
    res.json(feedback);
  } catch (error) {
    console.error("Error fetching feedback:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const createFeedback = async (req: Request, res: Response) => {
  try {
    const currentUser = (req as any).user;
    const { category, message, rating } = req.body;

    const feedback = await prisma.feedback.create({
      data: {
        userId: currentUser.id,
        userName: currentUser.name,
        category,
        message,
        rating,
      },
    });

    res.status(201).json(feedback);
  } catch (error) {
    console.error("Error creating feedback:", error);
    res.status(500).json({ message: "Server error" });
  }
};
