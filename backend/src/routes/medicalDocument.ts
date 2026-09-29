import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  createMedicalDocument,
  getMyMedicalDocuments,
  getPatientHistory,
} from "../controllers/medicalDocument";

const medicalDocumentRouter = Router();

medicalDocumentRouter.get(
  "/mine",
  requireAuth,
  checkRole(["patient"]),
  getMyMedicalDocuments,
);
medicalDocumentRouter.get(
  "/patient/:patientId",
  requireAuth,
  checkRole(["doctor"]),
  getPatientHistory,
);
medicalDocumentRouter.post(
  "/",
  requireAuth,
  checkRole(["patient"]),
  createMedicalDocument,
);

export default medicalDocumentRouter;
