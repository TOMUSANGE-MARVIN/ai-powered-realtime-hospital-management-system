import type { Request, Response } from "express";
import { prisma } from "../lib/prisma";
import { logActivity } from "../lib/activity";

export const ICON_KEYS = [
  { key: "internal_medicine", label: "Internal Medicine" },
  { key: "pediatrics", label: "Pediatrics" },
  { key: "orthopedics", label: "Orthopedics" },
  { key: "cardiology", label: "Cardiology" },
  { key: "obstetrics_gynecology", label: "Obstetrics & Gynecology" },
  { key: "emergency_medicine", label: "Emergency Medicine" },
  { key: "neurology", label: "Neurology" },
  { key: "dermatology", label: "Dermatology" },
  { key: "general", label: "General" },
];

export const COLOR_KEYS = [
  { key: "blue", label: "Blue" },
  { key: "teal", label: "Teal" },
  { key: "orange", label: "Orange" },
  { key: "pink", label: "Pink" },
  { key: "purple", label: "Purple" },
  { key: "red", label: "Red" },
  { key: "indigo", label: "Indigo" },
  { key: "amber", label: "Amber" },
  { key: "lavender", label: "Lavender" },
];

const VALID_ICON_KEYS = new Set(ICON_KEYS.map((i) => i.key));
const VALID_COLOR_KEYS = new Set(COLOR_KEYS.map((c) => c.key));

export const getCategories = async (req: Request, res: Response) => {
  try {
    const includeInactive = req.query.includeInactive === "true";
    const categories = await prisma.category.findMany({
      where: includeInactive ? {} : { isActive: true },
      orderBy: { name: "asc" },
    });
    res.json(categories);
  } catch (error) {
    console.error("Error fetching categories:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const getCategoryOptions = async (_req: Request, res: Response) => {
  res.json({ icons: ICON_KEYS, colors: COLOR_KEYS });
};

export const createCategory = async (req: Request, res: Response) => {
  try {
    const { name, iconKey, colorKey, department } = req.body;

    if (!name || typeof name !== "string" || !name.trim()) {
      return res.status(400).json({ message: "Name is required" });
    }
    if (iconKey && !VALID_ICON_KEYS.has(iconKey)) {
      return res.status(400).json({ message: "Invalid iconKey" });
    }
    if (colorKey && !VALID_COLOR_KEYS.has(colorKey)) {
      return res.status(400).json({ message: "Invalid colorKey" });
    }

    const existing = await prisma.category.findFirst({
      where: { name: { equals: name.trim() } },
    });
    if (existing) {
      return res.status(400).json({ message: "A category with this name already exists" });
    }

    const category = await prisma.category.create({
      data: {
        name: name.trim(),
        iconKey: iconKey || "general",
        colorKey: colorKey || "lavender",
        department: department || null,
      },
    });

    const io = req.app.get("io");
    if (io) io.emit("category_updated");
    await logActivity(
      (req as any).user.id,
      "Added Category",
      `Added category ${category.name}`,
    );

    res.status(201).json(category);
  } catch (error) {
    console.error("Error creating category:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const updateCategory = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { name, iconKey, colorKey, department, isActive } = req.body;

    if (name !== undefined && (typeof name !== "string" || !name.trim())) {
      return res.status(400).json({ message: "Name cannot be empty" });
    }
    if (iconKey !== undefined && !VALID_ICON_KEYS.has(iconKey)) {
      return res.status(400).json({ message: "Invalid iconKey" });
    }
    if (colorKey !== undefined && !VALID_COLOR_KEYS.has(colorKey)) {
      return res.status(400).json({ message: "Invalid colorKey" });
    }

    if (name !== undefined) {
      const existing = await prisma.category.findFirst({
        where: { name: { equals: name.trim() }, NOT: { id } },
      });
      if (existing) {
        return res.status(400).json({ message: "A category with this name already exists" });
      }
    }

    const category = await prisma.category
      .update({
        where: { id },
        data: {
          ...(name !== undefined && { name: name.trim() }),
          ...(iconKey !== undefined && { iconKey }),
          ...(colorKey !== undefined && { colorKey }),
          ...(department !== undefined && { department }),
          ...(isActive !== undefined && { isActive }),
        },
      })
      .catch(() => null);

    if (!category) {
      return res.status(404).json({ message: "Category not found" });
    }

    const io = req.app.get("io");
    if (io) io.emit("category_updated");
    await logActivity(
      (req as any).user.id,
      "Updated Category",
      `Updated category ${category.name}`,
    );

    res.json(category);
  } catch (error) {
    console.error("Error updating category:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const deleteCategory = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const category = await prisma.category
      .update({ where: { id }, data: { isActive: false } })
      .catch(() => null);

    if (!category) {
      return res.status(404).json({ message: "Category not found" });
    }

    const io = req.app.get("io");
    if (io) io.emit("category_updated");
    await logActivity(
      (req as any).user.id,
      "Removed Category",
      `Deactivated category ${category.name}`,
    );

    res.json({ message: "Category deactivated" });
  } catch (error) {
    console.error("Error deleting category:", error);
    res.status(500).json({ message: "Server error" });
  }
};
