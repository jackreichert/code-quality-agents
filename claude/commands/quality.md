---
description: "Code quality framework — runs targeted quality agents against your current git diff or full project. Usage: /quality [aspects] | /quality project [path] [aspects]"
argument-hint: "[project [path]] [code] [arch] [refactor] [tests] [security] [simplify] [process] [delivery] [distributed] [patterns] [persistence] — or omit for all"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Task"]
---

# Quality Framework

Run quality agents against the current git diff or the full project. Spawn relevant agents in parallel, then aggregate findings into a prioritized action plan.

**Requested aspects:** "$ARGUMENTS"

---

## Step 1 — Get the Diff (or Project Files)

**Check for project mode first.** If `project` appears anywhere in `$ARGUMENTS`, skip the diff and jump to **Case C** below.

Otherwise, check we're in a git repo:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```

**If not a git repo:** ask the user which files or directories to review explicitly. Skip the diff steps and pass file paths directly to agents.

**If in a git repo:** detect the current branch and pick the right diff scope.

```bash
git rev-parse --abbrev-ref HEAD
```

### Case A — On `main`, `staging`, or `develop` (long-lived branches)

Review what's about to be committed. In priority order:

```bash
git diff --cached                    # staged
git diff --cached --name-only
```

If empty, fall back to working tree:
```bash
git diff
git diff --name-only
git status --short
```

If still empty, ask the user which files to review.

### Case B — On a feature branch (anything else)

Review the entire branch's work since it forked, plus any uncommitted changes on top.

**Find the fork point.** Try parent candidates in priority order: `develop`, `staging`, `main`. Use the first one that exists locally or on `origin`. Prefer the remote ref (`origin/<branch>`) since the local copy may be stale; fall back to the local ref if no remote.

```bash
# Probe each candidate; first hit wins
for base in develop staging main; do
  if git rev-parse --verify --quiet "origin/$base" >/dev/null; then
    fork=$(git merge-base HEAD "origin/$base")
    parent="origin/$base"
    break
  elif git rev-parse --verify --quiet "$base" >/dev/null; then
    fork=$(git merge-base HEAD "$base")
    parent="$base"
    break
  fi
done
```

**Build the diff** — all commits on the branch + uncommitted working-tree changes:

```bash
git diff "$fork"...HEAD              # branch commits since fork
git diff "$fork"...HEAD --name-only
git diff                             # uncommitted on top
git diff --name-only
git status --short
```

The combined file list (branch commits ∪ working tree) feeds Step 2's auto-selection. The combined diff content feeds Step 4's agents.

**If no parent candidate exists** (rare — fresh repo, detached HEAD, exotic setup): fall back to Case A's logic and warn the user that fork-point detection failed.

**Edge case — feature-on-feature branches.** If `feature/x` was branched off `feature/y` (not `develop`), this probe will diff against `develop` and over-include `feature/y`'s commits. If the diff looks larger than expected, ask the user to confirm the base branch.

### Case C — Project mode (`project` in $ARGUMENTS)

Review all tracked source files in the repo, or a scoped subdirectory.

**Extract path scope:** scan `$ARGUMENTS` tokens for any that start with `.`, `/`, or contain `/` — that token is the path scope. If none found, default to repo root (`.`).

**Extract aspect keywords:** all remaining tokens (excluding `project` and the path) are the aspect filter for Step 2.

```bash
# List all git-tracked files under the scope
git ls-files <path>
```

**Filter the file list** — exclude the following before passing to agents:

| Exclude pattern | Reason |
|----------------|--------|
| `*.min.js`, `*.min.css` | Minified — unreadable |
| `*.lock`, `package-lock.json`, `yarn.lock`, `Pipfile.lock`, `poetry.lock` | Generated — no signal |
| `dist/`, `build/`, `out/`, `.next/`, `__pycache__/`, `.cache/` | Build output |
| `node_modules/`, `vendor/`, `.venv/`, `venv/` | Dependencies — not your code |
| `*.png`, `*.jpg`, `*.gif`, `*.webp`, `*.svg`, `*.ico`, `*.woff`, `*.woff2`, `*.ttf`, `*.pdf`, `*.zip` | Binary / assets |
| `*.map` | Source maps |

