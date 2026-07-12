import express from "express";

const userRouter = express.Router();

import {
  fetchAllUsers,
  getUserById,
  updateUser,
  updateMe,
  deleteMe,
  admitPatient,
  getPolarPortalLink,
} from "../controllers/user";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";

userRouter.get(
  "/",
  requireAuth,
  checkRole(["admin", "doctor", "nurse"]),
  fetchAllUsers,
);

// Self-service — any authenticated user editing/deleting their own profile
userRouter.patch("/me", requireAuth, updateMe);
userRouter.delete("/me", requireAuth, deleteMe);

userRouter.put(
  "/update/:id",
  requireAuth,
  //   allowed roles: admin, doctor, nurse
  checkRole(["admin", "doctor", "nurse"]),
  updateUser,
);

// only admin and medical staff can update patient profiles
userRouter.get("/profile/:id", requireAuth, getUserById);
// test admit
userRouter.post(
  "/:id/admit",
  requireAuth,
  checkRole(["admin", "doctor", "nurse"]),
  admitPatient,
);

userRouter.get("/polar-portal/:userId", requireAuth, getPolarPortalLink);

// if :id route is first, it will catch all routes including /update/:id, so we need to put it after the /update/:id route
export default userRouter;
