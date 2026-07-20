import {
  callOpenAi,
  consumeAiAllowance,
  corsHeaders,
  handleError,
  openAiModel,
  requireUser,
} from "../_shared/mod.ts";

interface CoachRequest {
  messages: Array<{ role: string; content: string }>;
  profile: Record<string, unknown>;
  health: Record<string, unknown>;
  today: Record<string, unknown>;
}

function systemPrompt(body: CoachRequest): string {
  return `You are Bodi, a warm, evidence-based personal health coach.

Principles:
- Be concrete and personal: use the user's own numbers and meals, never generic advice.
- Habits over perfection. Celebrate progress, never shame.
- Respect the user's food culture (including African dishes like eru, ndolé, fufu, jollof); improve portions and pairings rather than banning foods.
- Keep answers short: 2-6 sentences unless the user asks for a plan.
- You are not a doctor. For symptoms, medication changes or red-flag signs, advise seeing a healthcare professional.
- Account for their medical conditions, medications and allergies in every suggestion.

User profile (JSON): ${JSON.stringify(body.profile)}
Computed health profile (JSON): ${JSON.stringify(body.health)}
Today so far (JSON): ${JSON.stringify(body.today)}`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { userId, admin } = await requireUser(req);
    await consumeAiAllowance(admin, userId);
    const body = (await req.json()) as CoachRequest;

    const upstream = await callOpenAi({
      model: openAiModel(),
      stream: true,
      input: [
        { role: "system", content: systemPrompt(body) },
        ...body.messages.slice(-20),
      ],
    });

    // Re-emit only text deltas as a compact SSE stream for the app.
    const encoder = new TextEncoder();
    const decoder = new TextDecoder();
    let buffer = "";
    const stream = new ReadableStream({
      async start(controller) {
        const reader = upstream.body!.getReader();
        try {
          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            buffer += decoder.decode(value, { stream: true });
            let split;
            while ((split = buffer.indexOf("\n\n")) !== -1) {
              const event = buffer.slice(0, split);
              buffer = buffer.slice(split + 2);
              for (const line of event.split("\n")) {
                if (!line.startsWith("data: ")) continue;
                const payload = line.slice(6).trim();
                if (payload === "[DONE]") continue;
                try {
                  const parsed = JSON.parse(payload);
                  if (
                    parsed.type === "response.output_text.delta" &&
                    typeof parsed.delta === "string"
                  ) {
                    controller.enqueue(encoder.encode(
                      `data: ${JSON.stringify({ delta: parsed.delta })}\n\n`,
                    ));
                  }
                } catch {
                  // ignore malformed keep-alive lines
                }
              }
            }
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
