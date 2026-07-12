import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  createMedicalDocument,
  getMyMedicalDocuments,
} from "../controllers/medicalDocument";

const medicalDocumentRouter = Router();

medicalDocumentRouter.get(
  "/mine",
  requireAuth,
  checkRole(["patient"]),
  getMyMedicalDocuments,
);
medicalDocumentRouter.post(
  "/",
  requireAuth,
  checkRole(["patient"]),
  createMedicalDocument,
);

export default medicalDocumentRouter;
