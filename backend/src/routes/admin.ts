import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import { getOverview, sendAnnouncement } from "../controllers/admin";

const adminRouter = Router();

adminRouter.get("/overview", requireAuth, checkRole(["admin"]), getOverview);
adminRouter.post("/announcements", requireAuth, checkRole(["admin"]), sendAnnouncement);

export default adminRouter;
