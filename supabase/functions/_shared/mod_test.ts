import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import {
  callGemini,
  HttpError,
  SseDecoder,
  streamedText,
  streamStop,
} from "./mod.ts";

const chunk = (text: string) =>
  JSON.stringify({ candidates: [{ content: { parts: [{ text }] } }] });

Deno.test("reads CRLF-terminated events — the framing Google actually sends", () => {
  const sse = new SseDecoder();
  const payloads = sse.push(
    `data: ${chunk("Yes")}\r\n\r\ndata: ${chunk(", salad is fine.")}\r\n\r\n`,
  );
  assertEquals(payloads.map(streamedText), ["Yes", ", salad is fine."]);
});

Deno.test("reads LF-terminated events", () => {
  const sse = new SseDecoder();
  assertEquals(
    sse.push(`data: ${chunk("Hi")}\n\n`).map(streamedText),
    ["Hi"],
  );
});

Deno.test("holds a partial event until the rest of it arrives", () => {
  const sse = new SseDecoder();
  const body = `data: ${chunk("split")}\r\n\r\n`;
  assertEquals(sse.push(body.slice(0, 20)), []);
  assertEquals(sse.push(body.slice(20)).map(streamedText), ["split"]);
});

Deno.test("flush recovers a stream that ends without its blank line", () => {
  const sse = new SseDecoder();
  assertEquals(sse.push(`data: ${chunk("last")}`), []);
  assertEquals(sse.flush().map(streamedText), ["last"]);
});

Deno.test("skips keep-alives and comments rather than throwing", () => {
  const sse = new SseDecoder();
  const payloads = sse.push(`: keep-alive\r\n\r\ndata: not-json\r\n\r\n`);
  assertEquals(payloads.map(streamedText), [""]);
});

Deno.test("never leaks a thinking model's reasoning as the answer", () => {
  const payload = JSON.stringify({
    candidates: [{
      content: {
        parts: [
          { text: "the user asked about salad...", thought: true },
          { text: "Salad in the morning is great." },
        ],
      },
    }],
  });
  assertEquals(streamedText(payload), "Salad in the morning is great.");
});

const stubFetch = (
  responses: Array<{ status: number }>,
  calls: string[],
): typeof fetch =>
(input) => {
  calls.push(String(input));
  const { status } = responses[calls.length - 1];
  return Promise.resolve(
    new Response(status === 200 ? "{}" : `{"error":{"code":${status}}}`, {
      status,
    }),
  );
};

Deno.test("retries an overloaded model, then falls back to the lite model", async () => {
  Deno.env.set("GEMINI_API_KEY", "test-key");
  const calls: string[] = [];
  const fetcher = stubFetch([{ status: 503 }, { status: 503 }, {
    status: 200,
  }], calls);
  const response = await callGemini({}, { fetcher });
  assertEquals(response.status, 200);
  assertEquals(calls.length, 3);
  assertEquals(calls[0].includes("gemini-3.5-flash:"), true);
  assertEquals(calls[2].includes("gemini-3.5-flash-lite:"), true);
});

Deno.test("does not retry a client error", async () => {
  Deno.env.set("GEMINI_API_KEY", "test-key");
  const calls: string[] = [];
  const fetcher = stubFetch([{ status: 400 }], calls);
  await assertRejects(() => callGemini({}, { fetcher }), HttpError);
  assertEquals(calls.length, 1);
});

Deno.test("reports why a stream carried no text", () => {
  const blocked = JSON.stringify({ promptFeedback: { blockReason: "SAFETY" } });
  assertEquals(streamStop(blocked), "SAFETY");

  const truncated = JSON.stringify({
    candidates: [{ finishReason: "MAX_TOKENS", content: { parts: [] } }],
  });
  assertEquals(streamStop(truncated), "MAX_TOKENS");

  assertEquals(streamStop(chunk("hello")), undefined);
  assertEquals(streamStop("not-json"), undefined);
});
