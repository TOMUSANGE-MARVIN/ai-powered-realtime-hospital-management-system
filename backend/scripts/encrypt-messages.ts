// One-off: encrypt chat messages stored before MESSAGE_ENCRYPTION_KEY was set
// (E23.5). Safe to run more than once — already-encrypted rows are skipped.
//
//   bun scripts/encrypt-messages.ts            # encrypt
//   bun scripts/encrypt-messages.ts --dry-run  # only count
//
// In production run it inside the backend container, which has the key:
//   docker exec <backend-container> bun scripts/encrypt-messages.ts
import { prisma } from "../src/lib/prisma";
import {
  encryptMessageFields,
  isEncrypted,
  messageEncryptionEnabled,
} from "../src/lib/messageCrypto";

const dryRun = process.argv.includes("--dry-run");

if (!messageEncryptionEnabled) {
  console.error("MESSAGE_ENCRYPTION_KEY is not set — nothing to encrypt with.");
  process.exit(1);
}

const rows = await prisma.message.findMany({
  select: { id: true, text: true, replyToText: true, attachmentName: true },
});
const pending = rows.filter(
  (m) =>
    (m.text && !isEncrypted(m.text)) ||
    (m.replyToText && !isEncrypted(m.replyToText)) ||
    (m.attachmentName && !isEncrypted(m.attachmentName)),
);
console.log(`${rows.length} messages, ${pending.length} still in plain text.`);

if (!dryRun) {
  for (const m of pending) {
    await prisma.message.update({
      where: { id: m.id },
      data: encryptMessageFields({
        text: m.text,
        replyToText: m.replyToText,
        attachmentName: m.attachmentName,
      }),
    });
  }
  console.log(`Encrypted ${pending.length} messages.`);
}
await prisma.$disconnect();
