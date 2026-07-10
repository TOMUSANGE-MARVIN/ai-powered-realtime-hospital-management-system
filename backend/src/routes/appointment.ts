import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  requestAppointment,
  getAppointments,
  createAppointment,
  updateAppointment,
  bookAppointment,
  getMyAppointments,
  cancelMyAppointment,
} from "../controllers/appointment";

const appointmentRouter = Router();

// Public — the marketing "Book Appointment" form
appointmentRouter.post("/request", requestAppointment);

// Patient (mobile app) — book with a specific doctor, view/cancel own appointments
appointmentRouter.post(
  "/book",
  requireAuth,
  checkRole(["patient"]),
  bookAppointment,
);
appointmentRouter.get(
  "/mine",
  requireAuth,
  checkRole(["patient"]),
  getMyAppointments,
);
appointmentRouter.patch(
  "/:id/cancel",
  requireAuth,
  checkRole(["patient"]),
  cancelMyAppointment,
);

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
