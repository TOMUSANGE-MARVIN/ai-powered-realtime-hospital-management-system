import type { Request, Response } from "express";
import { logActivity } from "../lib/activity";
import { inngest } from "../inngest/client";
import { polarClient } from "../lib/auth";
import { prisma } from "../lib/prisma";
import { isUserOnline } from "../lib/socket";

// Whether a user currently has a live Socket.IO connection — not sensitive
// data, so no role restriction (used for the chat header and the caller's
// "Calling…" vs "Ringing…" wording).
export const getUserOnlineStatus = async (req: Request, res: Response) => {
  const id = req.params.id as string;
  res.json({ online: isUserOnline(id) });
};

export const getUserById = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    // to use current user, we need a middleware
    const currentUser = (req as any).user; // Assuming you have a middleware that attaches the user to the request object

    // Check permissions: A user can view their own profile,
    // or Admins/Medical staff can view patient profiles.
    if (currentUser.id !== id && currentUser.role === "patient") {
      return res.status(403).json({ message: "Forbidden" });
    }

    const user = await prisma.user.findUnique({ where: { id } });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(user);
  } catch (error) {
    console.error("Error fetching user:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const updateUser = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { name, email, role, password, ...customFields } = req.body; // Add fields you want to update

    const existingUser = await prisma.user.findUnique({ where: { id } });
    if (!existingUser) {
      return res.status(404).json({ message: "User not found" });
    }

    const updatePayload: Record<string, unknown> = {
      name,
      email,
      role,
      ...customFields,
    };

    // Remove undefined/null keys
    Object.keys(updatePayload).forEach(
      (key) =>
        (updatePayload[key] === undefined || updatePayload[key] === null) &&
        delete updatePayload[key],
    );

    const updatedUser = await prisma.user.update({
      where: { id },
      data: updatePayload,
    });

    // socket notification
    const io = req.app.get("io");
    if (io) {
      io.emit("notify_user_updated");
    }

    // activity log
    await logActivity(
      (req as any).user.id, // you can also use name but id is more reliable
      "Updated User",
      `User updated: ${id}`,
    );
    res.json({
      message: "User updated successfully",
      updatedUser,
    });
  } catch (error) {
    console.error("Error updating user:", error);
    res.status(500).json({ message: "Server error" });
  }
};

export const fetchAllUsers = async (req: Request, res: Response) => {
  try {
    //  Pagination Params (Default: Page 1, Limit 10)
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const limit = Math.max(1, parseInt(req.query.limit as string) || 10);
    const skip = (page - 1) * limit;
    const where: any = {};
    const role = req.query.role as string;

    // Only add role to filter if it exists and isn't empty/all
    if (role && role !== "all" && role !== "") {
      where.role = role;
    }

    const [totalUsers, users] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        omit: { emailVerified: true },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
      }),
    ]);

    res.json({
      res: users,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalUsers / limit),
        totalData: totalUsers,
        limit,
      },
    });
  } catch (error) {
    console.error("Error fetching users:", error);
    res.status(500).json({ message: "Server error" });
  }
};

//admit
export const admitPatient = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const { admissionReason } = req.body;

    // trigger inngest
    await inngest.send({
      name: "patient/admitted",
      data: { patientId: id, admissionReason },
    });
    // log who did these
    await logActivity(
      (req as any).user.id,
      "Admitted Patient",
      `Admitted patient ${id}`,
    );
    // when you don't want your api routes or functions to load forever make sure to finish with a response, otherwise the client will keep waiting for a response until it times out
    res.json({ message: "Patient admission requested successfully" });
  } catch (error) {
    console.error("Error admitting patient:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Self-service profile update — any authenticated role can edit their own profile
export const updateMe = async (req: Request, res: Response) => {
  try {
    const currentUser = (req as any).user;
    const {
      name,
      image,
      gender,
      bloodgroup,
      maritalStatus,
      age,
      bio,
      hospitalName,
      hospitalAddress,
      consultationFee,
      specialization,
      department,
      emergencyContactName,
      emergencyContactPhone,
      emergencyContactRelation,
    } = req.body;

    const updatePayload: Record<string, unknown> = {
      name,
      image,
      gender,
      bloodgroup,
      maritalStatus,
      age,
      bio,
      hospitalName,
      hospitalAddress,
      consultationFee,
      specialization,
      department,
      emergencyContactName,
      emergencyContactPhone,
      emergencyContactRelation,
    };
    Object.keys(updatePayload).forEach(
      (key) =>
        (updatePayload[key] === undefined || updatePayload[key] === null) &&
        delete updatePayload[key],
    );

    const updatedUser = await prisma.user.update({
      where: { id: currentUser.id },
      data: updatePayload,
    });

    res.json({ message: "Profile updated successfully", updatedUser });
  } catch (error) {
    console.error("Error updating own profile:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// Self-service account deletion
export const deleteMe = async (req: Request, res: Response) => {
  try {
    const currentUser = (req as any).user;
    await prisma.user.delete({ where: { id: currentUser.id } });
    res.json({ message: "Account deleted successfully" });
  } catch (error) {
    console.error("Error deleting own account:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// polar portal
export const getPolarPortalLink = async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ message: "User ID is required" });
    }
    const result = await polarClient.customerSessions.create({
      externalCustomerId: userId as string, // The internal Polar Customer ID
    });
    res.json({ polarPortalUrl: result.customerPortalUrl });
  } catch (error) {
    console.error("Error fetching Polar portal link:", error);
    res.status(500).json({ message: "Server error" });
  }
};
