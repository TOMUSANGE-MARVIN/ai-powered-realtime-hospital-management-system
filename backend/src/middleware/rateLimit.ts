import crypto from "crypto";
import type { Request } from "express";
import { ipKeyGenerator, rateLimit } from "express-rate-limit";

// API rate limiting (E23.5). Sign-in, sign-up and 2FA have their own stricter
// limits inside better-auth (lib/auth.ts); these protect everything else.
//
// Many Ugandan mobile networks put thousands of phones behind one public IP
// (carrier-grade NAT), so a signed-in request is counted per session, not
// per IP — otherwise one busy user could lock out a whole network. Only
// signed-out requests fall back to the IP address (via Traefik; see
// `trust proxy` in server.ts).

const SESSION_COOKIES = ["__Secure-better-auth.session_token", "better-auth.session_token"];

function clientKey(req: Request) {
  for (const name of SESSION_COOKIES) {
    const token = req.cookies?.[name];
    if (token) {
      // Never keep the raw session token in memory as a map key.
      return "s:" + crypto.createHash("sha256").update(String(token)).digest("hex").slice(0, 32);
    }
  }
  return "ip:" + ipKeyGenerator(req.ip ?? "unknown", 56);
}

// Server-to-server callbacks (Pesapal) and the auth handler, which has its
// own limiter, are never counted here.
const EXEMPT = [/^\/api\/payments\/pesapal\//, /^\/api\/auth\//, /^\/api\/polar\//];

const tooMany = (what: string) => ({
  code: "rate_limited",
  message: `Too many ${what}. Please wait a few minutes and try again.`,
});

function limiter(options: {
  windowMinutes: number;
  limit: number;
  what: string;
  onlyWrites?: boolean;
}) {
  return rateLimit({
    windowMs: options.windowMinutes * 60 * 1000,
    limit: options.limit,
    standardHeaders: "draft-8",
    legacyHeaders: false,
    keyGenerator: clientKey,
    skip: (req) =>
      process.env.RATE_LIMIT === "off" ||
      EXEMPT.some((pattern) => pattern.test(req.originalUrl)) ||
      (options.onlyWrites === true && ["GET", "HEAD", "OPTIONS"].includes(req.method)),
    message: tooMany(options.what),
  });
}

/** Every /api request: generous — the app loads several endpoints per screen. */
export const apiLimiter = limiter({ windowMinutes: 5, limit: 600, what: "requests" });

/** Creating or changing anything. */
export const writeLimiter = limiter({
  windowMinutes: 5,
  limit: 120,
  what: "changes",
  onlyWrites: true,
});

/** AI symptom search — each call costs a Gemini request. */
export const aiLimiter = limiter({ windowMinutes: 10, limit: 15, what: "AI searches" });

/** File uploads (documents, photos, voice notes, licences). */
export const uploadLimiter = limiter({ windowMinutes: 10, limit: 40, what: "uploads" });

/** Starting payments. */
export const paymentLimiter = limiter({
  windowMinutes: 10,
  limit: 10,
  what: "payment attempts",
  onlyWrites: true,
});
