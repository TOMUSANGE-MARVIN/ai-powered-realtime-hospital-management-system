import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { logActivity } from "../lib/activity";
import { getLegalDocuments, saveLegalDocuments } from "../lib/legal";

// GET /api/legal — public, so the Register screen and the website can show
// the documents before anyone signs in.
export const getLegal = async (_req: Request, res: Response) => {
  try {
    res.json(await getLegalDocuments());
  } catch (error) {
    console.error("Error fetching legal documents:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// POST /api/legal/accept { version } — the signed-in user accepts the
// current Terms and Privacy Policy.
export const acceptLegal = async (req: Request, res: Response) => {
  try {
    const user = (req as any).user;
    const docs = await getLegalDocuments();
    if (req.body?.version !== docs.version) {
      return res.status(409).json({
        code: "legal_version_changed",
        message: "The Terms or Privacy Policy just changed. Please review the latest version.",
        version: docs.version,
      });
    }
    await prisma.$transaction([
      prisma.user.update({
        where: { id: user.id },
        data: { legalAcceptedVersion: docs.version },
      }),
      prisma.consent.createMany({
        data: [
          { userId: user.id, type: "terms", version: docs.version },
          { userId: user.id, type: "privacy", version: docs.version },
        ],
      }),
    ]);
    res.json({ legalAcceptedVersion: docs.version });
  } catch (error) {
    console.error("Error accepting legal documents:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// PUT /api/legal (admin) { terms?, privacy?, telemedicineConsent?, publishNewVersion? }
export const updateLegal = async (req: Request, res: Response) => {
  try {
    const admin = (req as any).user;
    const pick = (key: string) =>
      typeof req.body?.[key] === "string" && req.body[key].trim() ? req.body[key].trim() : undefined;
    const publish = req.body?.publishNewVersion === true;
    const docs = await saveLegalDocuments(
      {
        terms: pick("terms"),
        privacy: pick("privacy"),
        telemedicineConsent: pick("telemedicineConsent"),
      },
      publish,
    );
    await logActivity(
      admin.id,
      publish ? "Legal Version Published" : "Legal Text Edited",
      `${admin.name} ${publish ? `published version ${docs.version}` : "edited the legal documents"}`,
    );
    res.json(docs);
  } catch (error) {
    console.error("Error updating legal documents:", error);
    res.status(500).json({ message: "Server error" });
  }
};
