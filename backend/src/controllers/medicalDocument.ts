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

// Doctor's "Full History" view of a patient: profile snapshot, uploaded
// documents and past consultations with this doctor. Only allowed once the
// two have an appointment or have chatted.
export const getPatientHistory = async (req: Request, res: Response) => {
  try {
    const doctor = (req as any).user;
    const patientId = req.params.patientId as string;

    const [appointment, message] = await Promise.all([
      prisma.appointment.findFirst({
        where: { doctorId: doctor.id, patientId },
        select: { id: true },
      }),
      prisma.message.findFirst({
        where: {
          OR: [
            { senderId: doctor.id, receiverId: patientId },
            { senderId: patientId, receiverId: doctor.id },
          ],
        },
        select: { id: true },
      }),
    ]);
    if (!appointment && !message) {
      return res
        .status(403)
        .json({ message: "You have no consultations with this patient" });
    }

    const patient = await prisma.user.findUnique({
      where: { id: patientId },
      select: {
        id: true,
        name: true,
        image: true,
        age: true,
        gender: true,
        bloodgroup: true,
        medicalHistory: true,
      },
    });
    if (!patient) {
      return res.status(404).json({ message: "Patient not found" });
    }

    const [documents, appointments] = await Promise.all([
      prisma.medicalDocument.findMany({
        where: { patientId },
        orderBy: { createdAt: "desc" },
      }),
      prisma.appointment.findMany({
        where: { doctorId: doctor.id, patientId },
        orderBy: { date: "desc" },
        take: 20,
        select: {
          id: true,
          date: true,
          time: true,
          status: true,
          consultationType: true,
          reason: true,
          notes: true,
        },
      }),
    ]);

    res.json({ patient, documents, appointments });
  } catch (error) {
    console.error("Error fetching patient history:", error);
    res.status(500).json({ message: "Server error" });
  }
};
