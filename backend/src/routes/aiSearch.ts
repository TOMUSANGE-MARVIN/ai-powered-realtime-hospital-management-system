import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import { aiSymptomSearch } from "../controllers/aiSearch";

const aiSearchRouter = Router();

aiSearchRouter.post("/symptom-search", requireAuth, checkRole(["patient"]), aiSymptomSearch);

export default aiSearchRouter;
