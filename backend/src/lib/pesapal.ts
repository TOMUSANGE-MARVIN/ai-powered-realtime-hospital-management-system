// Pesapal API 3.0 client (https://developer.pesapal.com).
//
// Flow: RequestToken → SubmitOrderRequest (returns a hosted checkout URL the
// app opens in a WebView) → Pesapal calls our IPN / callback URL → we call
// GetTransactionStatus, since neither the callback nor the IPN carries the
// payment status itself.

const BASE_URLS = {
  sandbox: "https://cybqa.pesapal.com/pesapalv3",
  live: "https://pay.pesapal.com/v3",
} as const;

const env = process.env.PESAPAL_ENV === "live" ? "live" : "sandbox";
// PESAPAL_BASE_URL is for local tests against a mock server only.
const baseUrl = process.env.PESAPAL_BASE_URL || BASE_URLS[env];

/** Public URL of this backend — Pesapal must be able to reach the IPN/callback. */
export const publicApiUrl = () =>
  (process.env.PUBLIC_API_URL || process.env.BETTER_AUTH_URL || "").replace(/\/$/, "");

export const pesapalCallbackUrl = () => `${publicApiUrl()}/api/payments/pesapal/callback`;
const ipnUrl = () => `${publicApiUrl()}/api/payments/pesapal/ipn`;

export const isPesapalConfigured = () =>
  !!(process.env.PESAPAL_CONSUMER_KEY && process.env.PESAPAL_CONSUMER_SECRET && publicApiUrl());

export class PesapalError extends Error {}

async function call<T>(path: string, init: RequestInit & { token?: string } = {}): Promise<T> {
  const { token, ...rest } = init;
  const response = await fetch(`${baseUrl}${path}`, {
    ...rest,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });
  const body: any = await response.json().catch(() => null);
  // Pesapal reports most failures as HTTP 200 with a populated `error` object.
  if (!response.ok || !body || (body.error && (body.error.code || body.error.message))) {
    const message = body?.error?.message || body?.message || `HTTP ${response.status}`;
    throw new PesapalError(`Pesapal ${path} failed: ${message}`);
  }
  return body as T;
}

// Tokens live for 5 minutes; refresh a little early.
let cachedToken: { value: string; expiresAt: number } | null = null;

async function getToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now()) return cachedToken.value;
  const body = await call<{ token: string; expiryDate: string }>("/api/Auth/RequestToken", {
    method: "POST",
    body: JSON.stringify({
      consumer_key: process.env.PESAPAL_CONSUMER_KEY,
      consumer_secret: process.env.PESAPAL_CONSUMER_SECRET,
    }),
  });
  const expiry = Date.parse(body.expiryDate);
  cachedToken = {
    value: body.token,
    expiresAt: (Number.isNaN(expiry) ? Date.now() + 5 * 60_000 : expiry) - 30_000,
  };
  return body.token;
}

// The IPN id is mandatory on every order. Prefer a pre-registered one from
// env; otherwise register our IPN URL once per process and reuse the id.
let cachedIpnId: string | null = process.env.PESAPAL_IPN_ID || null;

async function getIpnId(token: string): Promise<string> {
  if (cachedIpnId) return cachedIpnId;
  const body = await call<{ ipn_id: string }>("/api/URLSetup/RegisterIPN", {
    method: "POST",
    token,
    body: JSON.stringify({ url: ipnUrl(), ipn_notification_type: "GET" }),
  });
  cachedIpnId = body.ipn_id;
  return body.ipn_id;
}

export interface SubmitOrderInput {
  merchantReference: string;
  amount: number;
  currency: string;
  description: string;
  email?: string | null;
  phone?: string | null;
  firstName?: string;
  lastName?: string;
}

export async function submitOrder(input: SubmitOrderInput) {
  const token = await getToken();
  const notificationId = await getIpnId(token);
  return call<{ order_tracking_id: string; merchant_reference: string; redirect_url: string }>(
    "/api/Transactions/SubmitOrderRequest",
    {
      method: "POST",
      token,
      body: JSON.stringify({
        id: input.merchantReference,
        currency: input.currency,
        amount: input.amount,
        description: input.description.slice(0, 100),
        callback_url: pesapalCallbackUrl(),
        notification_id: notificationId,
        billing_address: {
          email_address: input.email || undefined,
          phone_number: input.phone || undefined,
          country_code: "UG",
          first_name: input.firstName,
          last_name: input.lastName,
        },
      }),
    },
  );
}

export interface TransactionStatus {
  status_code: number; // 0 INVALID, 1 COMPLETED, 2 FAILED, 3 REVERSED
  payment_status_description: string;
  payment_method: string | null;
  confirmation_code: string | null;
  amount: number;
  currency: string;
  merchant_reference: string;
}

export async function getTransactionStatus(orderTrackingId: string) {
  const token = await getToken();
  return call<TransactionStatus>(
    `/api/Transactions/GetTransactionStatus?orderTrackingId=${encodeURIComponent(orderTrackingId)}`,
    { method: "GET", token },
  );
}

export interface RefundInput {
  /** The payment's confirmation code from GetTransactionStatus. */
  confirmationCode: string;
  amount: number;
  /** Who asked for the refund (shown to the merchant approving it). */
  username: string;
  remarks: string;
}

/**
 * Asks Pesapal to refund a COMPLETED payment. Pesapal allows one refund per
 * payment, full-only for mobile money; the merchant approves it on Pesapal,
 * after which GetTransactionStatus reports the payment REVERSED.
 */
export async function requestRefund(input: RefundInput) {
  const token = await getToken();
  const body = await call<{ status: string | number; message?: string }>(
    "/api/Transactions/RefundRequest",
    {
      method: "POST",
      token,
      body: JSON.stringify({
        confirmation_code: input.confirmationCode,
        amount: input.amount,
        username: input.username,
        remarks: input.remarks.slice(0, 200),
      }),
    },
  );
  if (String(body.status) !== "200") {
    throw new PesapalError(`Pesapal rejected the refund: ${body.message || body.status}`);
  }
  return body;
}
