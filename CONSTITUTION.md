# The Constitution — Write-Time Engineering Discipline

> The `/quality` agents *catch* problems after code exists. This Constitution *prevents* them while code is being written. It is the always-on companion to the review framework: the same distilled CS canon, compiled into terse imperative rules an agent obeys on **every task**, before a single review runs.
>
> Inspired by the layered-constitution pattern in [unclebob/swarm-forge](https://github.com/unclebob/swarm-forge). Where swarm-forge ships ~5 hard rules, this Constitution distills the quality skills — but keeps the same spirit: *disciplined agents build better software, faster and more reliably, by embedding craftsmanship up front rather than relying on post-hoc review.*

## How to load it

This is opt-in and always-on once imported — it is **not** a slash command.

- **Claude Code** — add one line to your project's `CLAUDE.md` (or `~/.claude/CLAUDE.md`):
  ```
  @/absolute/path/to/Code-Quality-Skills/CONSTITUTION.md
  ```
  Claude Code resolves `@`-imports at load time, so the rules ride along on every turn.
- **Copilot / Cursor / Continue** — paste the articles below into your repo-root `AGENTS.md` (or the tool's per-repo instructions file).

Each article is a *summary*. The authoritative, citation-rich reasoning lives in the matching `skills/*.md` — follow the pointer when a rule needs justification or nuance.

---

## Article I — Conflict Precedence (the tie-break order)

When two rules pull in opposite directions, resolve in this fixed order — **earlier wins**. This is the global arbiter for the cross-skill tensions the skills document individually (e.g. Clean Code's small functions vs. APOSD's deep modules).

1. **Correctness** — the code does what it must; tests pass. Nothing below matters if this fails.
2. **Security & data safety** — no injection, no leaked secrets, no PHI exposure, validated input. A security finding outranks a style or simplicity preference.
3. **Readability for the next maintainer** — optimize for time-to-understanding six months out, not for line counts or cleverness.
4. **Simplicity** — the simplest design that supports current behavior and leaves clear options for the next step. Prefer deleting over adding.
5. **Consistency** — match the surrounding code's idioms, naming, and structure over importing a personal preference.
6. **Performance** — correct big-O for realistic `n`; pick the right data structure; cache deliberately and invalidate correctly; avoid N+1 and needless nested loops. Profile before micro-optimizing, and never trade away 1–4 for speed you haven't measured.

> Apply the **scalpel, not the sledgehammer**: targeted changes beat large rewrites. Preserve existing behavior unless a change is explicitly requested.

---

## Article II — Code
*Deep reference: [`skills/code-quality.md`](skills/code-quality.md), [`skills/patterns.md`](skills/patterns.md)*

- **Names reveal intent.** A reader infers purpose in <3 seconds. Nouns for classes, verbs for methods. Units and constraints in the name (`timeout_ms`, `max_retries`). No `Manager`/`Processor`/`Data`/`Info` filler. No magic numbers.
- **Functions do one thing.** One responsibility, ~20–30 lines as a soft ceiling. Extract a nested block only when its name genuinely *abstracts* — not to hit a line count.
- **0–2 arguments ideal, ≤3.** No boolean flags that select behavior — split the function.
- **DRY, but not prematurely.** Two copies that will diverge are a smell; two that coincidentally match are not.
- **Comments explain *why*, not *what*.** Capture invariants, trade-offs, and constraints code can't express. Delete comments that paraphrase the code.
- **Functional discipline.** Prefer pure functions and immutability. Push I/O and side effects to the boundaries; keep the core deterministic. Declarative (`map`/`filter`/`reduce`) over imperative loops where it reads clearer. Early returns over nested conditionals.
- **Fail fast, fail loud.** Raise specific, meaningful exceptions early; never silently swallow them; never signal errors with `None` or magic values — raise, or return a Result. Log at the appropriate level (debug/info/warn/error).
- **Apply Beck's four rules of simple design, in order:** passes all tests → no duplication → expresses intent → fewest classes/methods.
- **Two hats** *(Fowler, Refactoring ch.2)*: never add behavior and refactor in the same step — wear one hat at a time, and never refactor while a test is red. Keep refactoring commits separate from feature commits.

## Article III — Design & Architecture
*Deep reference: [`skills/architecture.md`](skills/architecture.md), [`skills/distributed.md`](skills/distributed.md), [`skills/persistence.md`](skills/persistence.md)*

- **SOLID by default.** One reason to change per module. Depend on abstractions, inject dependencies, keep interfaces small and focused.
- **Dependencies point inward.** Domain logic does not import frameworks, I/O, or persistence. Keep the dependency arrows aimed at stable abstractions.
- **No dependency cycles; depend toward stability.** The module/package dependency graph stays acyclic (ADP) — break any cycle with an interface or a shared third component. A module depends only on ones more stable than itself (SDP), never the reverse.
- **Favor composition + DI over inheritance.**
- **Deep modules, narrow interfaces** (APOSD): hide complexity behind a small surface. Information hiding beats exposing internals for convenience.
- **Across a process boundary, think distributed** (Waldo): assume latency, partial failure, concurrency, and no shared memory. Make remote operations idempotent; never silently swallow a remote failure.
- **Persistence stays at the edge.** No N+1 queries; explicit transaction boundaries; ORM mappings don't leak into the domain.

## Article IV — Tests (write them *with*, or *before*, the code)
*Deep reference: [`skills/test-quality.md`](skills/test-quality.md), [`skills/specification.md`](skills/specification.md), [`skills/process.md`](skills/process.md)*

- **Specify behavior before building it.** For non-trivial features, capture the requirement as concrete, declarative **key examples** (Given/When/Then) — the shared source of truth a developer, tester, and businessperson all read the same way. Specify *what*, not UI mechanics; parameterize only what varies.

- **TDD where it pays:** for non-trivial logic, follow Uncle Bob's **Three Laws** — (1) no production code except to make a failing test pass; (2) no more test than is sufficient to fail; (3) no more production code than is sufficient to pass. That is the Red → Green → Refactor cycle. Tests written after the fact tend to test implementation, not behavior.
- **Test behavior, not internals.** A safe refactor must leave the suite green; a behavior change must turn it red. Mock only externals (I/O, clock, network, randomness) — never your own code.
- **F.I.R.S.T.** — Fast, Isolated, Repeatable, Self-validating, Timely. A unit test >100ms is hiding real I/O.
- **AAA structure, one logical assertion, intention-revealing names** (`method_scenario_expectedBehavior`).
- **The Beyoncé Rule:** if the team relies on a behavior, it has a test that fails when the behavior breaks. "Tested manually once" does not count.
- **Coverage is a floor (~80% on core logic), not a ceiling.** Mutation score is the real oracle of test strength — see Article VII.

## Article V — Security & Secrets
*Deep reference: [`skills/security-review.md`](skills/security-review.md)*

- **Validate and sanitize all external input** at the boundary. Treat every input as hostile until proven otherwise.
- **Never commit secrets.** No keys, passwords, or connection strings in code — env vars or a secret manager only. Never read or echo `.env*` files.
- **Least privilege everywhere.** Strong password hashing (Argon2id/bcrypt). Pin and audit dependencies.
- **No PHI / PII in prompts, logs, or fixtures.** Use placeholders (`$1`, `fake_id_123`, `test@example.com`). If unsure whether something is safe to include — it is not.

## Article VI — Delivery
*Deep reference: [`skills/delivery.md`](skills/delivery.md)*

- **Every commit is shippable.** Work in small, reviewable increments on trunk or short-lived branches. Hide incomplete work behind a flag, not a long-lived branch.
- **Schema changes are expand-contract.** Add the new shape, migrate, then remove the old — never a breaking change in one deploy.
- **12-Factor config:** configuration in the environment, not the code. Logs to stdout. Stateless processes.
- **Observability is a prerequisite, not an afterthought.** New behavior ships with the logs/metrics needed to see it working.

---

## Article VII — Numeric Gates (the enforceable floor)
*Deep reference: [`skills/gates.md`](skills/gates.md) — run via `/quality gates` or the [pre-commit hook](hooks/)*

Subjective rules above become objective here. These thresholds are the *minimum*, not the target. A change that breaches one is not done until it's fixed or an explicit, recorded exception is taken.

| Gate | Threshold | Tooling (examples) |
|------|-----------|--------------------|
| **Lint** | Zero errors; warnings triaged | language-native linter (eslint, ruff, golangci-lint, clippy) |
| **Cyclomatic complexity** | ≤ 10 per function (≤ 15 hard cap) | lizard, radon, gocyclo |
| **CRAP score** | ≤ 30 per function (≤ 6 once refactored) | crap4j-style: `complexity² × (1−coverage)³ + complexity` |
| **Function length** | ≤ 60 lines (soft); flag > 100 | lizard, custom |
| **Duplication** | No new copy-paste blocks | jscpd, similarity, PMD-CPD |
| **Test coverage** | ≥ 80% on changed core logic | native coverage tool |
| **Mutation score** | ≥ 80% killed on changed critical-path code (≥ 90% for payment/auth/billing) | Stryker, PIT, mutmut, go-mutesting |

> Thresholds are defaults — a project may tighten or relax them in `skills/gates.md`'s project overrides, but a relaxation must be deliberate and written down, never silent.

---

## Article VIII — Definition of Done

A task is complete only when **all** of the following hold. This is the checklist swarm-forge calls a Definition of Done; treat it as the gate before you say "done."

- [ ] **Requirements met** — old and new business logic both satisfied; deviations and assumptions documented.
- [ ] **Tests written and green** — behavior-level, covering the happy path *and* edge cases (empty, null, zero, boundary, concurrent).
- [ ] **Numeric gates pass** (Article VII) — lint clean, complexity/duplication within bounds, coverage and mutation thresholds met on changed code.
- [ ] **Self-review done** — names reveal intent; functions do one thing; no swallowed exceptions; specific exception types; no N+1; big-O acceptable.
- [ ] **Security clear** — all external input validated; no secrets, PHI, or PII committed.
- [ ] **Precedence honored** — where rules conflicted, Article I's order was applied and the trade-off is explained.
- [ ] **Reviewed** — `/quality` run on the diff with no unresolved Critical findings.
- [ ] **Committed cleanly** — atomic commit, no unrelated changes or generated artifacts, on a feature branch (never directly to a protected branch).

> When in doubt, run `/quality` for the full review before declaring a feature done.

---

## Article IX — Communication Style

*Personalized by `install.sh --link --name "Your Name"` (it asks if you omit `--name`). The haiku/limerick sign-off is **off by default** — turn it on with `--poem` (and off again with `--no-poem`). An un-personalized clone shows the `__USER_NAME__` placeholder.*

<!-- BEGIN quality:communication-style -->
- Start every answer with "Hey __USER_NAME__" and end with "Cheers __USER_NAME__!"
<!-- END quality:communication-style -->

