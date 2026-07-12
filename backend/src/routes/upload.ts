import { Router } from "express";
import multer from "multer";
import path from "path";
import crypto from "crypto";
import { requireAuth } from "../middleware/auth";

const storage = multer.diskStorage({
  destination: path.join(__dirname, "../../uploads"),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${crypto.randomUUID()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
});

const uploadRouter = Router();

// Generic authenticated file upload (mobile app: prescription photos,
// signatures, medical documents) — stored on local disk, served statically
// from /uploads. Separate from the web frontend's UploadThing-based flow.
uploadRouter.post("/", requireAuth, upload.single("file"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: "No file uploaded" });
  }
  // Built from the incoming request rather than a fixed env var so this
  // works whether the client hit localhost, a LAN IP (mobile dev), or the
  // production domain — a hardcoded BETTER_AUTH_URL of "localhost" is
  // unreachable from a phone on the same network.
  const url = `${req.protocol}://${req.get("host")}/uploads/${req.file.filename}`;
  res.status(201).json({ url });
});

export default uploadRouter;
