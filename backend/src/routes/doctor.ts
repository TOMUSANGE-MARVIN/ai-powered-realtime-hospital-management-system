import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import {
  listDoctors,
  getDoctorSpecialties,
  getDoctorById,
} from "../controllers/doctor";

const doctorRouter = Router();

// Any authenticated user (patients included) can browse/search doctors
doctorRouter.get("/", requireAuth, listDoctors);
doctorRouter.get("/specialties", requireAuth, getDoctorSpecialties);
doctorRouter.get("/:id", requireAuth, getDoctorById);

export default doctorRouter;
