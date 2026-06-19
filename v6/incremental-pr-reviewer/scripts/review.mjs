// Incremental PR reviewer — two phases, selected by argv[2]:
//   build : compute the diff since the last review, write the prompt file
//   post  : turn Claude's JSON into inline review comments + a sticky summary
//
// GitHub I/O uses global fetch (Node 20+) with GITHUB_TOKEN — no extra deps.
// The Claude call happens between the two phases, in the cost-guardrail action.

import fs from "node:fs";
import { execFileSync } from "node:child_process";

const API = "https://api.github.com";
const {
  GH_TOKEN, REPO, PR_NUMBER, BASE_SHA, HEAD_SHA, RESPONSE_FILE, GITHUB_OUTPUT,
} = process.env;
const [owner, repo] = (REPO || "").split("/");
const TMP = process.env.RUNNER_TEMP || "/tmp";
const PROMPT_FILE = `${TMP}/review-prompt.txt`;
const MARKER = "<!-- claude-incremental-review -->";

async function gh(path, init = {}) {
  const res = await fetch(`${API}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${GH_TOKEN}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`GitHub ${init.method || "GET"} ${path} -> ${res.status}: ${body.slice(0, 300)}`);
  }
  return res.status === 204 ? null : res.json();
}

function setOutput(name, value) {
  fs.appendFileSync(GITHUB_OUTPUT, `${name}=${value}\n`);
}

// Run git with an argument array (no shell) so refs can't inject commands.
function git(args) {
  return execFileSync("git", args, { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
}
const isSha = (s) => /^[0-9a-f]{7,40}$/i.test(s);

async function findSticky() {
  const comments = await gh(`/repos/${owner}/${repo}/issues/${PR_NUMBER}/comments?per_page=100`);
  return comments.find((c) => c.body && c.body.includes(MARKER)) || null;
}

function lastReviewedSha(body) {
  const m = body && body.match(/<!-- last-sha=([0-9a-f]{7,40}) -->/);
  return m ? m[1] : null;
}

async function build() {
  const sticky = await findSticky();
  const lastSha = sticky ? lastReviewedSha(sticky.body) : null;

  if (lastSha && lastSha === HEAD_SHA) {
    setOutput("changed", "false"); // nothing new since last review
    return;
  }

  const from = lastSha || BASE_SHA;
  // Refs come from GitHub event context / a hex-matched marker, but validate
  // before passing to git so a bad value can't become an option or path.
  for (const s of [from, BASE_SHA, HEAD_SHA]) {
    if (!isSha(s)) { setOutput("changed", "false"); throw new Error(`Refusing non-SHA git ref: ${s}`); }
  }
  try { git(["fetch", "--no-tags", "--quiet", "origin", from, HEAD_SHA]); } catch { /* best effort */ }

  let diff = "";
  try {
    diff = git(["diff", `${from}..${HEAD_SHA}`]);
  } catch {
    diff = git(["diff", `${BASE_SHA}..${HEAD_SHA}`]);
  }
  diff = diff.trim();
  if (!diff) { setOutput("changed", "false"); return; }

  const MAX = 50000;
  const clipped = diff.length > MAX ? `${diff.slice(0, MAX)}\n\n[diff truncated]` : diff;
  const scope = lastSha
    ? `the changes since the last review (commit ${lastSha.slice(0, 7)})`
    : "the full pull request";

  const prompt =
`Review ${scope} in this unified diff. Comment only on real problems in changed lines.
Use line numbers from the NEW (right) side of the diff. Return JSON matching the schema:
- "summary": a 1-3 sentence overall assessment.
- "comments": findings, each with "severity" of "blocker" | "warning" | "nit".

DIFF:
\`\`\`diff
${clipped}
\`\`\``;

  fs.writeFileSync(PROMPT_FILE, prompt);
  setOutput("changed", "true");
  setOutput("prompt_file", PROMPT_FILE);
}

async function post() {
  const raw = fs.readFileSync(RESPONSE_FILE, "utf8");
  let data;
  try { data = JSON.parse(raw); } catch { data = { summary: raw, comments: [] }; }
  const comments = Array.isArray(data.comments) ? data.comments : [];

  const inline = comments
    .filter((c) => c && c.path && Number.isInteger(c.line) && c.body)
    .map((c) => ({
      path: c.path,
      line: c.line,
      side: "RIGHT",
      body: `**${String(c.severity || "note").toUpperCase()}** — ${c.body}`,
    }));

  // Post a single review with inline comments; on 422 (e.g. a comment lands on a
  // line outside the diff) fall back to listing findings in the sticky summary.
  let postedInline = false;
  if (inline.length) {
    try {
      await gh(`/repos/${owner}/${repo}/pulls/${PR_NUMBER}/reviews`, {
        method: "POST",
        body: JSON.stringify({ commit_id: HEAD_SHA, event: "COMMENT", comments: inline }),
      });
      postedInline = true;
    } catch (e) {
      console.log(`::warning::Inline review failed (${e.message}); falling back to a summary comment.`);
    }
  }

  const n = (sev) => comments.filter((c) => c.severity === sev).length;
  const lines = [
    MARKER,
    `<!-- last-sha=${HEAD_SHA} -->`,
    "### 🤖 Claude incremental review",
    "",
    data.summary || "No summary provided.",
    "",
    `**Findings:** ${comments.length} (${n("blocker")} blocker, ${n("warning")} warning, ` +
      `${n("nit")} nit) · reviewed through \`${(HEAD_SHA || "").slice(0, 7)}\``,
  ];
  if (!postedInline && comments.length) {
    lines.push("", "<details><summary>Findings (inline posting unavailable)</summary>", "");
    for (const c of comments) {
      lines.push(`- **${String(c.severity || "note").toUpperCase()}** \`${c.path}:${c.line}\` — ${c.body}`);
    }
    lines.push("", "</details>");
  }
  const body = lines.join("\n");

  const sticky = await findSticky();
  if (sticky) {
    await gh(`/repos/${owner}/${repo}/issues/comments/${sticky.id}`, { method: "PATCH", body: JSON.stringify({ body }) });
  } else {
    await gh(`/repos/${owner}/${repo}/issues/${PR_NUMBER}/comments`, { method: "POST", body: JSON.stringify({ body }) });
  }
}

const mode = process.argv[2];
(mode === "post" ? post() : build()).catch((e) => {
  console.log(`::error::${e.message}`);
  process.exit(1);
});
