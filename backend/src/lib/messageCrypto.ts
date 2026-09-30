import crypto from "crypto";

// Chat messages encrypted at rest (E23.5). Message text, the quoted reply
// text and attachment file names are stored as AES-256-GCM ciphertext, so a
// copied database file or backup doesn't expose conversations. The key lives
// only in the MESSAGE_ENCRYPTION_KEY environment variable (Coolify), never in
// the database. Messages travel over HTTPS/WSS and are decrypted server-side
// before being sent to the two people in the conversation.
//
// Stored format: "enc:v1:" + base64(iv[12] | authTag[16] | ciphertext).
// The version prefix leaves room to rotate keys later. Values without the
// prefix are plaintext written before encryption was switched on, and are
// returned as they are — scripts/encrypt-messages.ts converts them.
//
// Generate a key with:  openssl rand -base64 32

const PREFIX = "enc:v1:";

function loadKey(): Buffer | null {
  const raw = process.env.MESSAGE_ENCRYPTION_KEY;
  if (!raw) return null;
  const key = Buffer.from(raw, "base64");
  if (key.length !== 32) {
    throw new Error("MESSAGE_ENCRYPTION_KEY must be 32 bytes, base64-encoded (openssl rand -base64 32)");
  }
  return key;
}

const KEY = loadKey();
if (!KEY) {
  console.warn(
    "⚠️  MESSAGE_ENCRYPTION_KEY is not set — chat messages are being stored unencrypted.",
  );
}

export const messageEncryptionEnabled = KEY !== null;

export function isEncrypted(value: string | null | undefined) {
  return typeof value === "string" && value.startsWith(PREFIX);
}

/** Encrypts [value] for storage. Empty strings and nulls stay as they are. */
export function encryptText<T extends string | null | undefined>(value: T): T {
  if (!KEY || !value || isEncrypted(value)) return value;
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", KEY, iv);
  const ciphertext = Buffer.concat([cipher.update(value, "utf8"), cipher.final()]);
  const tag = cipher.getAuthTag();
  return (PREFIX + Buffer.concat([iv, tag, ciphertext]).toString("base64")) as T;
}

/** Decrypts a stored value; plaintext (pre-encryption rows) passes through. */
export function decryptText<T extends string | null | undefined>(value: T): T {
  if (!isEncrypted(value)) return value;
  if (!KEY) return "[Encrypted message]" as T;
  try {
    const data = Buffer.from((value as string).slice(PREFIX.length), "base64");
    const decipher = crypto.createDecipheriv("aes-256-gcm", KEY, data.subarray(0, 12));
    decipher.setAuthTag(data.subarray(12, 28));
    return Buffer.concat([decipher.update(data.subarray(28)), decipher.final()]).toString(
      "utf8",
    ) as T;
  } catch {
    // Wrong key or tampered row — never crash the chat over one message.
    return "[Message could not be decrypted]" as T;
  }
}

interface MessageFields {
  text: string;
  replyToText?: string | null;
  attachmentName?: string | null;
}

/** Encrypts the sensitive fields of a message about to be written. */
export function encryptMessageFields<T extends Partial<MessageFields>>(data: T): T {
  return {
    ...data,
    ...(data.text !== undefined ? { text: encryptText(data.text) } : {}),
    ...(data.replyToText !== undefined ? { replyToText: encryptText(data.replyToText) } : {}),
    ...(data.attachmentName !== undefined
      ? { attachmentName: encryptText(data.attachmentName) }
      : {}),
  };
}

/** Decrypts a message row read from the database. */
export function decryptMessage<T extends MessageFields>(message: T): T {
  return {
    ...message,
    text: decryptText(message.text),
    replyToText: decryptText(message.replyToText ?? null),
    attachmentName: decryptText(message.attachmentName ?? null),
  };
}
