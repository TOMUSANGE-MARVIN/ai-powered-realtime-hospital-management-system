import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import { getSetting, updateSetting } from "../controllers/setting";

const settingRouter = Router();

settingRouter.get(
  "/:key",
  requireAuth,
  checkRole(["admin"]),
  getSetting,
);
settingRouter.put(
  "/:key",
  requireAuth,
  checkRole(["admin"]),
  updateSetting,
);

export default settingRouter;
