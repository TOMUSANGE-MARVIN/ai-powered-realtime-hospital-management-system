import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  getPrescriptions,
  createPrescription,
  dispensePrescription,
  cancelPrescription,
  getMyPrescriptions,
  extractPrescription,
  getIssuedPrescriptions,
} from "../controllers/prescription";

const prescriptionRouter = Router();

// Patient (mobile app) — own prescriptions
prescriptionRouter.get(
  "/mine",
  requireAuth,
  checkRole(["patient"]),
  getMyPrescriptions,
);

prescriptionRouter.get(
  "/issued",
  requireAuth,
  checkRole(["doctor"]),
  getIssuedPrescriptions,
);

prescriptionRouter.get(
  "/",
  requireAuth,
  checkRole(["admin", "pharmacist", "doctor", "nurse"]),
  getPrescriptions,
);
prescriptionRouter.post(
  "/extract",
  requireAuth,
  checkRole(["doctor"]),
  extractPrescription,
);
prescriptionRouter.post(
  "/",
  requireAuth,
  checkRole(["admin", "doctor"]),
  createPrescription,
);
prescriptionRouter.post(
  "/:id/dispense",
  requireAuth,
  checkRole(["admin", "pharmacist"]),
  dispensePrescription,
);
prescriptionRouter.post(
  "/:id/cancel",
  requireAuth,
  checkRole(["admin", "pharmacist", "doctor"]),
  cancelPrescription,
);

export default prescriptionRouter;
