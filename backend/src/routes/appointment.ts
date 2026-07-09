import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  requestAppointment,
  getAppointments,
  createAppointment,
  updateAppointment,
} from "../controllers/appointment";

const appointmentRouter = Router();

// Public — the marketing "Book Appointment" form
appointmentRouter.post("/request", requestAppointment);

appointmentRouter.get(
  "/",
  requireAuth,
  checkRole(["admin", "doctor", "nurse"]),
  getAppointments,
);
appointmentRouter.post(
  "/",
  requireAuth,
  checkRole(["admin", "doctor", "nurse"]),
  createAppointment,
);
appointmentRouter.put(
  "/:id",
  requireAuth,
  checkRole(["admin", "doctor", "nurse"]),
  updateAppointment,
);

export default appointmentRouter;
