import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import { checkRole } from "../middleware/checkRole";
import {
  createPost,
  deletePost,
  getPublishedPost,
  listAllPosts,
  listPublishedPosts,
  updatePost,
} from "../controllers/blog";

const blogRouter = Router();

// Admin routes first so "/admin/all" isn't taken as a slug.
blogRouter.get("/admin/all", requireAuth, checkRole(["admin"]), listAllPosts);
blogRouter.post("/", requireAuth, checkRole(["admin"]), createPost);
blogRouter.patch("/:id", requireAuth, checkRole(["admin"]), updatePost);
blogRouter.delete("/:id", requireAuth, checkRole(["admin"]), deletePost);

// Public — the marketing site.
blogRouter.get("/", listPublishedPosts);
blogRouter.get("/:slug", getPublishedPost);

export default blogRouter;
