import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { addTimeOff, deleteTimeOff, listMyTimeOff } from "../controllers/timeOff";
import { checkRole } from "../middleware/checkRole";
import {
  listDoctors,
  getDoctorSpecialties,
  getDoctorById,
} from "../controllers/doctor";
import {
  applyAsDoctor,
  getMyVerification,
  submitMyVerification,
} from "../controllers/doctorVerification";

const doctorRouter = Router();

// Any authenticated user (patients included) can browse/search doctors
doctorRouter.get("/", requireAuth, listDoctors);
doctorRouter.get("/specialties", requireAuth, getDoctorSpecialties);
// Licence verification — deliberately not behind checkRole(["doctor"]),
// which refuses doctors until they're approved.
doctorRouter.post("/apply", requireAuth, applyAsDoctor);
doctorRouter.get("/me/verification", requireAuth, getMyVerification);
doctorRouter.put("/me/verification", requireAuth, submitMyVerification);
doctorRouter.get("/me/time-off", requireAuth, checkRole(["doctor"]), listMyTimeOff);
doctorRouter.post("/me/time-off", requireAuth, checkRole(["doctor"]), addTimeOff);
doctorRouter.delete("/me/time-off/:id", requireAuth, checkRole(["doctor"]), deleteTimeOff);
doctorRouter.get("/:id", requireAuth, getDoctorById);

export default doctorRouter;
