/**
 * Server-side receipt verification for Sanora Premium.
 *
 * The app never decides that someone is premium — it hands over whatever the
 * store gave it, this function asks Apple or Google whether that is real, and
 * only then writes `subscriptions.tier = 'premium'`.
 *
 * ## Required secrets
 *
 * Set with `supabase secrets set NAME=value`. Every one of them is mandatory
 * for its platform: if a secret is missing this function answers 500 and the
 * caller stays on the free tier. It never falls back to trusting the client.
 *
 * Apple (App Store Server API — StoreKit 2, which is what `in_app_purchase`
 * uses by default; the receipt the app sends is a signed transaction JWS):
 *   APPLE_BUNDLE_ID     e.g. cm.sanora.app — must match the bundle Apple
 *                       reports for the transaction.
 *   APPLE_ISSUER_ID     App Store Connect → Users and Access → Integrations →
 *                       In-App Purchase → Issuer ID.
 *   APPLE_KEY_ID        The key id of the in-app purchase key you generated
 *                       there.
 *   APPLE_PRIVATE_KEY   The contents of that key's .p8 file, including the
 *                       BEGIN/END lines.
 *
 * Google (Play Developer API; the receipt the app sends is a purchase token):
 *   GOOGLE_PLAY_PACKAGE_NAME      e.g. cm.sanora.app
 *   GOOGLE_SERVICE_ACCOUNT_EMAIL  A service account granted "View financial
 *                                 data" on the app in Play Console, with the
 *                                 Android Publisher API enabled.
 *   GOOGLE_SERVICE_ACCOUNT_KEY    That account's PEM private key.
 *
 * ## What is trusted
 *
 * The store's own HTTPS response is the authority, not the payload the client
 * sent. Apple's JWS is decoded only to learn which transaction to ask about;
 * the entitlement comes from what Apple answers. A transaction id can
 * therefore only be claimed once — `subscription_receipts` has a unique key on
 * (platform, transaction_id) and a receipt already bound to another account is
 * refused rather than transferred.
 */

import {
  corsHeaders,
  handleError,
  HttpError,
  json,
  requireUser,
} from "../_shared/mod.ts";

/** Must match `PremiumProducts` in app/lib/features/premium/premium_products.dart. */
const PREMIUM_PRODUCT_IDS = ["sanora_premium_monthly", "sanora_premium_yearly"];

interface Entitlement {
  /** Stable across renewals, so a renewal updates the receipt row in place. */
  transactionId: string;
  expiresAt: Date;
}

function requireSecret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    console.error(`verify-purchase: missing secret ${name}`);
    throw new HttpError(
      500,
      "Purchases are not configured on this project yet, so this one could " +
        "not be confirmed. You have not been charged for anything Sanora can " +
        "unlock.",
    );
  }
  return value;
}

// ---------------------------------------------------------------- crypto ---

function base64UrlEncode(input: Uint8Array | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : input;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/,
    "",
  );
}

function base64UrlDecode(input: string): string {
  const padded = input.replace(/-/g, "+").replace(/_/g, "/").padEnd(
    Math.ceil(input.length / 4) * 4,
    "=",
  );
  return new TextDecoder().decode(
    Uint8Array.from(atob(padded), (c) => c.charCodeAt(0)),
  );
}

/** Strips the PEM armour and returns the DER bytes for `importKey`. */
function pemToDer(pem: string): ArrayBuffer {
  const body = pem
    .replace(/-----BEGIN [A-Z ]+-----/g, "")
    .replace(/-----END [A-Z ]+-----/g, "")
    .replace(/\s+/g, "");
  const raw = atob(body);
  const der = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) der[i] = raw.charCodeAt(i);
  return der.buffer;
}

async function signJwt(
  header: Record<string, unknown>,
  claims: Record<string, unknown>,
  pem: string,
  algorithm: "ES256" | "RS256",
): Promise<string> {
  const params = algorithm === "ES256"
    ? { name: "ECDSA", namedCurve: "P-256" }
    : { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" };
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(pem),
    params,
    false,
    ["sign"],
  );
  const body = `${base64UrlEncode(JSON.stringify(header))}.${
    base64UrlEncode(JSON.stringify(claims))
  }`;
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      algorithm === "ES256"
        ? { name: "ECDSA", hash: "SHA-256" }
        : { name: "RSASSA-PKCS1-v1_5" },
      key,
      new TextEncoder().encode(body),
    ),
  );
  return `${body}.${base64UrlEncode(signature)}`;
}

/**
 * Reads a JWS payload without checking its signature.
 *
 * Only ever used on data that is about to be re-fetched from the store over
 * TLS: nothing read here is trusted on its own.
 */
