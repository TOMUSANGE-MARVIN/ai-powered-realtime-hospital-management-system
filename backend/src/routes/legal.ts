import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import { acceptLegal, getLegal, updateLegal } from "../controllers/legal";

const legalRouter = Router();

legalRouter.get("/", getLegal);
legalRouter.post("/accept", requireAuth, acceptLegal);
legalRouter.put("/", requireAuth, checkRole(["admin"]), updateLegal);

export default legalRouter;
