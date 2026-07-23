import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

/** Resolves the calling user from their JWT; throws 401 otherwise. */
export async function requireUser(
  req: Request,
): Promise<{ userId: string; admin: SupabaseClient }> {
  const authHeader = req.headers.get("Authorization") ?? "";
  const anonClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data, error } = await anonClient.auth.getUser();
  if (error || !data.user) throw new HttpError(401, "Not signed in.");
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  return { userId: data.user.id, admin };
}

const FREE_DAILY_AI_CALLS = 20;

/**
 * Meters AI usage: premium subscribers are unlimited, free tier gets a
 * daily allowance. Throws 429 when exhausted.
 *
 * The check and the increment happen in one statement inside
 * `consume_ai_call` — doing them as separate reads and writes here let two
 * concurrent requests both observe the same count and both be admitted.
 */
export async function consumeAiAllowance(
  admin: SupabaseClient,
  userId: string,
): Promise<void> {
  const { data: allowed, error } = await admin.rpc("consume_ai_call", {
    p_user_id: userId,
    p_limit: FREE_DAILY_AI_CALLS,
  });
  if (error) {
    console.error("metering failed", error);
    throw new HttpError(500, "Could not check your AI allowance.");
  }
  if (allowed !== true) {
    throw new HttpError(
      429,
      "Daily AI limit reached. Upgrade to Premium for unlimited coaching.",
    );
  }
}

/**
 * Direct identifiers stripped from a profile before it reaches Gemini.
 *
 * The coach is personal because it knows your numbers, not because it knows
 * your name, and the privacy policy promises Google is never told who you are.
 * The app sends the whole profile — filtering here rather than there means an
 * older client cannot opt out of it.
 */
const IDENTIFIER_KEYS = new Set(["name", "email", "phone", "user_id", "id"]);

export function withoutIdentifiers(
  profile: Record<string, unknown> | undefined | null,
): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(profile ?? {}).filter(([key]) => !IDENTIFIER_KEYS.has(key)),
  );
}

const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/models";

export function geminiModel(): string {
  return Deno.env.get("GEMINI_MODEL") ?? "gemini-3.5-flash";
}

export function geminiFallbackModel(): string {
  return Deno.env.get("GEMINI_FALLBACK_MODEL") ?? "gemini-3.5-flash-lite";
}

/** Overload and rate limits are transient; anything else is our bug. */
const RETRYABLE_STATUSES = new Set([429, 500, 503]);
const BACKOFF_MS = [500, 1000];

/**
 * Calls the Gemini generateContent API. Set `stream` for the coach, which uses
 * `streamGenerateContent?alt=sse` and yields partial candidates.
 *
 * When a model is overloaded Google sheds free-tier keys first (503
 * UNAVAILABLE), so a failed call is retried with backoff and then tried once
 * on the fallback model, whose capacity pool is separate from the primary's.
 *
 * The key travels as a header rather than the `?key=` query parameter Google
 * also accepts, so it cannot end up in a proxy or access log.
 */
