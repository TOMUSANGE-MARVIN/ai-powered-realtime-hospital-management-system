import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import { initiatePayment, confirmPayment } from "../controllers/payment";

const paymentRouter = Router();

paymentRouter.post("/initiate", requireAuth, checkRole(["patient"]), initiatePayment);
paymentRouter.post("/:id/confirm", requireAuth, checkRole(["patient"]), confirmPayment);

export default paymentRouter;
