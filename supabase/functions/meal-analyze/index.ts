import {
  callOpenAi,
  consumeAiAllowance,
  corsHeaders,
  handleError,
  HttpError,
  json,
  openAiModel,
  outputText,
  requireUser,
} from "../_shared/mod.ts";

interface AnalyzeRequest {
  image_base64?: string;
  description?: string;
  country?: string;
  allergies?: string[];
  preferences?: string[];
}

const nutritionSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "calories",
    "protein_g",
    "fat_g",
    "carbs_g",
    "fiber_g",
    "sugar_g",
    "sodium_mg",
    "micronutrients",
  ],
  properties: {
    calories: { type: "number" },
    protein_g: { type: "number" },
    fat_g: { type: "number" },
    carbs_g: { type: "number" },
    fiber_g: { type: "number" },
    sugar_g: { type: "number" },
    sodium_mg: { type: "number" },
    micronutrients: {
      type: "object",
      additionalProperties: false,
      required: ["iron_mg", "vitamin_a_ug", "potassium_mg"],
      properties: {
        iron_mg: { type: "number" },
        vitamin_a_ug: { type: "number" },
        potassium_mg: { type: "number" },
      },
    },
  },
};

const mealSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "name",
    "meal_type",
    "components",
    "confidence",
    "notes",
    "healthier_swaps",
  ],
  properties: {
    name: { type: "string", description: "Short dish name, e.g. 'Eru with water fufu'" },
    meal_type: { type: "string", enum: ["breakfast", "lunch", "dinner", "snack"] },
    components: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["name", "portion_g", "nutrition"],
        properties: {
          name: { type: "string" },
          portion_g: { type: "number", description: "Estimated portion in grams" },
          nutrition: nutritionSchema,
        },
      },
    },
    confidence: { type: "number", description: "0-1 recognition confidence" },
    notes: {
      type: "string",
      description: "One or two friendly sentences about the meal's balance",
    },
    healthier_swaps: {
      type: "array",
      items: { type: "string" },
      description: "Up to 3 culturally-appropriate improvement suggestions",
    },
  },
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    const { userId, admin } = await requireUser(req);
    await consumeAiAllowance(admin, userId);
    const body = (await req.json()) as AnalyzeRequest;
    if (!body.image_base64 && !body.description) {
      throw new HttpError(400, "Send a photo or a description of the meal.");
    }

    const instructions =
      `You are a nutritionist who knows African cuisine (Cameroonian, Nigerian, Ghanaian, East and Southern African) as well as international food.
Identify the meal, estimate realistic cooked portion sizes in grams, and estimate nutrition for the whole portion of each component (not per 100 g).
${body.country ? `The user is in ${body.country}; prefer local dish names.` : ""}
${body.allergies?.length ? `The user is allergic to: ${body.allergies.join(", ")}. Mention it in notes if the meal may contain any.` : ""}
${body.preferences?.length ? `Dietary preferences: ${body.preferences.join(", ")}.` : ""}
Swaps must respect the food culture — adjust portions or sides rather than replacing the dish.`;

    const userContent: Array<Record<string, unknown>> = [];
    if (body.description) {
      userContent.push({ type: "input_text", text: body.description });
    }
    if (body.image_base64) {
      userContent.push({
        type: "input_image",
        image_url: `data:image/jpeg;base64,${body.image_base64}`,
      });
    }

    const upstream = await callOpenAi({
      model: openAiModel(),
      instructions,
      input: [{ role: "user", content: userContent }],
      text: {
        format: {
          type: "json_schema",
          name: "meal_analysis",
          strict: true,
          schema: mealSchema,
        },
      },
    });

    const parsed = JSON.parse(outputText(await upstream.json()));
    return json({ id: crypto.randomUUID(), ...parsed });
  } catch (e) {
    return handleError(e);
  }
});
