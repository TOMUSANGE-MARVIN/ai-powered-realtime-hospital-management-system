import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  getTickets,
  createTicket,
  updateTicketStatus,
  getFeedback,
  createFeedback,
} from "../controllers/support";

const supportRouter = Router();

const anyStaffOrPatient: any = [
  "admin",
  "doctor",
  "nurse",
  "pharmacist",
  "lab_tech",
  "patient",
];

supportRouter.get("/tickets", requireAuth, checkRole(anyStaffOrPatient), getTickets);
supportRouter.post(
  "/tickets",
  requireAuth,
  checkRole(anyStaffOrPatient),
  createTicket,
);
supportRouter.put(
  "/tickets/:id",
  requireAuth,
  checkRole(["admin"]),
  updateTicketStatus,
);

supportRouter.get("/feedback", requireAuth, checkRole(["admin"]), getFeedback);
supportRouter.post(
  "/feedback",
  requireAuth,
  checkRole(anyStaffOrPatient),
  createFeedback,
);

export default supportRouter;
