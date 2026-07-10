import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { logActivity } from "../lib/activity";

const DEFAULTS: Record<string, Record<string, any>> = {
  general: {
    hospitalName: "Ask Musawo",
    supportEmail: "support@askmusawo.co.ug",
    supportPhone: "+256 700 123 456",
    address: "Plot 12, Acacia Avenue, Kampala, Uganda",
    timezone: "Africa/Kampala",
  },
  billing: {
    currency: "UGX",
    taxRatePercent: 0,
    paymentTerms: "Due on receipt",
    invoiceFooter: "Thank you for choosing Ask Musawo.",
  },
};

export const getSetting = async (req: Request, res: Response) => {
  try {
    const key = req.params.key as string;
    const setting = await prisma.setting.findUnique({ where: { key } });
    res.json({ key, data: setting?.data || DEFAULTS[key] || {} });
  } catch (error) {
    console.error("Error fetching setting:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const updateSetting = async (req: Request, res: Response) => {
  try {
    const key = req.params.key as string;
    const { data } = req.body;

    const setting = await prisma.setting.upsert({
      where: { key },
      update: { data },
      create: { key, data },
    });

    await logActivity(
      (req as any).user.id,
      "Updated Settings",
      `Updated "${key}" settings`,
    );
    res.json({ key, data: setting.data });
  } catch (error) {
    console.error("Error updating setting:", error);
    res.status(500).json({ message: "Server error" });
  }
};
