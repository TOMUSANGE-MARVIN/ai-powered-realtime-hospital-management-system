import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  getMyWithdrawals,
  listWithdrawals,
  requestWithdrawal,
  updateWithdrawal,
} from "../controllers/withdrawal";

const withdrawalRouter = Router();

withdrawalRouter.post("/", requireAuth, checkRole(["doctor"]), requestWithdrawal);
withdrawalRouter.get("/mine", requireAuth, checkRole(["doctor"]), getMyWithdrawals);
withdrawalRouter.get("/", requireAuth, checkRole(["admin"]), listWithdrawals);
withdrawalRouter.patch("/:id", requireAuth, checkRole(["admin"]), updateWithdrawal);

export default withdrawalRouter;
