import type { Request, Response } from "express";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { prisma } from "../lib/prisma";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_KEY!);

// Patient describes symptoms in free text; Gemini maps them to the
// specialties we actually have doctors in, same model/pattern as the
// admission-triage and X-ray analysis AI features in inngest/functions.ts.
export const aiSymptomSearch = async (req: Request, res: Response) => {
  try {
    const { symptoms } = req.body;
    if (!symptoms || !symptoms.trim()) {
      return res.status(400).json({ message: "Please describe your symptoms" });
    }

    const categories = await prisma.category.findMany({
      where: { isActive: true },
      select: { name: true },
    });
    const KNOWN_SPECIALTIES = categories.map((c) => c.name);

    let matches: { specialty: string; reason: string }[];
    try {
      const model = genAI.getGenerativeModel({
        model: "gemini-3-flash-preview",
        generationConfig: { responseMimeType: "application/json" },
      });
      const prompt = `A patient describes these symptoms: "${symptoms.trim()}"

Available medical specialties: ${KNOWN_SPECIALTIES.join(", ")}.

Return a JSON array of the 1-3 most relevant specialties for this patient to see, ordered by relevance (most relevant first), each with a short one-sentence reason written directly to the patient. Only use specialties from the list above, exactly as spelled. If the symptoms sound like a medical emergency (e.g. chest pain, difficulty breathing, severe bleeding, loss of consciousness), put "Emergency Medicine" first regardless of the other symptoms.

Format exactly like this: [{"specialty": "Cardiology", "reason": "..."}]`;

      const result = await model.generateContent(prompt);
      const text = result.response.text();
      const cleanJson = text.replace(/```json/g, "").replace(/```/g, "").trim();
      matches = JSON.parse(cleanJson);
    } catch (aiError) {
      console.error("AI symptom search failed:", aiError);
      return res.status(503).json({
        message: "AI search isn't available right now. Please try searching manually.",
      });
    }

    // Only keep specialties we actually recognize, in the AI's suggested order.
    const validMatches = matches.filter((m) => KNOWN_SPECIALTIES.includes(m.specialty));
    if (validMatches.length === 0) {
      return res.json({ matches: [], doctors: [] });
    }

    const doctors = await prisma.user.findMany({
      where: { role: "doctor", specialization: { in: validMatches.map((m) => m.specialty) } },
      select: {
        id: true,
        name: true,
        email: true,
        image: true,
        specialization: true,
        department: true,
        bio: true,
        hospitalName: true,
        consultationFee: true,
      },
    });

    const ratingGroups = doctors.length
      ? await prisma.review.groupBy({
          by: ["doctorId"],
          where: { doctorId: { in: doctors.map((d) => d.id) } },
          _avg: { rating: true },
          _count: { rating: true },
        })
      : [];
    const ratingsByDoctor = new Map(ratingGroups.map((g) => [g.doctorId, g]));
    const doctorsWithRatings = doctors.map((d) => {
      const g = ratingsByDoctor.get(d.id);
      return { ...d, rating: g?._avg.rating ?? null, reviewCount: g?._count.rating ?? 0 };
    });

    res.json({ matches: validMatches, doctors: doctorsWithRatings });
  } catch (error) {
    console.error("Error in AI symptom search:", error);
    res.status(500).json({ message: "Server error" });
  }
};
