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
 */
export async function consumeAiAllowance(
  admin: SupabaseClient,
  userId: string,
): Promise<void> {
  const { data: sub } = await admin
    .from("subscriptions")
    .select("tier, valid_until")
    .eq("user_id", userId)
    .maybeSingle();
  const premium = sub?.tier === "premium" &&
    (!sub.valid_until || new Date(sub.valid_until) > new Date());
  if (premium) return;

  const day = new Date().toISOString().slice(0, 10);
  const { data: usage } = await admin
    .from("ai_usage")
    .select("calls")
    .eq("user_id", userId)
    .eq("day", day)
    .maybeSingle();
  const calls = usage?.calls ?? 0;
  if (calls >= FREE_DAILY_AI_CALLS) {
    throw new HttpError(
      429,
      "Daily AI limit reached. Upgrade to Premium for unlimited coaching.",
    );
  }
  await admin
    .from("ai_usage")
    .upsert({ user_id: userId, day, calls: calls + 1 });
}

const OPENAI_URL = "https://api.openai.com/v1/responses";

export function openAiModel(): string {
  return Deno.env.get("OPENAI_MODEL") ?? "gpt-5-mini";
}

export async function callOpenAi(body: Record<string, unknown>): Promise<Response> {
  const key = Deno.env.get("OPENAI_API_KEY");
  if (!key) throw new HttpError(500, "AI is not configured on this project.");
  const response = await fetch(OPENAI_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    const detail = await response.text();
    console.error("openai error", response.status, detail);
    throw new HttpError(502, "The AI service is unavailable right now.");
  }
  return response;
}

/** Extracts the aggregated text output from a non-streaming Responses API reply. */
export function outputText(response: Record<string, unknown>): string {
  const output = response.output as Array<Record<string, unknown>> ?? [];
  for (const item of output) {
    if (item.type !== "message") continue;
    for (const part of (item.content as Array<Record<string, unknown>>) ?? []) {
      if (part.type === "output_text") return part.text as string;
    }
  }
  throw new HttpError(502, "The AI returned an empty response.");
}

export function handleError(e: unknown): Response {
  if (e instanceof HttpError) return json({ error: e.message }, e.status);
  console.error(e);
  return json({ error: "Unexpected server error." }, 500);
}
