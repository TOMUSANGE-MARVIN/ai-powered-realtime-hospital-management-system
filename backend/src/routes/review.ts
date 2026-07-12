import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  createReview,
  getDoctorReviews,
  getMyReviews,
  replyToReview,
} from "../controllers/review";

const reviewRouter = Router();

reviewRouter.post("/", requireAuth, checkRole(["patient"]), createReview);
// /mine must come before the /doctor/:doctorId catch-all.
reviewRouter.get("/mine", requireAuth, checkRole(["doctor"]), getMyReviews);
reviewRouter.get("/doctor/:doctorId", requireAuth, getDoctorReviews);
reviewRouter.post("/:id/reply", requireAuth, checkRole(["doctor"]), replyToReview);

export default reviewRouter;
