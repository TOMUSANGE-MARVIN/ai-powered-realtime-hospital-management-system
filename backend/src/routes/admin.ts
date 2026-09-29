import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  getCallLogs,
  getConsultations,
  getOverview,
} from "../controllers/admin";
import {
  countRecipients,
  getReports,
  listAnnouncements,
  listReviews,
  moderateReview,
  sendAnnouncement,
} from "../controllers/adminContent";

const adminRouter = Router();

adminRouter.get("/overview", requireAuth, checkRole(["admin"]), getOverview);
adminRouter.get("/consultations", requireAuth, checkRole(["admin"]), getConsultations);
adminRouter.get("/calls", requireAuth, checkRole(["admin"]), getCallLogs);
adminRouter.post("/announcements", requireAuth, checkRole(["admin"]), sendAnnouncement);
adminRouter.get("/announcements", requireAuth, checkRole(["admin"]), listAnnouncements);
adminRouter.get("/announcements/recipients", requireAuth, checkRole(["admin"]), countRecipients);
adminRouter.get("/reviews", requireAuth, checkRole(["admin"]), listReviews);
adminRouter.patch("/reviews/:id", requireAuth, checkRole(["admin"]), moderateReview);
adminRouter.get("/reports", requireAuth, checkRole(["admin"]), getReports);

export default adminRouter;