function decodeJwsPayload(jws: string): Record<string, unknown> {
  const parts = jws.split(".");
  if (parts.length !== 3) {
    throw new HttpError(400, "That receipt is not in a format Sanora can read.");
  }
  try {
    return JSON.parse(base64UrlDecode(parts[1]));
  } catch {
    throw new HttpError(400, "That receipt is not in a format Sanora can read.");
  }
}

// ----------------------------------------------------------------- apple ---

const APPLE_PRODUCTION = "https://api.storekit.itunes.apple.com";
const APPLE_SANDBOX = "https://api.storekit-sandbox.itunes.apple.com";

/** Apple's `status` for a subscription: 1 active, 4 in a billing grace period. */
const APPLE_ENTITLED_STATUSES = [1, 4];

async function appleBearerToken(): Promise<string> {
  const issuerId = requireSecret("APPLE_ISSUER_ID");
  const keyId = requireSecret("APPLE_KEY_ID");
  const privateKey = requireSecret("APPLE_PRIVATE_KEY");
  const bundleId = requireSecret("APPLE_BUNDLE_ID");
  const now = Math.floor(Date.now() / 1000);
  return await signJwt(
    { alg: "ES256", kid: keyId, typ: "JWT" },
    {
      iss: issuerId,
      iat: now,
      exp: now + 900,
      aud: "appstoreconnect-v1",
      bid: bundleId,
    },
    privateKey,
    "ES256",
  );
}

/**
 * Sandbox and production are separate databases with the same API. A
 * TestFlight or Xcode purchase only exists in sandbox, so a production miss is
 * retried there rather than being reported to the user as a fake receipt.
 */
async function appleSubscriptionStatuses(
  originalTransactionId: string,
  token: string,
): Promise<Record<string, unknown>> {
  for (const host of [APPLE_PRODUCTION, APPLE_SANDBOX]) {
    const response = await fetch(
      `${host}/inApps/v1/subscriptions/${
        encodeURIComponent(originalTransactionId)
      }`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (response.ok) return await response.json();
    const detail = await response.text();
    if (response.status === 404 && host === APPLE_PRODUCTION) continue;
    if (response.status === 404) {
      throw new HttpError(402, "The App Store does not know that purchase.");
    }
    console.error("apple status error", response.status, detail);
    throw new HttpError(502, "The App Store is unavailable right now.");
  }
  throw new HttpError(402, "The App Store does not know that purchase.");
}

async function verifyApple(
  receipt: string,
  productId: string,
): Promise<Entitlement> {
  const bundleId = requireSecret("APPLE_BUNDLE_ID");
  const claimed = decodeJwsPayload(receipt);
  const originalTransactionId = claimed.originalTransactionId;
  if (typeof originalTransactionId !== "string" || !originalTransactionId) {
    throw new HttpError(400, "That receipt has no transaction in it.");
  }

  const body = await appleSubscriptionStatuses(
    originalTransactionId,
    await appleBearerToken(),
  );

  if (body.bundleId !== bundleId) {
    console.error("apple bundle mismatch", body.bundleId);
    throw new HttpError(402, "That purchase was not made in the Sanora app.");
  }

  const groups = (body.data ?? []) as Array<
    { lastTransactions?: Array<Record<string, unknown>> }
  >;
  let best: Entitlement | null = null;
  for (const group of groups) {
    for (const transaction of group.lastTransactions ?? []) {
      if (!APPLE_ENTITLED_STATUSES.includes(Number(transaction.status))) {
        continue;
      }
      const signed = transaction.signedTransactionInfo;
      if (typeof signed !== "string") continue;
      const info = decodeJwsPayload(signed);
      if (info.productId !== productId) continue;
      const expiresAt = new Date(Number(info.expiresDate));
      if (Number.isNaN(expiresAt.getTime())) continue;
      const id = String(
        transaction.originalTransactionId ?? originalTransactionId,
      );
      if (!best || expiresAt > best.expiresAt) {
        best = { transactionId: id, expiresAt };
      }
    }
  }

  if (!best) {
    throw new HttpError(
      402,
      "There is no active Sanora Premium subscription on that App Store account.",
    );
  }
  return best;
}

// ---------------------------------------------------------------- google ---

async function googleAccessToken(): Promise<string> {
  const email = requireSecret("GOOGLE_SERVICE_ACCOUNT_EMAIL");
  const privateKey = requireSecret("GOOGLE_SERVICE_ACCOUNT_KEY");
  const now = Math.floor(Date.now() / 1000);
  const assertion = await signJwt(
    { alg: "RS256", typ: "JWT" },
    {
      iss: email,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    },
    privateKey,
    "RS256",
  );

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) {
    console.error("google token error", response.status, await response.text());
    throw new HttpError(502, "Google Play is unavailable right now.");
  }
  const body = await response.json();
  const token = body.access_token;
  if (typeof token !== "string") {
    throw new HttpError(502, "Google Play is unavailable right now.");
  }
  return token;
}

