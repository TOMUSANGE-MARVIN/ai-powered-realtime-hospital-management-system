import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  getCallLogs,
  getConsultations,
  getOverview,
  sendAnnouncement,
} from "../controllers/admin";

const adminRouter = Router();

adminRouter.get("/overview", requireAuth, checkRole(["admin"]), getOverview);
adminRouter.get("/consultations", requireAuth, checkRole(["admin"]), getConsultations);
adminRouter.get("/calls", requireAuth, checkRole(["admin"]), getCallLogs);
adminRouter.post("/announcements", requireAuth, checkRole(["admin"]), sendAnnouncement);

export default adminRouter;
