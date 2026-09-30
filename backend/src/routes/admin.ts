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
import { listPayments, refundPayment, syncPayment } from "../controllers/adminPayments";
import { listVerifications, reviewVerification } from "../controllers/doctorVerification";
import { listRecordAccess } from "../controllers/recordAccess";

const adminRouter = Router();

adminRouter.get("/overview", requireAuth, checkRole(["admin"]), getOverview);
adminRouter.get("/consultations", requireAuth, checkRole(["admin"]), getConsultations);
adminRouter.get("/calls", requireAuth, checkRole(["admin"]), getCallLogs);
adminRouter.post("/announcements", requireAuth, checkRole(["admin"]), sendAnnouncement);
adminRouter.get("/announcements", requireAuth, checkRole(["admin"]), listAnnouncements);
adminRouter.get("/announcements/recipients", requireAuth, checkRole(["admin"]), countRecipients);
adminRouter.get("/reviews", requireAuth, checkRole(["admin"]), listReviews);
adminRouter.patch("/reviews/:id", requireAuth, checkRole(["admin"]), moderateReview);
adminRouter.get("/payments", requireAuth, checkRole(["admin"]), listPayments);
adminRouter.post("/payments/:id/sync", requireAuth, checkRole(["admin"]), syncPayment);
adminRouter.post("/payments/:id/refund", requireAuth, checkRole(["admin"]), refundPayment);
adminRouter.get("/doctor-verifications", requireAuth, checkRole(["admin"]), listVerifications);
adminRouter.post("/doctor-verifications/:id", requireAuth, checkRole(["admin"]), reviewVerification);
adminRouter.get("/record-access", requireAuth, checkRole(["admin"]), listRecordAccess);
adminRouter.get("/reports", requireAuth, checkRole(["admin"]), getReports);

export default adminRouter;
