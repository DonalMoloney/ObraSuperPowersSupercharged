// Cost-guarded single Anthropic Messages API call.
//
// Reads a prompt file, enforces a per-run output ceiling and a persisted monthly
// USD spend ceiling, calls Claude once, accounts for the cost, and writes the
// model's text response to a file. Invoked by ../action.yml — all configuration
// arrives via CG_* environment variables.
//
// Resolves "@anthropic-ai/sdk" from node_modules installed into the action dir
// (see the "Install Anthropic SDK" step in action.yml).

import fs from "node:fs";
import crypto from "node:crypto";
import Anthropic from "@anthropic-ai/sdk";

// USD per 1M tokens (input, output). Source: claude-api skill price table.
const PRICES = {
  "claude-fable-5":    { in: 10, out: 50 },
  "claude-opus-4-8":   { in: 5,  out: 25 },
  "claude-opus-4-7":   { in: 5,  out: 25 },
  "claude-opus-4-6":   { in: 5,  out: 25 },
  "claude-sonnet-4-6": { in: 3,  out: 15 },
  "claude-haiku-4-5":  { in: 1,  out: 5  },
};

const {
  CG_PROMPT_FILE, CG_MODEL, CG_SYSTEM, CG_MAX_TOKENS, CG_EFFORT,
  CG_SCHEMA_FILE, CG_MONTHLY_CAP_USD, CG_SPEND_FILE, CG_RESPONSE_FILE,
  GITHUB_OUTPUT,
} = process.env;

function setOutput(name, value) {
  const delim = `__cg_${crypto.randomUUID()}`;
  fs.appendFileSync(GITHUB_OUTPUT, `${name}<<${delim}\n${value}\n${delim}\n`);
}
const notice = (m) => console.log(`::notice::${m}`);
function fail(m) { console.log(`::error::${m}`); process.exit(1); }

const month = new Date().toISOString().slice(0, 7); // YYYY-MM
const cap = parseFloat(CG_MONTHLY_CAP_USD || "0");

// --- read persisted month-to-date spend (rolling cache; reset on month change) ---
let spent = 0;
try {
  const s = JSON.parse(fs.readFileSync(CG_SPEND_FILE, "utf8"));
  if (s.month === month && typeof s.spentUsd === "number") spent = s.spentUsd;
} catch { /* first run this month */ }

if (cap > 0 && spent >= cap) {
  fail(
    `Monthly Claude spend ceiling reached: $${spent.toFixed(2)} >= $${cap.toFixed(2)} (${month}). ` +
    `Raise monthly-cap-usd / CLAUDE_MONTHLY_CAP_USD, or wait for the counter to reset next month.`
  );
}

const prices = PRICES[CG_MODEL] || PRICES["claude-opus-4-8"];

// --- build the request (adaptive thinking + effort, per claude-api guidance) ---
const req = {
  model: CG_MODEL,
  max_tokens: parseInt(CG_MAX_TOKENS || "8000", 10),
  thinking: { type: "adaptive" },
  output_config: { effort: CG_EFFORT || "high" },
  messages: [{ role: "user", content: fs.readFileSync(CG_PROMPT_FILE, "utf8") }],
};
if (CG_SYSTEM && CG_SYSTEM.trim()) req.system = CG_SYSTEM;
if (CG_SCHEMA_FILE && CG_SCHEMA_FILE.trim()) {
  req.output_config.format = {
    type: "json_schema",
    schema: JSON.parse(fs.readFileSync(CG_SCHEMA_FILE, "utf8")),
  };
}

const client = new Anthropic(); // reads ANTHROPIC_API_KEY

let resp;
try {
  resp = await client.messages.create(req);
} catch (err) {
  fail(`Anthropic API error: ${err?.message || err}`);
}

if (resp.stop_reason === "refusal") {
  fail(`Claude declined this request (category: ${resp.stop_details?.category ?? "unknown"}).`);
}

const text = (resp.content || [])
  .filter((b) => b.type === "text")
  .map((b) => b.text)
  .join("\n")
  .trim();

// --- cost accounting (cache reads ~0.1x, cache writes ~1.25x) ---
const u = resp.usage || {};
const inTok =
  (u.input_tokens || 0) +
  (u.cache_creation_input_tokens || 0) * 1.25 +
  (u.cache_read_input_tokens || 0) * 0.1;
const cost = (inTok * prices.in + (u.output_tokens || 0) * prices.out) / 1e6;
spent += cost;

fs.writeFileSync(CG_SPEND_FILE, JSON.stringify({ month, spentUsd: spent }));
fs.writeFileSync(CG_RESPONSE_FILE, text);

setOutput("response-file", CG_RESPONSE_FILE);
setOutput("spent-usd", spent.toFixed(4));
notice(
  `Claude call ≈ $${cost.toFixed(4)} (${CG_MODEL}); ` +
  `month-to-date $${spent.toFixed(2)}${cap > 0 ? ` / cap $${cap.toFixed(2)}` : ""}.`
);

if (resp.stop_reason === "max_tokens") {
  notice("Response hit max_tokens — output may be truncated. Consider raising max-tokens.");
}
