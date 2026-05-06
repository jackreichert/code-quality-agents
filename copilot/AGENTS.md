# AGENTS.md — Code Quality Framework

Repo-level instructions for AI coding tools (Claude Code, GitHub Copilot, Cursor, Continue, Aider, etc.). Drop this file into any repo's root to apply Jack's `/quality` framework as the default review/code-generation lens.

The `AGENTS.md` convention is increasingly recognized across tools as a shared instruction file. Tools that don't read AGENTS.md directly typically read `.github/copilot-instructions.md` (Copilot) or `CLAUDE.md` (Claude Code) — symlink or duplicate this content into those locations as needed.

---

## Review Priority (Google Eng Practices)

When reviewing code, evaluate dimensions in this order. Block on items 1–4 when significant; flag the rest:

1. **Design** — fits architecture, not over-engineered, no premature generality
2. **Functionality** — behaves as intended, edge cases, concurrency, no accidental data loss
3. **Complexity** — could it be simpler? Solve current problem, not the general case
4. **Tests** — present, appropriate, not skipped, not flaky
5. **Naming** — specific, accurate, domain-aligned
6. **Comments** — explain *why*, not *what*; not outdated
7. **Style** — defer to linter/formatter
8. **Consistency** — match conventions in the directory
9. **Documentation** — README, API docs, changelogs updated when public surface changes

Standard: **net positive over current state, not perfection.**

## Report-First Protocol (review/refactor/simplify/test/security prompts)

When invoked for review, refactor, simplify, test-quality, or security audit: produce the report only. Do **not** edit, refactor, or apply any fix in that turn — even if asked. End the response by listing each finding with an ID (e.g. `[F1]`, `[F2]`) and ask: *"Which findings should I fix? (e.g. 'F1, F3' or 'all critical')"*. Apply fixes only on the user's next message, scoped strictly to the IDs they confirm.

## Code Quality Stance

Resolve Clean Code (Martin) vs APOSD (Ousterhout):
- **Functions**: prefer deep modules with clear top-down narrative over fragmented small functions. Line count is not a proxy for clarity.
- **Comments**: skip comments paraphrasing code; keep comments capturing *why*, invariants, and trade-offs.
- **Default**: optimize for next reader's time-to-understanding.

## Architecture

- **SOLID** at class level; **REP/CCP/CRP** + **ADP/SDP/SAP** at component level
- **Dependency direction inward only** (Clean Architecture or Hexagonal — same goal)
- **Hyrum's Law**: every observable behavior of an API will be relied upon. Behavior changes labeled "minor refactor" must verify callers
- **Conway's Law**: service/module boundaries align with team boundaries
- **Resilience patterns** (Timeout, Circuit Breaker, Bulkhead, Steady State, Fail Fast, Backpressure) at adapter boundaries, not in domain logic
- **Screaming Architecture**: top-level directory structure should reveal use cases, not framework

## Testing

- **Listen to the Tests** (GOOS): test pain is design feedback. Hard-to-write test → redesign production code, not the test
- **Four Pillars** (Khorikov): Protection Against Regressions · Resistance to Refactoring (most critical) · Fast Feedback · Maintainability. A zero on any pillar kills the test's value.
- **F.I.R.S.T.** + AAA structure; one logical assertion per test; name after behavior not method
- **Testing styles ranked**: output-based (pure functions) > state-based > communication-based. A suite dominated by communication-based tests signals over-mocking.
- **Mock only unmanaged external dependencies** (third-party APIs, SMTP, external buses). Never mock internal collaborators. Use real managed dependencies (your own DB) in integration tests. Never assert on stubs.
- **Beyoncé Rule** (SE@Google): if you liked it, put a test on it
- Mutation score on critical paths beats line coverage
- Test pyramid (backend) or trophy (frontend-heavy); ice-cream cone is the anti-pattern
- **Non-determinism** (Fowler): flaky tests are an active liability. Root causes: shared state, bare sleeps, remote services, direct clock calls, resource leaks. Quarantine with a hard limit.
- **Suite-level strategy**: use `quality-test-strategy` for project-wide shape/coverage/infrastructure audits; use `quality-tests` for diff-level file review.

## Refactoring

- Fowler smell→move catalog (Extract Function, Replace Conditional with Polymorphism, Remove Flag Argument, Replace Loop with Pipeline, etc.)
- WELC dependency-breaking techniques for legacy code (Subclass and Override Method, Extract and Override, Parameterize, Extract Interface)
- **Branch by Abstraction** for in-process replacement; **Strangler Fig** for system-level migration. **Never start over from a blank file** (Spolsky)
- Beck: "make the change easy, then make the easy change"

## Persistence

- Active Record vs Data Mapper choice intentional
- **No N+1 queries** — eager-load explicitly when traversing collections in loops
- Repository per aggregate root, not per table
- **Expand-contract migrations** must be safe with old + new code running simultaneously (rolling deploys, blue-green, rollback)
- Long-running transactions avoided; isolation level named in code

## Distributed Systems

**Waldo's Four Differences** (1994) — every distributed bug traces to one:
- **Latency** (10⁶× slower) — caching, batching
- **Memory access** — pointers don't cross the wire
- **Partial failure** — idempotency, retry with backoff
- **Concurrency** — no shared lock; use logical clocks

- Every remote call has a finite timeout
- State-mutating operations idempotent OR guarded by idempotency keys
- No clock comparisons across machines for ordering
- Saga / compensating transactions for distributed workflows

## Delivery

- **Trunk-based development**: ≤24-48h branch life, ≤200 line CL sweet spot
- **Build once, deploy everywhere**: same artifact promoted through stages
- **12-Factor App** compliance: config in env, stateless processes, logs to stdout
- **DORA Four Keys**: deploy frequency, lead time, change failure rate, MTTR. Speed and stability are NOT opposed at high CD maturity
- **Walking Skeleton**: end-to-end deploy before vertical features
- **Feature flag taxonomy**: release / experiment / ops / permission — different lifecycles, owners, removal expectations

## Security

OWASP Top 10:2021 systematic review. Beyond implementation bugs:
- **A04 Insecure Design** — threat model, trust boundaries, abuse cases, defense in depth
- **A08 Software/Data Integrity** — pinned deps + lockfile review, signed artifacts, CI/CD trust boundaries, SBOM
- **A09 Logging/Monitoring** — auth events, sensitive ops, failed-access logged with context, integrity, retention ≥90 days

If you can't write the exploit scenario, downgrade severity. **Tools augment manual review, never replace it.**

## Process

Before writing code:
- Edge cases (empty/null/zero/MAX, concurrent, network failure, partial writes)
- Blast radius (callers, shared state, implicit ordering)
- Alternatives considered, simpler solution available

After writing:
- Real requirements satisfied (not just surface ticket text)
- No regression of design principles
- Big-O analysis on loops, queries, transforms
- Assumptions documented or asserted

Commitment discipline (Clean Coder):
- "I'll try" is a lie. Surface specific objections + missing prerequisites
- Real commitments use "I will" + a date

## When This File Applies

- All code in this repo
- All AI-tool-generated suggestions, refactors, and reviews
- Both new code and existing-code modifications

## See Also

Full per-skill detail: <https://github.com/[your-handle]/code-quality-skills> *(or your local mirror)*

For Claude Code: per-skill agents at `~/.claude/agents/quality-*.md`; orchestrator at `~/.claude/commands/quality.md`.

For Copilot: per-skill prompts at `[user-shared-location]/copilot/prompts/quality-*.prompt.md`; global instructions at `[user-shared-location]/copilot/global-instructions.md`.
