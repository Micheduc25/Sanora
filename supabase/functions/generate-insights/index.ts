import {
  callOpenAi,
  consumeAiAllowance,
  corsHeaders,
  handleError,
  json,
  openAiModel,
  outputText,
  requireUser,
} from "../_shared/mod.ts";

const insightsSchema = {
  type: "object",
  additionalProperties: false,
  required: ["insights"],
  properties: {
    insights: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["title", "body", "severity", "action"],
        properties: {
          title: { type: "string" },
          body: {
            type: "string",
            description: "2-3 sentences: the pattern, why it matters, one concrete next step",
          },
          severity: {
            type: "string",
            enum: ["celebrate", "info", "nudge", "warning"],
          },
          action: {
            type: "string",
            description: "Short call-to-action label, or empty string",
          },
        },
      },
    },
  },
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { userId, admin } = await requireUser(req);
    await consumeAiAllowance(admin, userId);
    const { context } = await req.json();

    const upstream = await callOpenAi({
      model: openAiModel(),
      instructions:
        `You analyze a user's week of health data and surface at most 4 genuinely useful patterns (weight trends vs meals, late eating, low protein, sodium, sleep, movement, weekend effects). Be specific with their numbers, kind in tone, and always give one doable next step. Celebrate real wins. Never shame.`,
      input: [{
        role: "user",
        content: [{
          type: "input_text",
          text: `Week of data (JSON): ${JSON.stringify(context)}`,
        }],
      }],
      text: {
        format: {
          type: "json_schema",
          name: "weekly_insights",
          strict: true,
          schema: insightsSchema,
        },
      },
    });

    const parsed = JSON.parse(outputText(await upstream.json()));
    return json(parsed);
  } catch (e) {
    return handleError(e);
  }
});
