import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { getMyCalls, recordCall } from "../controllers/call";

const callRouter = Router();

callRouter.post("/", requireAuth, recordCall);
callRouter.get("/mine", requireAuth, getMyCalls);

export default callRouter;
