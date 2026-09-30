import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import { getMyRecordAccess } from "../controllers/recordAccess";

const recordAccessRouter = Router();

recordAccessRouter.get("/mine", requireAuth, checkRole(["patient"]), getMyRecordAccess);

export default recordAccessRouter;
