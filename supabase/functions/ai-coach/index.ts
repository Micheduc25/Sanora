import {
  callGemini,
  consumeAiAllowance,
  corsHeaders,
  handleError,
  HttpError,
  requireUser,
  SseDecoder,
  streamedText,
  streamStop,
  withoutIdentifiers,
} from "../_shared/mod.ts";

interface CoachRequest {
  messages: Array<{ role: string; content: string }>;
  profile: Record<string, unknown>;
  health: Record<string, unknown>;
  today: Record<string, unknown>;
}

function systemPrompt(body: CoachRequest): string {
  return `You are Sanora, a warm, evidence-based personal health coach.

Principles:
- Be concrete and personal: use the user's own numbers and meals, never generic advice.
- Habits over perfection. Celebrate progress, never shame.
- Respect the user's food culture (including African dishes like eru, ndolé, fufu, jollof); improve portions and pairings rather than banning foods.
- Keep answers short: 2-6 sentences unless the user asks for a plan.
- You are not a doctor. For symptoms, medication changes or red-flag signs, advise seeing a healthcare professional.
- Account for their medical conditions, medications and allergies in every suggestion.

User profile (JSON): ${JSON.stringify(withoutIdentifiers(body.profile))}
Computed health profile (JSON): ${JSON.stringify(body.health)}
Today so far (JSON): ${JSON.stringify(body.today)}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { userId, admin } = await requireUser(req);
    await consumeAiAllowance(admin, userId);
    const body = (await req.json()) as CoachRequest;

    // An empty turn reaches the model as `parts: [{text: ""}]`, which it can
    // answer with an empty candidate — one blank reply would then keep every
    // later reply blank. Older clients still send them, so drop them here as
    // well as in the app. A conversation must also open on the user's turn.
    const turns = body.messages
      .filter((m) => m.content?.trim())
      .slice(-20);
    while (turns.length && turns[0].role === "assistant") turns.shift();
    if (turns.length === 0) throw new HttpError(400, "Nothing to answer.");

    const upstream = await callGemini({
      systemInstruction: { parts: [{ text: systemPrompt(body) }] },
      // Gemini names the assistant turn "model", and takes the system prompt
      // out of band rather than as the first message.
      contents: turns.map((m) => ({
        role: m.role === "assistant" ? "model" : "user",
        parts: [{ text: m.content }],
      })),
    }, { stream: true });

    // Re-emit only text deltas as a compact SSE stream for the app.
    const encoder = new TextEncoder();
    const decoder = new TextDecoder();
    const sse = new SseDecoder();
    let emitted = 0;
    let stop: string | undefined;
    const stream = new ReadableStream({
      async start(controller) {
        const reader = upstream.body!.getReader();
        const emit = (payloads: string[]) => {
          for (const payload of payloads) {
            stop = streamStop(payload) ?? stop;
            const delta = streamedText(payload);
            if (!delta) continue;
            emitted++;
            controller.enqueue(
              encoder.encode(`data: ${JSON.stringify({ delta })}\n\n`),
            );
          }
        };

        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            emit(sse.push(decoder.decode(value, { stream: true })));
          }
          emit(sse.push(decoder.decode()));
          emit(sse.flush());
          // Reporting success with nothing to show leaves an empty bubble the
          // user cannot act on — say the answer was lost instead.
          if (emitted === 0) {
            console.error("gemini stream produced no text", { stop });
            controller.enqueue(encoder.encode(
              `data: ${
                JSON.stringify({
                  error: stop === "SAFETY" || stop === "PROHIBITED_CONTENT"
                    ? "The AI could not answer that one. Try rewording it."
                    : stop === "MAX_TOKENS"
                    ? "That answer got too long. Try a narrower question."
                    : `The AI returned an empty response${
                      stop ? ` (${stop})` : ""
                    }. Please try again.`,
                })
              }\n\n`,
            ));
          }
          controller.enqueue(encoder.encode("data: [DONE]\n\n"));
        } finally {
          controller.close();
          reader.releaseLock();
        }
      },
    });

    return new Response(stream, {
      headers: {
        ...corsHeaders,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
      },
    });
  } catch (e) {
    return handleError(e);
  }
});
