import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  initiatePayment,
  getPaymentStatus,
  pesapalIpn,
  pesapalCallback,
} from "../controllers/payment";

const paymentRouter = Router();

// Called by Pesapal, not the app — must stay unauthenticated. They only
// trigger a status lookup against Pesapal itself, never trust the request.
paymentRouter.get("/pesapal/ipn", pesapalIpn);
paymentRouter.post("/pesapal/ipn", pesapalIpn);
paymentRouter.get("/pesapal/callback", pesapalCallback);

paymentRouter.post("/initiate", requireAuth, checkRole(["patient"]), initiatePayment);
paymentRouter.get("/:id/status", requireAuth, checkRole(["patient"]), getPaymentStatus);

export default paymentRouter;
