// Self-healing CI triage — two phases, selected by argv[2]:
//   build : pull the failed run's logs via the gh CLI, write the prompt file
//   post  : post Claude's diagnosis as a sticky comment on the PR (or commit)
//
// GitHub reads/writes use global fetch (Node 20+) and the gh CLI; no extra deps.

import fs from "node:fs";
import { execFileSync } from "node:child_process";

const API = "https://api.github.com";
const { GH_TOKEN, REPO, RUN_ID, RESPONSE_FILE, GITHUB_OUTPUT } = process.env;
const [owner, repo] = (REPO || "").split("/");
const TMP = process.env.RUNNER_TEMP || "/tmp";
const PROMPT_FILE = `${TMP}/triage-prompt.txt`;

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

// Run the gh CLI with an argument array (no shell).
function ghCli(args) {
  return execFileSync("gh", args, { encoding: "utf8", maxBuffer: 64 * 1024 * 1024 });
}

async function build() {
  if (!/^\d+$/.test(RUN_ID || "")) throw new Error(`Unexpected run id: ${RUN_ID}`);

  const meta = JSON.parse(
    ghCli(["run", "view", RUN_ID, "--repo", REPO, "--json",
      "headSha,headBranch,displayTitle,workflowName,event,pullRequests"])
  );

  let logs = "";
  try { logs = ghCli(["run", "view", RUN_ID, "--repo", REPO, "--log-failed"]); }
  catch {
    try { logs = ghCli(["run", "view", RUN_ID, "--repo", REPO, "--log"]); }
    catch { logs = "(logs unavailable)"; }
  }

  const MAX = 16000;
  const tail = logs.length > MAX ? logs.slice(-MAX) : logs;

  const prompt =
`A CI run failed. Diagnose the most likely root cause and the smallest fix.

Workflow: ${meta.workflowName}
Title: ${meta.displayTitle}
Branch: ${meta.headBranch}
Commit: ${meta.headSha}

Failing log (tail):
\`\`\`
${tail}
\`\`\`

Respond with exactly these sections:
1. **Root cause** — one or two sentences.
2. **Suggested fix** — concrete and minimal.
3. **Confidence** — high | medium | low, with a short reason.
Keep it under ~200 words.`;

  fs.writeFileSync(PROMPT_FILE, prompt);
  setOutput("prompt_file", PROMPT_FILE);
  setOutput("head_sha", meta.headSha || "");
  setOutput("workflow_name", meta.workflowName || "CI");
  const pr = meta.pullRequests && meta.pullRequests[0] ? meta.pullRequests[0].number : "";
  setOutput("pr_number", String(pr));
}

async function post() {
  const diagnosis = fs.readFileSync(RESPONSE_FILE, "utf8").trim();
  const headSha = process.env.HEAD_SHA || "";
  const prNumber = process.env.PR_NUMBER || "";
  const wf = process.env.WORKFLOW_NAME || "CI";
  // Dedupe per (workflow, failing commit) so re-runs update one comment.
  const marker = `<!-- claude-ci-triage:${wf}:${headSha} -->`;
  const body =
`${marker}
### 🤖 Claude CI triage — \`${wf}\` failed

${diagnosis}

<sub>Automated diagnosis for commit \`${headSha.slice(0, 7)}\`. Verify before applying.</sub>`;

  if (prNumber) {
    const comments = await gh(`/repos/${owner}/${repo}/issues/${prNumber}/comments?per_page=100`);
    const existing = comments.find((c) => c.body && c.body.includes(marker));
    if (existing) {
      await gh(`/repos/${owner}/${repo}/issues/comments/${existing.id}`, { method: "PATCH", body: JSON.stringify({ body }) });
    } else {
      await gh(`/repos/${owner}/${repo}/issues/${prNumber}/comments`, { method: "POST", body: JSON.stringify({ body }) });
    }
  } else {
    // No PR — fall back to a commit comment.
    const commitComments = await gh(`/repos/${owner}/${repo}/commits/${headSha}/comments?per_page=100`);
    const existing = commitComments.find((c) => c.body && c.body.includes(marker));
    if (!existing) {
      await gh(`/repos/${owner}/${repo}/commits/${headSha}/comments`, { method: "POST", body: JSON.stringify({ body }) });
    } else {
      console.log("::notice::Diagnosis already posted for this commit/workflow.");
    }
  }
}

const mode = process.argv[2];
(mode === "post" ? post() : build()).catch((e) => {
  console.log(`::error::${e.message}`);
  process.exit(1);
});