export async function callGemini(
  body: Record<string, unknown>,
  { stream = false, fetcher = fetch }: {
    stream?: boolean;
    fetcher?: typeof fetch;
  } = {},
): Promise<Response> {
  const key = Deno.env.get("GEMINI_API_KEY");
  if (!key) throw new HttpError(500, "AI is not configured on this project.");
  const method = stream ? "streamGenerateContent?alt=sse" : "generateContent";
  const models = [geminiModel(), geminiModel(), geminiFallbackModel()];
  for (const [attempt, model] of models.entries()) {
    if (attempt > 0) {
      await new Promise((r) => setTimeout(r, BACKOFF_MS[attempt - 1]));
    }
    const response = await fetcher(`${GEMINI_BASE}/${model}:${method}`, {
      method: "POST",
      headers: {
        "x-goog-api-key": key,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (response.ok) return response;
    const detail = await response.text();
    console.error("gemini error", response.status, model, detail);
    if (!RETRYABLE_STATUSES.has(response.status)) break;
  }
  throw new HttpError(502, "The AI service is unavailable right now.");
}

/**
 * Gemini's `responseSchema` takes an OpenAPI subset that rejects
 * `additionalProperties` outright, so the schema literals — which are written
 * the way JSON Schema wants — are sanitised on the way out rather than being
 * duplicated in two dialects.
 */
export function geminiSchema(schema: unknown): unknown {
  if (Array.isArray(schema)) return schema.map(geminiSchema);
  if (schema === null || typeof schema !== "object") return schema;
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(schema as Record<string, unknown>)) {
    if (k === "additionalProperties" || k === "strict") continue;
    out[k] = geminiSchema(v);
  }
  return out;
}

/**
 * Incremental SSE reader for Gemini's `alt=sse` stream.
 *
 * The SSE grammar terminates lines with CRLF, LF *or* CR, and Google sends
 * CRLF — a reader that splits on "\n\n" alone matches nothing, holds every
 * event in its buffer and hands the caller a stream that ends having said
 * nothing. Kept as a class so the framing has one implementation and one test
 * rather than a copy per function.
 */
export class SseDecoder {
  private buffer = "";
  private static readonly separator = /\r\n\r\n|\n\n|\r\r/;

  /** Whole `data:` payloads available so far. */
  push(chunk: string): string[] {
    this.buffer += chunk;
    const payloads: string[] = [];
    while (true) {
      const match = SseDecoder.separator.exec(this.buffer);
      if (!match) break;
      const event = this.buffer.slice(0, match.index);
      this.buffer = this.buffer.slice(match.index + match[0].length);
      payloads.push(...SseDecoder.payloadsIn(event));
    }
    return payloads;
  }

  /** Whatever is left when the upstream ends without a final blank line. */
  flush(): string[] {
    const rest = this.buffer;
    this.buffer = "";
    return rest.trim() ? SseDecoder.payloadsIn(rest) : [];
  }

  private static payloadsIn(event: string): string[] {
    const out: string[] = [];
    for (const line of event.split(/\r\n|\n|\r/)) {
      if (!line.startsWith("data:")) continue;
      const payload = line.slice(5).trim();
      if (payload) out.push(payload);
    }
    return out;
  }
}

/**
 * The answer text in one streamed `GenerateContentResponse`.
 *
 * Thinking models stream their reasoning as parts flagged `thought`; that is
 * not the answer and must never reach the user.
 */
export function streamedText(payload: string): string {
  try {
    const parsed = JSON.parse(payload);
    const parts = parsed?.candidates?.[0]?.content?.parts as
      | Array<{ text?: string; thought?: boolean }>
      | undefined;
    return (parts ?? [])
      .filter((p) => !p.thought)
      .map((p) => p.text)
      .filter((t): t is string => typeof t === "string")
      .join("");
  } catch {
    return ""; // keep-alive or a partial line
  }
}

/**
 * Why a streamed response carried no text, when it carried none.
 *
 * A prompt blocked by a safety filter, or a candidate cut short by the token
 * limit, still arrives as a 200 with a well-formed stream — the reason is
 * inside the payload. Without it "empty response" is unactionable.
 */
export function streamStop(payload: string): string | undefined {
  try {
    const parsed = JSON.parse(payload);
    return parsed?.promptFeedback?.blockReason ??
      parsed?.candidates?.[0]?.finishReason ?? undefined;
  } catch {
    return undefined;
  }
}

/** Joins the text parts of the first candidate in a generateContent reply. */
export function outputText(response: Record<string, unknown>): string {
  const candidates = (response.candidates as Array<Record<string, unknown>>) ??
    [];
  const content = candidates[0]?.content as Record<string, unknown> | undefined;
  const parts = (content?.parts as Array<Record<string, unknown>>) ?? [];
  const text = parts
    .map((p) => p.text)
    .filter((t): t is string => typeof t === "string")
    .join("");
  if (text) return text;

  // An empty candidate list usually means a safety filter fired; say so rather
  // than reporting a generic outage the user cannot act on.
  const feedback = response.promptFeedback as Record<string, unknown> | undefined;
  if (feedback?.blockReason) {
    console.error("gemini blocked", feedback);
    throw new HttpError(
      422,
      "The AI could not answer that one. Try rewording it.",
    );
  }
  throw new HttpError(502, "The AI returned an empty response.");
}

export function handleError(e: unknown): Response {
  if (e instanceof HttpError) return json({ error: e.message }, e.status);
  console.error(e);
  return json({ error: "Unexpected server error." }, 500);
}