Warn the user if the filtered list exceeds 100 files, and offer to narrow by passing a subdirectory path.

**In project mode:** agents receive the filtered file list (not a diff). Agents use their own Read/Grep/Glob tools to inspect the files. In Step 4, pass `"mode: project-wide review — read the listed files in full"` instead of diff content.

---

## Step 2 — Determine Applicable Agents

Parse `$ARGUMENTS` for aspect keywords:
- `code` → quality-code-quality
- `arch` or `architecture` → quality-architecture
- `refactor` → quality-refactor (Mode 2: full refactor plan)
- `simplify` → quality-refactor (Mode 1: light simplify pass)
- `tests` or `test` → quality-test-quality
- `security` → quality-security-review
- `review` → quality-review (confidence-scored review with PR lenses)
- `process` → quality-process
- `delivery` or `deploy` → quality-delivery
- `distributed` or `dist` → quality-distributed
- `patterns` or `pattern` → quality-patterns
- `persistence` or `db` or `database` → quality-persistence
- No arguments / `all` → run all applicable agents (see rules below)

**Note on simplify routing:** `quality-refactor` now handles both modes. Mode is selected by the aspect keyword: `simplify` → Mode 1 (light), `refactor` → Mode 2 (full plan). The existing `code-simplifier` agent is no longer routed by this orchestrator.

**Auto-selection rules (when no arguments provided)**

In **diff mode**, these rules use signals detectable from `git diff --name-only` and the diff content itself.
In **project mode**, signals come from the filtered file list (extensions, directory names, file name patterns).

| Detectable signal | Agent to run |
|-------------------|-------------|
| Any source files present | quality-code-quality (always) |
| New files added (`A` in `git status`) OR diff touches imports/dependencies OR new classes/modules — *project mode: any source files* | quality-architecture |
| Test files in diff (`*.test.*`, `*.spec.*`, `*_test.*`, `test_*.py`) — *project mode: same patterns in file list* | quality-test-quality |
| Files in auth/payment/api paths OR diff touches input handling, sessions, secrets — *project mode: same path patterns in file list* | quality-security-review |
| Migration files (`migrations/`, `db/migrate/`, `alembic/`, `prisma/migrations/`) OR Dockerfiles, k8s manifests, CI/CD configs (`.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`) OR feature-flag config OR `.env*` template changes | quality-delivery |
| Service-to-service HTTP/gRPC calls (`axios`, `fetch`, `http.Client`, `requests`, `RestTemplate`, `grpc`) OR message-queue imports (`kafka`, `rabbitmq`, `sqs`, `pubsub`, `nats`, `eventbridge`) OR files under `services/` crossing service boundaries | quality-distributed |
| ORM imports (`hibernate`, `sqlalchemy`, `prisma`, `typeorm`, `sequelize`, `mongoose`, `ActiveRecord`, `EntityFramework`) OR `*.sql`, `*.prisma`, schema files OR repository / DAO files OR raw SQL in diff | quality-persistence |
| After other reviews complete (always last, on recently modified code) | quality-refactor in Mode 1 (Simplify) |

**Opt-in only — never auto-spawned:**
- `quality-refactor` in Mode 2 (full plan) — invoke via `/quality refactor` when smells need named refactoring moves prescribed
- `quality-process` — invoke via `/quality process` when reviewing planning discipline of a significant change
- `quality-patterns` — invoke via `/quality patterns` for pattern recognition / anti-pattern audit (auto-detection of "this should be a Strategy" is unreliable; prefer explicit invocation, often after `quality-code-quality` finds smells)
- `quality-review` — invoke via `/quality review` for the full PR-style review with confidence scoring and lenses; redundant with the auto-selection above for normal pre-commit use

**Suggestion behavior:** When auto-spawning produces findings, suggest follow-up agents that aren't auto-spawned:
- If `quality-code-quality` flags multiple smells (Switch on type code, Long Method with branches, etc.) → suggest `/quality patterns` for prescribed pattern recognition AND `/quality refactor` for Fowler moves
- If significant changes were made → suggest `/quality process` for planning audit
- If `quality-distributed` flags partial-failure issues → suggest `/quality arch` for the underlying resilience patterns
- If `quality-persistence` flags N+1 or migration issues → ensure `quality-delivery` ran (or suggest it) for migration safety

