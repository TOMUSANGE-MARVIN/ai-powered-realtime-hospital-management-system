import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  getCategories,
  getCategoryOptions,
  createCategory,
  updateCategory,
  deleteCategory,
} from "../controllers/category";

const categoryRouter = Router();

// Any authenticated user (patients, doctors) can read the active category list
categoryRouter.get("/", requireAuth, getCategories);
categoryRouter.get(
  "/options",
  requireAuth,
  checkRole(["admin"]),
  getCategoryOptions,
);
categoryRouter.post("/", requireAuth, checkRole(["admin"]), createCategory);
categoryRouter.put("/:id", requireAuth, checkRole(["admin"]), updateCategory);
categoryRouter.delete(
  "/:id",
  requireAuth,
  checkRole(["admin"]),
  deleteCategory,
);

export default categoryRouter;
