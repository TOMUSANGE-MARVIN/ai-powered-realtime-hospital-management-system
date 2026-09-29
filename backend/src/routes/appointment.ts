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
  rescheduleMyAppointment,
  getAssignedAppointments,
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

appointmentRouter.patch(
  "/:id/reschedule",
  requireAuth,
  checkRole(["patient"]),
  rescheduleMyAppointment,
);

// Doctor (mobile app) — appointments assigned to the authenticated doctor
appointmentRouter.get(
  "/assigned",
  requireAuth,
  checkRole(["doctor"]),
  getAssignedAppointments,
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
