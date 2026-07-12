import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";

export const createMedicalDocument = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const { title, url } = req.body;

    if (!title || !url) {
      return res.status(400).json({ message: "title and url are required" });
    }

    const document = await prisma.medicalDocument.create({
      data: { patientId: patient.id, title, url },
    });

    res.status(201).json(document);
  } catch (error) {
    console.error("Error creating medical document:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getMyMedicalDocuments = async (req: Request, res: Response) => {
  try {
    const patient = (req as any).user;
    const documents = await prisma.medicalDocument.findMany({
      where: { patientId: patient.id },
      orderBy: { createdAt: "desc" },
    });
    res.json(documents);
  } catch (error) {
    console.error("Error fetching medical documents:", error);
    res.status(500).json({ message: "Server error" });
  }
};
