import { Router } from "express";
import { requireAuth } from "../middleware/auth";
import {
  deleteMessage,
  getConversation,
  getConversations,
  sendMessage,
} from "../controllers/message";

const messageRouter = Router();

// Any authenticated user (patient or doctor) can message the other side.
// /conversations must come before the /:otherUserId catch-all.
messageRouter.get("/conversations", requireAuth, getConversations);
messageRouter.get("/:otherUserId", requireAuth, getConversation);
messageRouter.post("/", requireAuth, sendMessage);
messageRouter.delete("/:id", requireAuth, deleteMessage);

export default messageRouter;
