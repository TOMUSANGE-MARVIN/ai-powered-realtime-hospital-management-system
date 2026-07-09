import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  getMedications,
  createMedication,
  updateMedication,
  deleteMedication,
} from "../controllers/medication";

const medicationRouter = Router();

medicationRouter.get(
  "/",
  requireAuth,
  checkRole(["admin", "pharmacist", "doctor"]),
  getMedications,
);
medicationRouter.post(
  "/",
  requireAuth,
  checkRole(["admin", "pharmacist"]),
  createMedication,
);
medicationRouter.put(
  "/:id",
  requireAuth,
  checkRole(["admin", "pharmacist"]),
  updateMedication,
);
medicationRouter.delete(
  "/:id",
  requireAuth,
  checkRole(["admin", "pharmacist"]),
  deleteMedication,
);

export default medicationRouter;
