import {
  callGemini,
  consumeAiAllowance,
  corsHeaders,
  geminiSchema,
  handleError,
  json,
  outputText,
  requireUser,
} from "../_shared/mod.ts";

interface WorkoutRequest {
  category: string;
  duration_minutes: number;
  profile: Record<string, unknown>;
  health: Record<string, unknown>;
}

const workoutSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "name",
    "difficulty",
    "duration_minutes",
    "estimated_calories",
    "exercises",
  ],
  properties: {
    name: { type: "string" },
    difficulty: { type: "string", enum: ["Beginner", "Intermediate", "Advanced"] },
    duration_minutes: { type: "integer" },
    estimated_calories: { type: "integer" },
    exercises: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "instructions", "sets", "reps_or_duration", "rest_seconds"],
        properties: {
          name: { type: "string" },
          instructions: {
            type: "string",
            description: "Clear form cues a beginner can follow without video",
          },
          sets: { type: "integer" },
          reps_or_duration: { type: "string" },
          rest_seconds: { type: "integer" },
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
    const body = (await req.json()) as WorkoutRequest;

    const upstream = await callGemini({
      systemInstruction: {
        parts: [{
          text:
            `You are a certified fitness coach. Design a safe, effective ${body.category} workout of about ${body.duration_minutes} minutes, personalized to the user's fitness level, goals, age and medical conditions. Favor progressions over impact for beginners; always include an implicit warm-up as the first exercise and a cool-down/stretch as the last. Estimate calories for the user's body weight.
User profile: ${JSON.stringify(body.profile)}
Health profile: ${JSON.stringify(body.health)}`,
        }],
      },
      contents: [{
        role: "user",
        parts: [{ text: "Generate today's workout." }],
      }],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: geminiSchema(workoutSchema),
      },
    });

    const parsed = JSON.parse(outputText(await upstream.json()));
    return json({
      id: crypto.randomUUID(),
      category: body.category,
      completed: false,
      created_at: new Date().toISOString(),
      ...parsed,
    });
  } catch (e) {
    return handleError(e);
  }
});
