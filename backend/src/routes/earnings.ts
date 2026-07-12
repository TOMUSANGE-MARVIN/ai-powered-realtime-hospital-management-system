import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import { getMyEarnings } from "../controllers/earnings";

const earningsRouter = Router();

earningsRouter.get("/mine", requireAuth, checkRole(["doctor"]), getMyEarnings);

export default earningsRouter;
