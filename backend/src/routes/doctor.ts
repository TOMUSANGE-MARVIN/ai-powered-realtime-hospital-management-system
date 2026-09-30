import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { addTimeOff, deleteTimeOff, listMyTimeOff } from "../controllers/timeOff";
import { checkRole } from "../middleware/checkRole";
import {
  listDoctors,
  getDoctorSpecialties,
  getDoctorById,
} from "../controllers/doctor";

const doctorRouter = Router();

// Any authenticated user (patients included) can browse/search doctors
doctorRouter.get("/", requireAuth, listDoctors);
doctorRouter.get("/specialties", requireAuth, getDoctorSpecialties);
doctorRouter.get("/me/time-off", requireAuth, checkRole(["doctor"]), listMyTimeOff);
doctorRouter.post("/me/time-off", requireAuth, checkRole(["doctor"]), addTimeOff);
doctorRouter.delete("/me/time-off/:id", requireAuth, checkRole(["doctor"]), deleteTimeOff);
doctorRouter.get("/:id", requireAuth, getDoctorById);

export default doctorRouter;