async function verifyGoogle(
  purchaseToken: string,
  productId: string,
): Promise<Entitlement> {
  const packageName = requireSecret("GOOGLE_PLAY_PACKAGE_NAME");
  const accessToken = await googleAccessToken();

  const response = await fetch(
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
      encodeURIComponent(packageName)
    }/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`,
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
  if (response.status === 400 || response.status === 404) {
    throw new HttpError(402, "Google Play does not know that purchase.");
  }
  if (!response.ok) {
    console.error(
      "google purchase error",
      response.status,
      await response.text(),
    );
    throw new HttpError(502, "Google Play is unavailable right now.");
  }

  const body = await response.json();
  const state = body.subscriptionState;
  if (
    state !== "SUBSCRIPTION_STATE_ACTIVE" &&
    state !== "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"
  ) {
    throw new HttpError(402, "That Google Play subscription is not active.");
  }

  const items = (body.lineItems ?? []) as Array<
    { productId?: string; expiryTime?: string }
  >;
  let expiresAt: Date | null = null;
  for (const item of items) {
    if (item.productId !== productId || !item.expiryTime) continue;
    const at = new Date(item.expiryTime);
    if (Number.isNaN(at.getTime())) continue;
    if (!expiresAt || at > expiresAt) expiresAt = at;
  }
  if (!expiresAt) {
    throw new HttpError(
      402,
      "That purchase is not a Sanora Premium subscription.",
    );
  }

  // The purchase token is what Play keeps stable across renewals of the same
  // subscription, so it is the identity of this entitlement.
  return { transactionId: purchaseToken, expiresAt };
}

// ------------------------------------------------------------------ http ---

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  try {
    const { userId, admin } = await requireUser(req);
    const payload = await req.json();
    const platform = payload.platform;
    const productId = payload.product_id;
    const receipt = payload.receipt;

    if (platform !== "ios" && platform !== "android") {
      throw new HttpError(400, "Unknown store.");
    }
    if (typeof receipt !== "string" || receipt.length === 0) {
      throw new HttpError(400, "Missing purchase receipt.");
    }
    if (
      typeof productId !== "string" || !PREMIUM_PRODUCT_IDS.includes(productId)
    ) {
      throw new HttpError(400, "That product is not Sanora Premium.");
    }

    const entitlement = platform === "ios"
      ? await verifyApple(receipt, productId)
      : await verifyGoogle(receipt, productId);

    if (entitlement.expiresAt.getTime() <= Date.now()) {
      throw new HttpError(402, "That subscription has already expired.");
    }

    // One store transaction belongs to one account. Without this an exported
    // receipt would upgrade every account it was pasted into.
    const { data: existing, error: lookupError } = await admin
      .from("subscription_receipts")
      .select("user_id")
      .eq("platform", platform)
      .eq("transaction_id", entitlement.transactionId)
      .maybeSingle();
    if (lookupError) {
      console.error("receipt lookup failed", lookupError);
      throw new HttpError(500, "Could not record that purchase.");
    }
    if (existing && existing.user_id !== userId) {
      throw new HttpError(
        409,
        "That purchase is already linked to another Sanora account.",
      );
    }

    const validUntil = entitlement.expiresAt.toISOString();

    const { error: receiptError } = await admin
      .from("subscription_receipts")
      .upsert({
        user_id: userId,
        platform,
        product_id: productId,
        transaction_id: entitlement.transactionId,
        expires_at: validUntil,
        verified_at: new Date().toISOString(),
      }, { onConflict: "platform,transaction_id" });
    if (receiptError) {
      console.error("receipt upsert failed", receiptError);
      throw new HttpError(500, "Could not record that purchase.");
    }

    // Only now, with a verified receipt on file, does the account become
    // premium. `consume_ai_call` reads exactly these two columns.
    const { error: subscriptionError } = await admin
      .from("subscriptions")
      .upsert({
        user_id: userId,
        tier: "premium",
        valid_until: validUntil,
      }, { onConflict: "user_id" });
    if (subscriptionError) {
      console.error("subscription upsert failed", subscriptionError);
      throw new HttpError(500, "Could not activate Premium on your account.");
    }

    return json({ tier: "premium", valid_until: validUntil });
  } catch (e) {
    return handleError(e);
  }
});