When in doubt: run `quality-code-quality` only.

---

## Step 3 — Display Plan

Before spawning, show the appropriate header:

**Diff mode:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 QUALITY ► REVIEWING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Changed files: [list from git diff --name-only]

◆ Spawning agents in parallel...
  → [agent name] — [what it checks]
  → [agent name] — [what it checks]
  ...
```

**Project mode:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 QUALITY ► PROJECT SCAN  [scope: <path>]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Files in scope: [N files across M directories]
[list first 20 files, then "...and N more"]

◆ Spawning agents in parallel...
  → [agent name] — [what it checks]
  → [agent name] — [what it checks]
  ...
```

---

## Step 4 — Spawn Agents in Parallel

**Diff mode** — pass the full diff content and file list:

```
Task(
  prompt="Review the following git diff for code quality issues.
  
  Changed files: [list]
  
  Diff:
  [full git diff output]
  
  Focus on: naming, function design, code smells, complexity, comments.
  Use the checklist in your instructions.",
  subagent_type="quality-code-quality",
  description="Code quality review"
)
```

**Project mode** — pass the file list and instruct the agent to read the files itself:

```
Task(
  prompt="Project-wide code quality review.
  
  Mode: project-wide review — read and analyze the listed files in full using your Read, Grep, and Glob tools.
  
  Scope: [path]
  
  Files to review:
  [filtered file list, one per line]
  
  Focus on: naming, function design, code smells, complexity, comments.
  Use the checklist in your instructions. Prioritize findings that appear in multiple files or indicate systemic issues.",
  subagent_type="quality-code-quality",
  description="Code quality project scan"
)
```

Spawn all selected agents simultaneously (parallel, not sequential).

**Note on simplify:** Always spawn `quality-refactor` (Mode 1) LAST, after other reviews complete, so it polishes rather than duplicates findings. Pass `mode=simplify` in the prompt so the agent picks the correct mode.

---

## Step 5 — Aggregate Results

After all agents complete, aggregate by severity (every agent now reports Critical/Important/Minor with consistent semantics):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 QUALITY ► RESULTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Critical — Fix Before Committing
- [agent] file:line — description

## Important — Fix Before PR
- [agent] file:line — description

## Minor — Worth Doing
- [agent] file:line — description

