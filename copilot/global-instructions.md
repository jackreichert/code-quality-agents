# Global Copilot Personal Instructions

A condensed (~2.5K char) summary of the `/quality` framework. Paste this into:
- **github.com → Settings → Copilot → Personal custom instructions**, OR
- **VS Code user settings** → `github.copilot.chat.codeGeneration.instructions`

This makes Copilot Chat aware of the framework's review priorities across every repo, even without prompt files.

---

## Paste-ready text

```
When reviewing or writing code, apply the /quality framework — a synthesis of Clean Code (Martin), A Philosophy of Software Design (Ousterhout), Refactoring (Fowler), Working Effectively with Legacy Code (Feathers), Clean Architecture (Martin), DDD (Evans), DDIA (Kleppmann), Release It! (Nygard), GOOS (Freeman/Pryce), xUnit Test Patterns (Meszaros), OWASP Top 10:2021, Continuous Delivery (Humble/Farley), Accelerate (Forsgren/Humble/Kim), and Software Engineering at Google.

Review priority order (Google Eng Practices): design > functionality > complexity > tests > naming > comments > style. Block on items 1-4 when significant; flag the rest. Net positive over current state, not perfection.

Report-first protocol for review/refactor/simplify/test/security audits: produce the report only — do not edit or apply fixes in that turn, even if asked. List each finding with an ID (e.g. F1, F2) and ask which to fix. Apply fixes only on the user's next message, scoped strictly to the confirmed IDs.

Code-quality stance — resolve Clean Code vs APOSD: prefer deep modules with clear top-down narrative over fragmented small functions; comments capture why and invariants, not what code already says. Optimize for next reader's time-to-understanding.

Architecture: SOLID at class level; REP/CCP/CRP + ADP/SDP/SAP at component level; dependency direction inward only; Hyrum's Law (every observable behavior gets relied on); Conway's Law (architecture mirrors team boundaries); place resilience patterns (Timeout, Circuit Breaker, Bulkhead, Steady State) at adapter boundaries.

Tests: Listen to the Tests (test pain is design feedback). F.I.R.S.T., AAA, mock roles not objects. Beyoncé Rule: if you liked it, put a test on it. Mutation score on critical paths > line coverage. Test pyramid (backend) or trophy (frontend-heavy).

Refactoring: Fowler smell→move catalog. Beck's "make the change easy, then make the easy change." Branch by Abstraction or Strangler Fig for large refactors instead of long-lived branches. Never start over from a blank file.

Persistence: Active Record vs Data Mapper choice intentional. No N+1 queries. Repository per aggregate root. Expand-contract migrations safe with old + new code running simultaneously.

Distributed systems: Waldo's four differences (latency, memory, partial failure, concurrency). Every remote call needs a finite timeout. Idempotency keys on state mutations. No clock comparison across machines for ordering.

Delivery: trunk-based, ≤24-48h branch life, ≤200 line CL sweet spot. Build once, deploy everywhere. 12-Factor compliance. DORA Four Keys (deploy frequency, lead time, change failure rate, MTTR) — speed and stability are not opposed. Walking Skeleton before vertical features.

Security: OWASP Top 10:2021 systematic checklist including A04 Insecure Design (threat model, abuse cases, defense in depth), A08 Software/Data Integrity (supply chain), A09 Logging/Monitoring (auth events, sensitive ops, retention). If you can't write the exploit scenario, downgrade severity.

Process: think before writing (edge cases, blast radius, alternatives), validate after (requirements, design principles, Big-O, assumptions). Saying No: "I'll try" is a lie. Saying Yes: "I will" + a date.

When tools (linters, SAST, SCA) aren't available in this context, proceed with manual review and call out which categories would benefit from automated scanning.

Full per-skill detail: see ~/Documents/AryaObsidian/Code-Quality-Skills/ in user's environment, or AGENTS.md if present in the repo.
```

---

## Why this works

- **Repo-agnostic** — no project-specific assumptions; applies to any codebase.
- **Source-attributed** — Copilot knows the priority order has authority behind it.
- **Compact** — fits within github.com's 3000-char personal-instructions limit.
- **Bridges to deeper detail** — references AGENTS.md (per-repo) and the canonical skills directory (Jack's local).

## Where to put it

| Location | Effect |
|----------|--------|
| github.com → Settings → Copilot → Personal custom instructions | Applies in github.com Copilot Chat, every repo |
| VS Code user settings.json → `github.copilot.chat.codeGeneration.instructions` | Applies in VS Code Copilot Chat for code generation |
| VS Code user settings.json → `github.copilot.chat.reviewSelection.instructions` | Applies when using Copilot's "Review and Comment" on a selection |
| `.github/copilot-instructions.md` in a repo | Applies in that repo specifically (combined with global) |

## VS Code settings.json snippet

Add to user `settings.json` (Cmd+Shift+P → "Preferences: Open User Settings (JSON)"):

```json
{
  "github.copilot.chat.codeGeneration.instructions": [
    {
      "file": "~/Documents/AryaObsidian/Code-Quality-Skills/copilot/global-instructions.md"
    }
  ],
  "github.copilot.chat.reviewSelection.instructions": [
    {
      "file": "~/Documents/AryaObsidian/Code-Quality-Skills/copilot/global-instructions.md"
    }
  ],
  "chat.promptFiles": true,
  "chat.promptFilesLocations": {
    "~/Documents/AryaObsidian/Code-Quality-Skills/copilot/prompts": true
  }
}
```

The `chat.promptFiles` + `chat.promptFilesLocations` lines make the per-skill prompt files (`/quality-code`, `/quality-arch`, etc.) available across all VS Code workspaces, not just per-repo.
