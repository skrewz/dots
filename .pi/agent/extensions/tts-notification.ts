import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readFileSync } from "node:fs";
import { join } from "node:path";

// --- Config loading ---

const CONFIG_PATH = join(
  process.env.HOME ?? "/root",
  ".pi",
  "agent",
  "extensions",
  "tts-notification.json"
);

interface TtsConfig {
  endpoint: string;
  apiKey?: string;
  model?: string;
  voice?: string;
}

let config: TtsConfig;

try {
  const raw = readFileSync(CONFIG_PATH, "utf-8");
  config = JSON.parse(raw) as TtsConfig;
} catch (err) {
  throw new Error(
    `[tts-notification] Failed to load config from ${CONFIG_PATH}: ${err instanceof Error ? err.message : String(err)}\n` +
    `Create the file with at least { "endpoint": "https://your-tts-server/v1/audio/speech" }`
  );
}

if (!config.endpoint) {
  throw new Error(
    `[tts-notification] PI_TTS_ENDPOINT is not set and "endpoint" is missing in ${CONFIG_PATH}\n` +
    `Set PI_TTS_ENDPOINT in your shell, or add "endpoint" to the config file.`
  );
}

const ENDPOINT = config.endpoint;
const API_KEY = config.apiKey;
const MODEL = config.model || "tts-1";
const VOICE = config.voice || "alloy";

// --- Summary builder ---

function buildSummary(messages: unknown[]): string {
  let assistantText = "";
  const toolCalls: string[] = [];
  const toolResults: string[] = [];

  for (const msg of messages) {
    if (typeof msg !== "object" || msg === null) continue;
    const m = msg as Record<string, unknown>;
    if (m.role === "assistant") {
      if (Array.isArray(m.content)) {
        for (const part of m.content) {
          if (typeof part === "object" && part !== null) {
            if (part.type === "text" && typeof part.text === "string") {
              assistantText += part.text;
            }
            if (part.type === "toolCall" && typeof part.name === "string") {
              toolCalls.push(part.name);
            }
          }
        }
      }
    }
    if (m.role === "toolResult" && typeof m.toolName === "string") {
      toolResults.push(m.toolName);
    }
  }

  const toolCounts = new Map<string, number>();
  for (const t of toolCalls) {
    toolCounts.set(t, (toolCounts.get(t) || 0) + 1);
  }
  for (const t of toolResults) {
    toolCounts.set(t, (toolCounts.get(t) || 0) + 1);
  }

  if (toolCounts.size > 0) {
    const parts: string[] = [];
    for (const [tool, count] of toolCounts) {
      const label = tool === "bash" ? "commands" : `${count} ${tool}${count > 1 ? "s" : ""}`;
      parts.push(`${count} ${label}`);
    }
    return parts.join(", ");
  }

  const text = assistantText.trim();
  return text.length > 80 ? text.slice(0, 80) + "..." : text || "done";
}

// --- Main extension ---

export default function (pi: ExtensionAPI) {
  pi.on("agent_end", async (_event, ctx) => {
    const summary = buildSummary(_event.messages);
    if (!summary.trim()) return;

    try {
      const headers: Record<string, string> = {
        "Content-Type": "application/json",
      };
      if (API_KEY) {
        headers["Authorization"] = `Bearer ${API_KEY}`;
      }

      const response = await fetch(ENDPOINT, {
        method: "POST",
        headers,
        body: JSON.stringify({
          model: MODEL,
          input: summary,
          voice: VOICE,
        }),
        signal: ctx.signal,
      });

      if (!response.ok) {
        const errText = await response.text().catch(() => "");
        ctx.ui.notify(`TTS failed: ${response.status} ${errText.slice(0, 60)}`, "warning");
        return;
      }

      // Consume body to avoid resource leaks (endpoint handles the speaking)
      await response.body?.consume?.();
    } catch (err) {
      if (err instanceof Error && err.name === "AbortError") return;
      ctx.ui.notify(`TTS notification failed: ${err instanceof Error ? err.message : String(err)}`, "warning");
    }
  });
}
