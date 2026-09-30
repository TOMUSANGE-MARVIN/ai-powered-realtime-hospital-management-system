import { prisma } from "./prisma";
import {
  DEFAULT_LEGAL_VERSION,
  DEFAULT_PRIVACY,
  DEFAULT_TELEMEDICINE_CONSENT,
  DEFAULT_TERMS,
} from "./legalDefaults";

// Versioned legal documents (E23.2), stored in the `setting` table under one
// key. Terms and Privacy Policy share a version: publishing a new version
// asks every user to accept again; saving without publishing just fixes text.

const SETTING_KEY = "legal";

export interface LegalDocuments {
  version: string;
  updatedAt: string;
  terms: string;
  privacy: string;
  telemedicineConsent: string;
}

export async function getLegalDocuments(): Promise<LegalDocuments> {
  const row = await prisma.setting.findUnique({ where: { key: SETTING_KEY } });
  const data = (row?.data ?? {}) as Partial<LegalDocuments>;
  return {
    version: data.version || DEFAULT_LEGAL_VERSION,
    updatedAt: data.updatedAt || new Date(`${DEFAULT_LEGAL_VERSION}T00:00:00Z`).toISOString(),
    terms: data.terms || DEFAULT_TERMS,
    privacy: data.privacy || DEFAULT_PRIVACY,
    telemedicineConsent: data.telemedicineConsent || DEFAULT_TELEMEDICINE_CONSENT,
  };
}

export async function saveLegalDocuments(
  changes: Partial<Pick<LegalDocuments, "terms" | "privacy" | "telemedicineConsent">>,
  publishNewVersion: boolean,
) {
  const current = await getLegalDocuments();
  const now = new Date();
  const next: LegalDocuments = {
    ...current,
    ...changes,
    updatedAt: now.toISOString(),
    // Date-stamped, with a time suffix so two versions on one day differ.
    version: publishNewVersion
      ? now.toISOString().slice(0, 16).replace("T", "-").replace(":", "")
      : current.version,
  };
  await prisma.setting.upsert({
    where: { key: SETTING_KEY },
    create: { key: SETTING_KEY, data: next as any },
    update: { data: next as any },
  });
  return next;
}

/** True when [userId] has accepted the current Terms and Privacy Policy. */
export async function hasAcceptedCurrentLegal(userId: string) {
  const [docs, user] = await Promise.all([
    getLegalDocuments(),
    prisma.user.findUnique({ where: { id: userId }, select: { legalAcceptedVersion: true } }),
  ]);
  return user?.legalAcceptedVersion === docs.version;
}

/**
 * Records the patient's telemedicine consent for one booking. Call only after
 * checking the request carried `telemedicineConsent: true`.
 */
export async function recordTelemedicineConsent(input: {
  userId: string;
  doctorId: string;
  paymentId?: string | null;
  appointmentId?: string | null;
}) {
  const { version } = await getLegalDocuments();
  await prisma.consent.create({
    data: {
      userId: input.userId,
      type: "telemedicine",
      version,
      doctorId: input.doctorId,
      paymentId: input.paymentId ?? null,
      appointmentId: input.appointmentId ?? null,
    },
  });
}

/** The 428 response a booking gets when a consent step is missing. */
export const CONSENT_ERRORS = {
  legal: {
    code: "legal_acceptance_required",
    message:
      "Please accept the latest Terms and Privacy Policy first. Update the app if you don't see them.",
  },
  telemedicine: {
    code: "telemedicine_consent_required",
    message: "Please confirm you consent to this consultation before booking.",
  },
} as const;