## Strengths
- [what's done well across agents]

─────────────────────────────────────────────────

Agents run: [list] | Issues: [X critical, Y important, Z minor]
Verdict: [SHIP IT / NEEDS WORK / SIGNIFICANT ISSUES]
```

**Aggregation rules:**
- Deduplicate findings that multiple agents flagged for the same file:line
- Preserve the most severe rating when agents disagree on severity
- **Severity normalization** — different agents use different scales; normalize to Critical/Important/Minor before aggregating:

  | Agent's native scale | Mapped to |
  |---------------------|-----------|
  | Critical (CVSS) → quality-security-review | Critical |
  | High (CVSS) → quality-security-review | Critical |
  | Medium (CVSS) → quality-security-review | Important |
  | Low (CVSS) → quality-security-review | Minor |
  | All other agents (already use Critical/Important/Minor) | passthrough |

  Security findings get elevated weight: a CVSS-High vulnerability is treated as Critical for aggregation since security issues block ship more readily than other categories.

- Final verdict from normalized severity counts:
  - Any Critical → `SIGNIFICANT ISSUES`
  - No Critical, ≥1 Important → `NEEDS WORK`
  - No Critical, no Important → `SHIP IT`

**Suggest next steps if applicable:**
- If `quality-code-quality` flagged smells: suggest `/quality refactor` for prescribed moves
- If significant changes were made: suggest `/quality process` for planning audit
- If results were strong: confirm ready to commit

---

## Usage Examples

```
# — Diff mode (default) —
/quality                              # Run all applicable agents on git diff (auto-routed)
/quality code                         # Naming, functions, smells only
/quality arch                         # SOLID, dependencies, coupling, resilience
/quality refactor                     # Smell catalog, safe refactoring plan (Mode 2)
/quality simplify                     # Light behavior-preserving cleanup (Mode 1)
/quality tests                        # Test suite quality audit
/quality security                     # OWASP/CWE adversarial scan + SAST/SCA tools
/quality review                       # Confidence-scored PR-style review with lenses
/quality process                      # Planning discipline — edge cases, deps, Big-O
/quality delivery                     # CD pipeline readiness, 12-Factor, migrations
/quality distributed                  # Service boundaries, idempotency, replication
/quality patterns                     # GoF pattern recognition + anti-pattern audit
/quality persistence                  # ORM patterns, N+1, transactions, migrations
/quality code arch                    # Code quality + architecture
/quality code arch refactor           # Three-way review
/quality persistence delivery         # DB layer + deploy/migration audit (common pair)
/quality distributed arch             # Distributed concerns + structural review

# — Project mode —
/quality project                      # All applicable agents on all tracked source files
/quality project src/                 # Narrow scan to a subdirectory
/quality project code                 # Code quality only across full project
/quality project arch                 # Architecture-only project scan
/quality project security             # Security scan across full project
/quality project src/ code arch       # Subdirectory + specific aspects
/quality project code arch tests      # Full project, three aspects
```

---

## Tips

- **Project mode vs. diff mode.** Use `/quality` (diff) as a fast pre-commit/pre-PR gate. Use `/quality project` for onboarding a new codebase, a periodic health check, or when the diff-based approach misses systemic issues across files that weren't recently changed.
- **Narrow project scans.** On large repos, `/quality project src/services` is far more actionable than scanning everything. Start small and expand.
- **Scope depends on the branch.** On `main`/`staging`/`develop`, `/quality` reviews staged (or working-tree) changes — a pre-commit gate. On a feature branch, it reviews the entire branch since it forked from `develop`/`staging`/`main` (whichever is its parent), plus uncommitted changes on top — a pre-PR gate.
- **Run before committing on long-lived branches, before opening a PR on feature branches.** Critical issues block the commit/PR.
- **`/quality`** — default; runs always-on agents based on what changed.
- **`/quality code`** — fast, focused. Naming, smells, FP, error handling, performance, structure.
- **`/quality arch`** — before large features. Catches structural problems + resilience-pattern gaps before they're baked in.
- **`/quality refactor`** — before adding to messy code. Make the change easy, then make the easy change.
- **`/quality tests`** — when tests feel brittle. Find the smells before a refactor breaks them.
- **`/quality security`** — before any code touching auth, payments, user input, or external API surface goes live.
- **`/quality review`** — full PR-style review with the Google design-first priority order; ideal before opening a PR.
- **`/quality process`** — for significant features. Audits whether edge cases, dependencies, alternatives, and Big-O were considered.
- **`/quality simplify`** — final polish pass. Run it last, after other reviews pass.
- **`/quality delivery`** — when touching schema migrations, deployment config, feature flags, or anything that affects the deploy pipeline. Catches deploy-coupled changes that break rolling deploys.
- **`/quality distributed`** — when crossing service boundaries (HTTP, gRPC, queues) or touching replication, partitioning, distributed transactions. Reduces every distributed bug to one of Waldo's four categories.
- **`/quality patterns`** — after `/quality code` finds smells. Names the GoF pattern that prescribes the fix, OR flags pattern misuse (Singleton-as-global, Visitor abuse). Often invoked alongside `refactor`.
- **`/quality persistence`** — when ORM, repositories, queries, or migrations are in the diff. Catches N+1, deploy-coupled migrations, missing transaction boundaries, persistence leaking into domain.

### Common multi-aspect combinations

- `/quality persistence delivery` — DB code + migration safety. Run together when touching schema.
- `/quality distributed arch` — service-to-service work + the resilience patterns underneath.
- `/quality code patterns refactor` — when reviewing structural code: smells + pattern recognition + prescribed moves.
- `/quality security review` — pre-PR pass on any user-facing or auth code.
