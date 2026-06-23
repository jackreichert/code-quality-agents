# Code Quality Skills — Sources & Index

## What this is

This repo is a **code-review framework** that runs inside [Claude Code](https://docs.claude.com/claude-code) via the `/quality` slash command. It spawns specialized review agents — for code quality, architecture, refactoring, testing, security, delivery, distributed systems, design patterns, persistence, and process discipline — against your current `git diff` and aggregates their findings into a severity-ranked verdict (`SHIP IT` / `NEEDS WORK` / `SIGNIFICANT ISSUES`). Its write-time companion — the always-on [Constitution](CONSTITUTION.md) — also reaches GitHub Copilot and Codex via `install.sh --link` (see [Multi-tool reach](#multi-tool-reach)).

Each agent is a focused lens. The orchestrator picks which lenses are relevant to the diff, runs them in parallel, deduplicates overlap, and returns one report.

## How it was created

The framework is a **distillation of the canonical CS literature** into agent-executable form. The pipeline:

1. **Source selection.** A reading list of ~24 canonical books plus key articles and papers (Clean Code, Refactoring, A Philosophy of Software Design, Clean Architecture, GOOS, Designing Data-Intensive Applications, PEAA, Release It!, Continuous Delivery, GoF, the OWASP standards, etc.) — the full inventory lives in [`CS-Best-Practices-Resources.md`](CS-Best-Practices-Resources.md).
2. **Per-source summaries.** Each book/article was summarized into a structured note in [`Resources/`](Resources/) (Books, Articles, Papers, Standards, Originals). These summaries capture the principles, smell catalogs, patterns, and counterpoints from each source — not full reproductions, but enough to drive synthesis.
3. **Cross-source synthesis into skills.** The summaries were synthesized into ~12 topical **skill documents** in [`skills/`](skills/) — the canonical, human-readable references. Each skill cites the specific chapters and articles that drove each section, and reconciles tensions between sources (e.g., Clean Code ch.4 vs. APOSD ch.12-15 on comments).
4. **Agent compilation.** Each skill is compiled into a concise **agent prompt** at `~/.claude/agents/quality-*.md`. The agents are the executable form; the skill files are the reasoning trail.
5. **Orchestration.** The `/quality` slash command routes a diff to the relevant agents, runs them in parallel, normalizes severity, and aggregates the report.

The "Sources by Skill" section below shows exactly which book/article/chapter informed each part of each skill, so any finding the framework produces can be traced back to a primary source.

For the master inventory of every book and article that informed this work, see [`CS-Best-Practices-Resources.md`](CS-Best-Practices-Resources.md). For the lineage of individual sections within each skill, see "Sources by Skill" further down.

---

## Quick start

Install into [Claude Code](https://docs.claude.com/claude-code):

```bash
git clone https://github.com/jackreichert/quality-agents.git
cd quality-agents
bash install.sh
```

Then in any git repo, run `/quality` from Claude Code.

### What it does

`install.sh` deploys:

- 14 agent files into `~/.claude/agents/quality-*.md`
- The `/quality` orchestrator into `~/.claude/commands/quality.md`

Each agent is wired to read its canonical reference from wherever you cloned this repo (the absolute path is substituted in at install time, replacing the `__SKILLS_DIR__` placeholder in the bundled files under `claude/`). Re-running the installer is idempotent — files already up to date are skipped, no backups created.

### Useful flags

```bash
bash install.sh --dry-run             # show what would happen
bash install.sh --force               # overwrite without backups
bash install.sh --link                # link CONSTITUTION.md into Claude/Codex/Copilot (one source, no copies)
bash install.sh --name "Your Name"    # set the Constitution greeting name (with --link; asked if omitted)
bash install.sh --copilot             # (re)generate the self-contained Copilot file [--copilot-prefix F] [--copilot-out F]
bash install.sh --uninstall           # remove deployed files (incl. links)
bash install.sh --skills-dir /path    # canonical docs live elsewhere
bash install.sh --claude-home /path   # non-standard ~/.claude location
bash install.sh --help
```

### One source, every tool — `--link`

`install.sh --link` wires the write-time [`CONSTITUTION.md`](CONSTITUTION.md) into all three assistants from a **single canonical file, with no content copies**:

- **Claude Code** — appends a native `@import` line to `~/.claude/CLAUDE.md` (idempotent).
- **Codex** — symlinks `~/.codex/AGENTS.md` → `CONSTITUTION.md` (an existing real file is backed up first).
- **Copilot (VS Code)** — creates `instructions/CONSTITUTION.instructions.md` (a symlink) and prints the `chat.instructionsFilesLocations` settings snippet to register the folder.

Edit the Constitution once; every tool sees the change. `--uninstall` removes the symlinks and the import line. The one context this can't reach is **github.com's web Copilot**, which only reads in-repo files — commit a copy there if you need it. See [`CONSTITUTION.md`](CONSTITUTION.md) for the rules and `hooks/` for the enforcement hook.

**Personalizing the greeting.** The Constitution's communication-style article carries a `Hey {name}` / `Cheers {name}!` greeting. `--link` asks for the name (or pass `--name "Your Name"`) and writes it in. Re-running preserves the current choice.

**Copilot can't `@import`** — so for Copilot the Constitution has to be *inlined*, not referenced. `--copilot` (re)generates a self-contained Copilot instructions file (your personal prefix via `--copilot-prefix`, then the Constitution inlined) at `instructions/copilot-instructions.md` (gitignored). Re-run it whenever `CONSTITUTION.md` changes to keep Copilot in sync; symlink your IntelliJ/global Copilot file and point VS Code's `github.copilot.chat.codeGeneration.instructions` at it so the refresh propagates. github.com web Copilot still needs a manual re-paste.

### GitHub Copilot & Codex

`install.sh` installs the Claude Code review agents. To also give Copilot and Codex the write-time Constitution, run `install.sh --link --copilot --copilot-prefix <your-prefix>` — it generates a self-contained instructions file (your personal prefix + the Constitution inlined) and points Codex's `~/.codex/AGENTS.md` at it. The installer prints the per-surface wiring (VS Code settings ref, IntelliJ symlink, github.com paste) at the end of a run. See [Multi-tool reach](#multi-tool-reach).

### Contributing

The framework keeps three synchronized copies of every agent (canonical → bundle → deployed). See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the editing flow and the `bundle.sh` script that captures live edits back into the repo.

---

## Files in This Directory

### Current Skills

| File | Focus | Agent file |
|------|-------|-----------|
| `skills/code-quality.md` | Naming, functions, smells, comments, complexity, FP, error handling, performance, structure, formatting | `~/.claude/agents/quality-code-quality.md` |
| `skills/architecture.md` | SOLID, dependency direction, component principles, coupling/cohesion, info hiding, DDD, resilience patterns | `~/.claude/agents/quality-architecture.md` |
| `skills/refactor.md` | Dual-mode: Mode 1 simplify (light) + Mode 2 full Fowler-catalog refactor plan, plus Branch by Abstraction & Strangler Fig | `~/.claude/agents/quality-refactor.md` |
| `skills/review.md` | Confidence-scored code review with quick, full-PR, and targeted-follow-up modes; Google design-first priority | `~/.claude/agents/quality-review.md` |
| `skills/security-review.md` | Adversarial security review using OWASP Top 10, CWE, and selected OWASP ASVS control families | `~/.claude/agents/quality-security-review.md` |
| `skills/test-quality.md` | F.I.R.S.T., AAA, naming, test doubles, xUnit Pattern smells, coverage; GOOS Listen-to-the-Tests as organizing principle | `~/.claude/agents/quality-test-quality.md` |
| `skills/delivery.md` | CD pipeline readiness, trunk-based dev, 12-Factor compliance, feature flags, expand-contract migrations, observability prereqs | `~/.claude/agents/quality-delivery.md` |
| `skills/distributed.md` | Waldo's four differences, replication/consistency, idempotency, partitioning, microservice boundaries, CQRS/ES tradeoffs | `~/.claude/agents/quality-distributed.md` |
| `skills/patterns.md` | GoF + HFDP pattern recognition vocabulary, anti-patterns (Singleton/Visitor abuse), modern alternatives | `~/.claude/agents/quality-patterns.md` |
| `skills/persistence.md` | PEAA pattern catalog: Active Record vs Data Mapper, Unit of Work, Repository, Lazy Load + N+1, transactions, migrations | `~/.claude/agents/quality-persistence.md` |
| `skills/gates.md` | Objective tool-measured floor: lint, cyclomatic complexity, function length, duplication, coverage, mutation score, CRAP — runs tools and reports pass/fail vs explicit thresholds | `~/.claude/agents/quality-gates.md` |
| `skills/specification.md` | Acceptance-criteria / BDD feature-file quality: key examples, declarative phrasing, ubiquitous language, executable & living specs, acceptance-level mutation | `~/.claude/agents/quality-specification.md` |
| _cross-cutting: `security-review` + `distributed` + `persistence` + `code-quality`_ | Flow tracing — control + data flow from entry points to sinks: taint (source→sink), error propagation, resource/transaction lifecycle, N+1-across-chain, cross-boundary partial failure. Runs as Phase 2 of `/quality deep`; standalone via `/quality flow` | `~/.claude/agents/quality-flow.md` |

### Workflow & Supporting Docs

| File | Focus | Agent file |
|------|-------|-----------|
| `README.md` | Sources, lineage, exclusions, and update guide for this framework | — |
| `skills/process.md` | Planning discipline: pre-flight (edge cases, deps, alternatives) + post-validation (Big-O, requirements, assumptions) | `~/.claude/agents/quality-process.md` |
| `CONSTITUTION.md` | Write-time prevention layer — the skills distilled into always-on imperative rules, a conflict-precedence order, numeric gate thresholds, and a Definition of Done. Loaded via a `CLAUDE.md` `@`-import. | — |
| `hooks/pre-commit` | Opt-in git hook that runs the fast gates (lint + complexity) on staged files and blocks the commit on a breach. See `hooks/README.md`. | — |

### Two modes: review-time and write-time

The framework now works at both ends of the change lifecycle:

- **Review-time (catch).** `/quality` routes a diff to the relevant reading agents, which *judge* the code against the canon and report severity-ranked findings. This is the original framework.
- **Write-time (prevent).** [`CONSTITUTION.md`](CONSTITUTION.md) compiles the same canon into terse always-on rules an agent obeys *while writing* — so issues are designed out, not just flagged. Import it into a project's `CLAUDE.md` with `@/path/to/Code-Quality-Skills/CONSTITUTION.md`.
- **Enforcement (block).** `/quality gates` and the [`hooks/pre-commit`](hooks/) hook turn the qualitative rules into objective, tool-measured pass/fail gates (lint, complexity, duplication, coverage, mutation) — the floor beneath the reading agents. The agents opine; the gates measure.

This mirrors the lesson of [unclebob/swarm-forge](https://github.com/unclebob/swarm-forge): the same distilled discipline should run as a *constitution* up front and as *enforced gates*, not only as post-hoc review.

### Lineage Notes

| Current file | Lineage |
|--------------|---------|
| `skills/review.md` | Started from the `code-reviewer` agent and absorbed the old `review-pr` orchestrator workflow |
| `skills/refactor.md` | Synthesized from Fowler/Feathers and absorbed the old `code-simplifier` behavior-preserving cleanup mode |
| `skills/process.md` | Built from Jack's CLAUDE.md "Planning Process" section, grounded in Code Complete + Pragmatic Programmer + Clean Coder + MMM + APOSD |
| `skills/delivery.md` | Synthesized fresh from Continuous Delivery + Trunk-Based Development + 12-Factor + Feature Toggles (Hodgson) — no prior agent ancestor |
| `skills/distributed.md` | Synthesized fresh from DDIA + Waldo's "A Note on Distributed Computing" + Microservices/CQRS/Event Sourcing — no prior agent ancestor |
| `skills/patterns.md` | Synthesized fresh from GoF + Head First Design Patterns + Effective Java refinements + APOSD ch.19 counterweight — no prior agent ancestor |
| `skills/persistence.md` | Synthesized fresh from PEAA pattern catalog + DDIA storage chapters + Effective Java resource-management items + DDD Repository — no prior agent ancestor |
| `skills/security-review.md` | Adapted from the `security-auditor` agent and extended with explicit security standards references |

### Orchestration

| Path | Purpose |
|------|---------|
| `~/.claude/commands/quality.md` | The `/quality [aspects]` command — routes to agents, aggregates findings (Claude Code) |
| `instructions/` (generated, gitignored) | Self-contained inlined instructions (vendor prefix + Constitution) for tools that can't `@import` — Codex & Copilot, via `install.sh --copilot` |
| `install.sh --link` / `--copilot` | Wires the Constitution into Claude (import), Codex (symlink), and Copilot (inlined file) from one source |

### Multi-tool reach

The **review framework** (`/quality` — parallel agents, diff-routing, severity aggregation, tool-backed SAST/SCA) is **Claude Code only**: it relies on slash-command orchestration and tool execution that Copilot and Codex don't offer.

The **write-time [Constitution](CONSTITUTION.md)** reaches all three from a single source (`install.sh --link`):

| Tool | How it gets the Constitution | `/quality` review agents? |
|------|------------------------------|---------------------------|
| **Claude Code** | native `@import` in `~/.claude/CLAUDE.md` — live | ✅ full |
| **Codex** | `~/.codex/AGENTS.md` → self-contained inlined file (vendor HIPAA + Constitution) | ❌ |
| **Copilot** (VS Code / IntelliJ / github.com) | self-contained inlined file via settings ref / symlink / paste | ❌ |

Claude resolves `@import` live, so editing `CONSTITUTION.md` updates it instantly. Codex and Copilot can't reference an external file that way, so `install.sh --copilot` generates a **self-contained** file — a personal prefix (including company HIPAA) followed by the Constitution inlined — that both point at; re-run it after the Constitution changes. github.com web Copilot can't reach external files at all, so it takes a manual paste.

> **Company HIPAA lives *inline* in each tool's instructions** (Claude's `CLAUDE.md`; the self-contained file for Codex/Copilot) — never delegated to the imported Constitution — so the mandate survives even where `@import` doesn't resolve.

---

## Sources by Skill

Below: the books, articles, and chapters that drove each skill's content. Citations also appear inline next to the specific sections they informed.

### `skills/code-quality.md`

**Books**
- **Clean Code** — Robert C. Martin (2008)
  - ch.2 Meaningful Names → Naming section
  - ch.3 Functions → Function Design section
  - ch.4 Comments → Comments section
  - ch.5 Formatting → Formatting section
  - ch.7 Error Handling → Error Handling section
  - ch.12 Emergence → Beck's Four Rules of Simple Design
  - ch.17 Smells and Heuristics → Code Smells section (cross-checked with Fowler)
- **A Philosophy of Software Design** — John Ousterhout (2018/2021)
  - ch.2 Nature of Complexity → Complexity section
  - ch.4-5 Modules should be deep, Information hiding → Function Design / Complexity sections
  - ch.10 Define Errors Out of Existence → Error Handling section
  - ch.12-15 Comments → Tensions & Comments sections (counterpoint to Clean Code ch.4)
  - ch.13-14 Comments, Choosing Names → Comments / Naming sections
- **Clean Architecture** — Robert C. Martin (2017)
  - ch.6 Functional Programming → FP section (the three-paradigm framing)
- **Refactoring 2nd ed.** — Martin Fowler (2018)
  - ch.3 Bad Smells in Code → Code Smells categories (Bloaters, OO Abusers, Change Preventers, Dispensables, Couplers)
- **Code Complete 2nd ed.** — Steve McConnell (2004)
  - ch.5-7 Construction practices → Function Design / Naming
  - ch.25 Code-Tuning Strategies → Performance section
  - ch.31 Layout and Style → Formatting section
- **The Art of Readable Code** — Boswell & Foucher (2011) → Naming section surface clarity
- **The Pragmatic Programmer** — Hunt & Thomas (1999/2019)
  - DRY, fail fast → Code Smells / Error Handling
  - ch.4 Design by Contract → Structure & Contracts section

**Articles & Papers**
- **Out of the Tar Pit** — Moseley & Marks (2006) — essential vs. accidental complexity, FP+relational core → Complexity / FP sections
- **Extreme Programming Explained** — Kent Beck — Four Rules of Simple Design (cited via Clean Code ch.12)

**Note:** Release It! stability patterns moved to `skills/architecture.md` (resilience is an architectural decision, not code-quality polish). Code-quality surfaces the symptoms; architecture prescribes the patterns.

---

### `skills/architecture.md`

**Books**
- **Clean Architecture** — Robert C. Martin (2017)
  - Part III chs.7-11 SOLID Principles → SOLID section
  - Part IV chs.13-14 Component Principles → Component Principles section (REP, CCP, CRP, ADP, SDP, SAP)
  - Part V ch.22 The Clean Architecture → Dependency Architecture section (the layered diagram)
- **Domain-Driven Design** — Eric Evans (2003)
  - Part II Building Blocks → DDD Patterns section (aggregates, repositories, domain services)
  - Part III Refactoring Toward Deeper Insight → Ubiquitous Language
  - Part IV Strategic Design → Bounded Contexts, Anti-Corruption Layer
- **Patterns of Enterprise Application Architecture** — Martin Fowler (2002)
  - ch.1 Layering → Layering Violations section
- **Software Engineering at Google** — Winters, Manshreck, Wright (2020)
  - ch.1 Hyrum's Law → Hyrum's Law subsection (API stability lens)
  - ch.3 Knowledge Sharing, dependency management chapters → Coupling & Cohesion section
- **Release It! 2nd ed.** — Michael T. Nygard (2018)
  - ch.4 Stability Antipatterns → Resilience & Stability Patterns section (antipatterns to flag)
  - ch.5 Stability Patterns → Resilience & Stability Patterns section (Timeout, Circuit Breaker, Bulkhead, Steady State, Fail Fast, Backpressure, Shed Load)
- **Domain-Driven Design** (Evans 2003)
  - Part IV ch.15 Distillation → Strategic DDD subsection (Core / Generic / Supporting subdomains)
- **Clean Architecture** — Robert C. Martin (2017)
  - ch.21 Screaming Architecture → Screaming Architecture subsection

**Articles & Papers**
- **"On the Criteria to Be Used in Decomposing Systems into Modules"** — D.L. Parnas (1972) → Information Hiding section
- **The Principles of OOD** (SOLID articles) — Robert C. Martin (blog.cleancoder.com) → SOLID section
- **Hexagonal Architecture (Ports and Adapters)** — Alistair Cockburn (alistair.cockburn.us) → Hexagonal Architecture subsection (sibling of Clean Architecture)
- **"How Do Committees Invent?"** — Melvin Conway (1968) → Conway's Law subsection
- **Team Topologies** — Matthew Skelton & Manuel Pais (2019) → Conway's Law subsection (Inverse Conway Maneuver)

---

### `skills/refactor.md`

**Books**
- **Refactoring: Improving the Design of Existing Code 2nd ed.** — Martin Fowler (2018)
  - ch.3 Bad Smells → Smell → Refactoring Map
  - ch.6-10 Composing Methods, Encapsulation, Moving Features, Organizing Data, Simplifying Conditional Logic → Smell→Move tables
  - ch.11 Refactoring APIs → Refactoring APIs section (Separate Query from Modifier, Parameterize Function, Remove Flag Argument, Preserve Whole Object, Replace Constructor with Factory Function, Replace Function with Command)
  - ch.8 Replace Loop with Pipeline → Refactoring APIs section
  - ch.12 Dealing with Inheritance → Inheritance Smell→Move table
- **Working Effectively with Legacy Code** — Michael Feathers (2004)
  - Seams (Object/Parameter/Interface) → Legacy Code Strategy section
  - Characterization tests → Legacy Code Strategy section
  - Sprout Method, Wrap Method → Legacy Code Strategy section
  - **ch.25 Dependency-Breaking Techniques** → Dependency-Breaking Techniques catalog (24 named techniques: Subclass and Override Method, Extract and Override Call/Factory/Getter, Parameterize Method/Constructor, Adapt Parameter, Extract Interface/Implementer, Encapsulate Global Reference, Introduce Static Setter, Pull Up Feature, Push Down Dependency, Supersede Instance Variable, Introduce Instance Delegator, Break Out Method Object, Link Substitution, Definition Completion, Template/Text Redefinition, Replace Function with Function Pointer, ranked by invasiveness)
- **Clean Code** — Robert C. Martin (2008) — ch.17 Smells (cross-references Fowler's catalog)

**Articles**
- **BranchByAbstraction** — Fowler / Hammant (martinfowler.com bliki) → Large-Scale Refactor Strategies (in-process replacement)
- **Strangler Fig Application** — Fowler (martinfowler.com bliki) → Large-Scale Refactor Strategies (system-level replacement)
- **Things You Should Never Do, Part I** — Joel Spolsky → motivation for Strangler Fig over big-bang rewrites

**Lineage**
- Mode 1 ("simplify") is the successor to the old `code-simplifier` agent pattern: behavior-preserving cleanup on recently touched code
- Mode 2 ("full-refactor") is the deeper Fowler/Feathers refactoring path

---

### `skills/test-quality.md`

**Books**
- **Growing Object-Oriented Software, Guided by Tests** — Freeman & Pryce (2009)
  - **ch.18 Listening to the Tests → Listen to the Tests section (organizing principle of the whole skill)**
  - Mock roles, not objects → Test Doubles section
  - Outside-in TDD, Walking Skeleton → TDD Indicators section
- **Test-Driven Development: By Example** — Kent Beck (2002)
  - Red-Green-Refactor cycle, baby steps, Three Laws of TDD → TDD Indicators section
- **The Art of Unit Testing 3rd ed.** — Roy Osherove (2023)
  - F.I.R.S.T. principles → F.I.R.S.T. section
  - AAA pattern → Structure section
  - Test double taxonomy (Stub, Mock, Spy, Fake, Dummy) → Test Doubles section
- **xUnit Test Patterns: Refactoring Test Code** — Gerard Meszaros (2007)
  - Test smell catalog → Test Smells section (Obscure, Eager, Mystery Guest, Fragile, Slow, Flaky, Hard-Coded Test Data, Irrelevant Information, Shared Fixture)
- **Software Engineering at Google** — Winters et al. (2020)
  - ch.11 The Beyoncé Rule → Beyoncé Rule subsection ("if you liked it, then you shoulda put a test on it")
  - chs.11-14 Testing → Coverage Analysis + Test Pyramid sections
- **Clean Code** — Robert C. Martin (2008) — ch.9 Unit Tests → F.I.R.S.T. section (overlap with Osherove)
- **Growing Object-Oriented Software, Guided by Tests** — Freeman & Pryce (2009)
  - **ch.19 Coverage** → Mutation Testing subsection (test quality, not just coverage)
- **The Pragmatic Programmer** — Hunt & Thomas (1999/2019)
  - ch.7 (QuickCheck lineage referenced) → Property-Based Testing subsection

**Articles & Concepts**
- **Test Pyramid** — Mike Cohn, *Succeeding with Agile* (2009) → Test Pyramid subsection
- **Testing Trophy** — Kent C. Dodds (kentcdodds.com) → Testing Trophy variant (frontend-heavy contexts)

---

### `skills/delivery.md`

**Books**
- **Continuous Delivery** — Humble & Farley (2010)
  - ch.5 Anatomy of the Deployment Pipeline → Build Discipline + Deployment Strategy sections
  - ch.6 Build and Deployment Scripting → Build Discipline section
  - ch.10 Deploying and Releasing → Deployment Strategy section
  - ch.12 Managing Data → Database Migrations (Expand-Contract) section
  - ch.13 Managing Components and Dependencies → Dependencies & Supply Chain section
  - ch.14 Advanced Version Control → Trunk-Based Development Hygiene section
- **Accelerate: The Science of Lean Software and DevOps** — Forsgren, Humble, Kim (2018)
  - DORA research → DORA Four Key Metrics subsection (deploy frequency, lead time, change failure rate, MTTR)
- **Software Engineering at Google** — Winters et al. (2020)
  - chs.16, 22-24 (Version Control, LSCs, CI, CD) → Trunk-Based Development + Build Discipline + Deployment Strategy
- **Release It! 2nd ed.** — Nygard (2018) ch.13 (Design for Deployment) → Deployment Strategy section
- **Growing Object-Oriented Software, Guided by Tests** — Freeman & Pryce (2009)
  - ch.4 Walking Skeleton → Walking Skeleton (§ 0) section
- **The Pragmatic Programmer** — Hunt & Thomas (1999/2019)
  - ch.2 Tracer Bullets → Walking Skeleton (§ 0) section

**Articles & Standards**
- **Trunk Based Development** — Fowler / Hammant → Trunk-Based Development Hygiene section
- **The Twelve-Factor App** — Heroku/Wiggins → Configuration & Environment + Process Hygiene + Logs & Telemetry sections
- **Feature Toggles** — Pete Hodgson on Fowler's site → Feature Flags section (the four-category taxonomy: release / experiment / ops / permission)
- **DORA State of DevOps Reports** (annual, dora.dev) → DORA Four Key Metrics subsection (elite/high/medium/low tiers)

### `skills/distributed.md`

**Books**
- **Designing Data-Intensive Applications** — Martin Kleppmann (2017)
  - ch.5 Replication → Replication & Consistency section
  - ch.6 Partitioning → Partitioning section
  - ch.7 Transactions → Transactions & Isolation section
  - ch.8 The Trouble with Distributed Systems → Network Reliability + Time/Clocks/Ordering sections
  - ch.9 Consistency and Consensus → Replication & Consistency section
  - ch.11 Stream Processing → Idempotency and Exactly-Once + CQRS / Event Sourcing sections
- **Release It! 2nd ed.** — Nygard (2018) → Stability Patterns at Distributed Scale (cross-ref skills/architecture.md § 5)
- **Software Engineering at Google** — Winters et al. (2020) ch.14 → Observability for Distributed Systems

**Articles & Papers**
- **A Note on Distributed Computing** — Waldo, Wyant, Wollrath, Kendall (1994) → § 0 Waldo's Four Differences (organizing principle)
- **Microservices** — Fowler & Lewis (martinfowler.com) → Microservice Boundaries section
- **CQRS** — Fowler (martinfowler.com) → CQRS / Event Sourcing section
- **Event Sourcing** — Fowler (martinfowler.com) → CQRS / Event Sourcing section

### `skills/patterns.md`

**Books**
- **Design Patterns: Elements of Reusable Object-Oriented Software** — Gamma, Helm, Johnson, Vlissides / GoF (1994)
  - The 23 patterns by category → § 2 The 23 GoF Patterns + § 1 Pattern Recognition by Smell
  - Foundational principles (program-to-interface, composition-over-inheritance) → § 0 The Pattern Mindset
- **Head First Design Patterns 2nd ed.** — Freeman & Robson (2020)
  - ch.12 Compound Patterns → § 2.5 MVC = Strategy + Composite + Observer (and MVP/MVVM/Flux variants)
  - Modern OO framing throughout, anti-pattern warnings
- **Patterns of Enterprise Application Architecture** — Fowler (2002)
  - Web Presentation Patterns chapter → § 2.6 Web Presentation Patterns (Page/Front Controller, Template/Transform/Two-Step View, Application Controller)
- **Refactoring 2nd ed.** — Fowler (2018) → Smell→Pattern mapping (Replace Conditional with Polymorphism = Strategy/State)
- **Effective Java 3rd ed.** — Bloch (2018) → Modern OO refinements (item 17 immutability, item 18 composition-over-inheritance)
- **A Philosophy of Software Design** — Ousterhout (2018/2021) ch.19 → § 5 When NOT to Apply a Pattern (counterweight on over-patterning)

### `skills/persistence.md`

**Books**
- **Patterns of Enterprise Application Architecture** — Martin Fowler (2002)
  - ch.2 Organizing Domain Logic → Domain Logic Pattern section (Transaction Script vs Domain Model vs Table Module)
  - ch.3, 10-11 Mapping to Relational + ORM Behavioral patterns → Active Record vs Data Mapper, Unit of Work, Identity Map, Lazy Load sections
  - ch.5 Concurrency → Transactions and Boundaries section
  - **Offline Concurrency Patterns chapter** → § 6.5 Offline Concurrency Patterns (Optimistic / Pessimistic Offline Lock, Coarse-Grained Lock, Implicit Lock)
  - PEAA inheritance mapping (STI / CTI / Concrete Table) → Inheritance Mapping section
  - PEAA Repository, Query Object → Repository Pattern section
- **Designing Data-Intensive Applications** — Kleppmann (2017)
  - ch.2 Data Models and Query Languages → cross-ref for relational vs document
  - ch.3 Storage and Retrieval → Query Patterns and SQL Hygiene section
  - ch.7 Transactions → Transactions and Boundaries section
- **Effective Java 3rd ed.** — Bloch (2018) items 7-9 → Connection & Resource Management section
- **Domain-Driven Design** — Evans (2003) → Repository pattern grounding

### `skills/process.md`

**Books**
- **Code Complete 2nd ed.** — Steve McConnell (2004)
  - ch.3 Measure Twice, Cut Once → Pre-Flight checks 1, 5
  - ch.5 Design in Construction → Pre-Flight check 2
  - ch.8 Defensive Programming → Pre-Flight check 3 (edge cases)
  - ch.25-26 Code-Tuning → Post-Validation check 8 (Big-O)
- **The Pragmatic Programmer** — Hunt & Thomas (1999/2019)
  - ch.2 Tracer Bullets → Pre-Flight check 1
  - ch.4 Pragmatic Paranoia, Design by Contract → Pre-Flight check 3 + Post-Validation check 9
  - ch.5 Decoupling → Pre-Flight check 4 (blast radius)
- **The Clean Coder** — Robert C. Martin (2011)
  - **chs.2-3 Saying No / Saying Yes** → Commitment Discipline section (specific objections vs. silent overcommitment; "I will + date" vs. "soon")
  - ch.7 Acceptance Testing → Post-Validation check 6
  - ch.10 Estimation → Pre-Flight check 5
- **The Mythical Man-Month** — Fred Brooks (1975/1995)
  - ch.2 Brooks's Law → Principles Behind These Checks
  - ch.7 Why Did the Tower of Babel Fail → Pre-Flight check 4 (dependencies/communication)
  - ch.16 No Silver Bullet → Principles (essence vs. accident)
- **A Philosophy of Software Design** — John Ousterhout (2018/2021)
  - ch.11 Design It Twice → Pre-Flight checks 2, 5

**Articles & Papers**
- **Painless Software Schedules** — Joel Spolsky → Pre-Flight check 5 (estimation discipline; weak signal in this skill but cited)
- **Out of the Tar Pit** — Moseley & Marks (2006) → Principles (essential vs. accidental complexity)

**Lineage:** Built from Jack's CLAUDE.md "Planning Process" section. The 9 checks (5 pre-flight + 4 post-validation) map directly to that source.

---

### `skills/review.md`

**Articles**
- **Code Review Developer Guide** — Google Engineering Practices (CC BY 3.0) → Review Priority Order section (design > functionality > complexity > tests > naming > comments > style)
- **The Standard of Code Review** — Google Engineering Practices → "net positive over current state, not perfection" framing
- **What to Look For in a Code Review** — Google Engineering Practices → ranked review dimensions
- **The CL Author's Guide / Small CLs** — Google Engineering Practices → CL-size guidance (≤200 sweet spot, >400 split, refactor + feature in separate CLs)

**Lineage**
- `code-reviewer` agent from `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/pr-review-toolkit/agents/code-reviewer.md`
- `review-pr` orchestrator from `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/pr-review-toolkit/commands/review-pr.md`

**Pattern:** Confidence-scored review (≥80 threshold), CLAUDE.md-driven, bug detection + general code quality, plus merged PR-review orchestration modes (`quick`, `full-pr`, `targeted-follow-up`).

**Agent files**: `quality-review.md` and `quality-security-review.md` were derived from these canonical skills and now exist at `~/.claude/agents/`.

---

### `skills/security-review.md`

**Source:** `security-auditor` agent from `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/code-modernization/agents/security-auditor.md`

**Pattern:** Adversarial OWASP/CWE review with exploit scenarios. Backed today by:
- **OWASP Top 10:2021** (web application security risks)
  - A01 Broken Access Control, A02 Cryptographic Failures, A03 Injection, A05 Security Misconfiguration, A06 Vulnerable Components, A07 Identification/Auth Failures, A10 SSRF → existing systematic checklist
  - **A04 Insecure Design** → architectural threat-modeling subsection (trust boundaries, abuse cases, secure design patterns, no security-by-obscurity, defense in depth)
  - **A08 Software/Data Integrity Failures** → supply chain subsection (pinned deps + lockfile review, signed artifacts, CI/CD trust boundaries, SBOM)
  - **A09 Security Logging/Monitoring Failures** → detection subsection (auth events, sensitive ops, failed-access logging, log integrity, retention, alert routing)
- **Selected OWASP ASVS control families** for code-review-relevant checks (authentication, session management, access control, validation, crypto, configuration, logging)
- **CWE catalog** (Common Weakness Enumeration)
- **SAST**: Semgrep (OWASP Top 10 + secrets + security-audit rulesets), CodeQL for deep taint analysis, plus language-specific scanners (Bandit, ESLint-security, gosec, Brakeman, SpotBugs+find-sec-bugs)
- **SCA**: `npm audit`, `pip-audit`, `govulncheck`, `bundle audit`, OWASP Dependency-Check, Trivy
- **Secrets scanning**: gitleaks, trufflehog
- **IaC scanning**: checkov, tfsec, trivy config

**Tool stance:** tools are recommended, not required. Their absence is *not blocking* — the review proceeds via manual code reading. But missing/failed tools must be called out explicitly so the coverage profile is visible to the reader.

---

### `skills/gates.md`

**Pattern:** The objective, tool-measured floor beneath the reading agents — the enforceable form of judgments the other skills make qualitatively. Backed by:
- **Continuous Delivery** (Humble & Farley) — automated quality gates in the deployment pipeline
- **A Philosophy of Software Design** ch.19 (Ousterhout) — complexity as the thing to measure; **Clean Code** function-size/complexity heuristics
- **Software Engineering at Google** chs.11, 20 — coverage and static analysis at scale
- **GOOS** ch.19 — mutation testing as the test-quality oracle
- **CRAP** metric — Savoia & Evans (2007), `crap4j` (see `Resources/Originals/Citations/Articles.md`); the one gate sourced outside the book canon, included because it measures the complex-*and*-undertested interaction nothing else in the set catches
- Enforceable-gate framing adapted from the constitution/engineering model in [unclebob/swarm-forge](https://github.com/unclebob/swarm-forge)

### `skills/specification.md`

**Source:** Synthesized fresh — no prior agent ancestor. The layer upstream of `test-quality.md`: spec quality before code.
- **Specification by Example** (Adzic, 2011) — the seven process patterns, key-example discipline, living documentation (`Resources/Books/Testing/28-Specification-by-Example.md`)
- **BDD / Given-When-Then** (Dan North) + **The Cucumber Book** (Wynne & Hellesøy) — Gherkin structure
- **The Clean Coder** ch.8 + **Continuous Delivery** ch.8 — acceptance tests as executable specifications
- **Domain-Driven Design** (Evans) — ubiquitous language
- Acceptance-level (Gherkin) mutation adapted from `gherkin-mutator` in [unclebob/swarm-forge](https://github.com/unclebob/swarm-forge)

---

## What's Deliberately Not Synthesized

The master resource list (`../CS-Best-Practices-Resources.md`) includes books that are **listed for context but did not deeply drive any skill's synthesis**. Each row links to the resource summary in `Resources/` for reference.

| Source | Why not (yet) integrated | Summary |
|--------|--------------------------|---------|
| **SICP** | Foundational/educational; principles already filter through Clean Code, FP basics, and the patterns skill | [Resources/Books/Language-Specific/24-SICP.md](Resources/Books/Language-Specific/24-SICP.md) |
| **NASA's Power of 10 Rules** | Safety-critical-C focus; overlaps with code-quality but not a full skill | [Resources/Standards/04-NASA-Power-of-10.md](Resources/Standards/04-NASA-Power-of-10.md) |

### Recently absorbed into new skills

The 4 new skills (delivery, distributed, patterns, persistence) closed many gaps that previously appeared here:

| Source | Now in skill |
|--------|--------------|
| **Continuous Delivery** (Humble & Farley) | `skills/delivery.md` — Build Discipline, Deployment Pipeline, Migrations |
| **Trunk Based Development** (Fowler / Hammant) | `skills/delivery.md` — Trunk-Based Development Hygiene section |
| **Twelve-Factor App** | `skills/delivery.md` — Configuration, Process Hygiene, Logs sections |
| **Feature Toggles** (Hodgson via Fowler) | `skills/delivery.md` — Feature Flags section (4-category taxonomy) |
| **Designing Data-Intensive Applications** (Kleppmann) | `skills/distributed.md` (chs.5-9, 11) + `skills/persistence.md` (chs.2-3, 7) |
| **A Note on Distributed Computing** (Waldo et al. 1994) | `skills/distributed.md` § 0 — organizing principle |
| **Microservices** (Fowler & Lewis) | `skills/distributed.md` — Microservice Boundaries section |
| **CQRS, Event Sourcing** (Fowler) | `skills/distributed.md` — CQRS / Event Sourcing section |
| **Design Patterns / GoF** | `skills/patterns.md` — full vocabulary, smell→pattern map, anti-patterns |
| **Head First Design Patterns** | `skills/patterns.md` — modern OO framing, anti-pattern warnings |
| **PEAA pattern catalog** (Active Record, Data Mapper, Unit of Work, Repository, Lazy Load) | `skills/persistence.md` — full catalog application |
| **Effective Java** | Partial — items 7-9 (resources) in `skills/persistence.md`; items 17-18 (composition) in `skills/patterns.md`. The full 90 items remain language-specific and aren't a standalone skill |

### Already partially absorbed (from earlier work)

| Source | Where it appears |
|--------|------------------|
| **Mythical Man-Month** (Brooks) | `skills/process.md` — Brooks's Law, blast radius, essence vs. accident |
| **Joel on Software** — *Painless Software Schedules* | `skills/process.md` — estimation discipline |
| **Joel on Software** — *Things You Should Never Do* | `skills/refactor.md` — motivates Strangler Fig |
| **Branch by Abstraction**, **Strangler Fig** (Fowler bliki) | `skills/refactor.md` — Large-Scale Refactor Strategies section + `skills/delivery.md` cross-ref |
| **Google Engineering Practices** | `skills/review.md` — Review Priority Order, CL-size guidance |
| **GOOS** ch.18 *Listening to the Tests* | `skills/test-quality.md` — organizing principle |
| **Release It!** | `skills/architecture.md` § 5 (resilience patterns) + `skills/distributed.md` § 10 cross-ref |

---

## How to Update

When extending or revising a skill:

1. **Edit the Obsidian file in this directory** — that's the canonical source of truth
2. **Mirror the change in the corresponding agent file** at `~/.claude/agents/quality-*.md` — keep agent files concise; full reasoning lives here
3. **If adding a new source**, update both:
   - The skill's "Sources" line at the top of its file
   - This README's "Sources by Skill" section
4. **If adding a new aspect to the orchestrator**, update `~/.claude/commands/quality.md`'s aspect routing table and tips section

---

## Worked Example: A Full `/quality` Session

A walkthrough so you (or future-you in 3 months) can re-orient.

### Scenario
You just finished a feature: added an `/api/users/:id/orders` endpoint that fetches a user's orders. Files changed:
- `src/routes/users.ts` (new endpoint handler)
- `src/services/orderService.ts` (new method `getOrdersForUser`)
- `src/services/orderService.test.ts` (one new test)

### Step 1 — Ready to commit, run the default
```
/quality
```

The orchestrator:
1. Runs `git rev-parse --is-inside-work-tree` → confirms git repo
2. Runs `git diff` and `git diff --name-only` → identifies the three changed files
3. Auto-selects agents based on detectable signals:
   - `quality-code-quality` (always, source files changed)
   - `quality-architecture` (new function/endpoint adds structural surface)
   - `quality-test-quality` (test file in diff)
   - `security-auditor` (file in `routes/` path)
   - `quality-refactor` Mode 1 (last, polish pass)
4. Spawns all 5 in parallel via `Task`
5. Each returns severity-tagged findings
6. Orchestrator deduplicates, normalizes severity, aggregates

### Step 2 — Read the report

Hypothetical output:
```
## Critical — Fix Before Committing
- [security-auditor] src/routes/users.ts:18 — IDOR: no ownership check;
  user A can fetch user B's orders by changing the path param

## Important — Fix Before PR
- [quality-test-quality] orderService.test.ts:42 — only happy path tested;
  missing test for non-existent userId
- [quality-architecture] orderService.ts:15 — direct DB import in service
  layer; should go through repository

## Minor — Worth Doing
- [quality-code-quality] orderService.ts:23 — variable `data` is vague;
  rename to `userOrders`

Counts: Critical: 1 | Important: 2 | Minor: 1
Verdict: SIGNIFICANT ISSUES
```

### Step 3 — Fix Critical, re-run

Add the ownership check, re-run `/quality`. If now `NEEDS WORK`, fix the Importants and re-run. When `SHIP IT`, commit.

### Step 4 — Optional: targeted follow-ups

Want named refactoring moves for the architecture finding?
```
/quality refactor
```

Mode 2 returns specific Fowler moves (e.g., "Extract Repository — mechanics: ...").

---

## Smoke Test Recipe

Before relying on `/quality` for anything important, run it once on a low-stakes diff to confirm everything wires up.

```bash
# In any git repo with some uncommitted changes:
cd ~/some-test-repo

# Make a trivial change — anything that produces a diff:
echo "// test comment" >> src/some-file.ts

# Run the framework:
# (in Claude Code session)
/quality
```

**Expected:**
- Orchestrator detects the change
- Agents spawn (you'll see "◆ Spawning agents in parallel...")
- Each returns a report
- Aggregated output with verdict appears
- Verdict on a trivial comment-only change should be `SHIP IT` or maybe one Minor finding

**If it doesn't work:**
- Agent fails to spawn → check `~/.claude/agents/quality-*.md` exists
- Orchestrator says "no diff found" but you have changes → check `git status`
- Output format looks broken → see Troubleshooting below

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `/quality` not recognized | Command file missing or permission issue | `ls ~/.claude/commands/quality.md` — recreate if missing |
| Orchestrator asks for files instead of using diff | Not a git repo OR no changes | `git status` — confirm you're in a repo with uncommitted work |
| Agent returns nothing useful | Diff is empty or trivial | Verify `git diff` shows substantive changes |
| Agent times out | Diff too large | Run targeted aspect on subset: `/quality code` on specific file |
| Severity counts don't match findings | Some agent didn't tag severity inline | Check that agent file has the `[CRITICAL]/[IMPORTANT]/[MINOR]` tagging instruction |
| Security findings get swallowed | CVSS not normalizing correctly | Check the orchestrator's severity-normalization table — `~/.claude/commands/quality.md` |
| Output is severity-grouped but I want category-grouped | Default is severity-grouped (orchestrator); per-agent reports are category-grouped | Run agents directly via `Task` tool for per-agent category view |
| Agents disagree about a finding | Expected — different lenses | Orchestrator preserves the most severe rating during deduplication |

If output is consistently broken, smoke-test a single agent directly via the `Task` tool to isolate whether the bug is in the orchestrator or the agent.

---

## GSD Integration

`/quality` composes naturally with the GSD workflow. Recommended insertion points:

| GSD command | When to add `/quality` | Why |
|-------------|------------------------|-----|
| Between `/gsd:execute-phase` and `/gsd:commit-phase` | Run `/quality` on the phase's changes | Catches issues before atomic phase commit |
| Before `/gsd:ship` | Run `/quality code arch tests security` | Comprehensive pre-PR review |
| After `/gsd:verify-work` validates UAT criteria | Run `/quality process` | Audits planning discipline retroactively |

**Not yet integrated automatically** — these are manual additions to your workflow. If the integration becomes standard practice, candidates for automation:
- Add `/quality` invocation to `gsd-verifier`'s checklist
- Add a workflow toggle in `planning/config.json`: `workflow.quality_gate: true`

For now, run `/quality` manually at the points above. If you find yourself doing it consistently, that's the signal to automate.

---

*Maintainer: Jack. Created 2026-05-01. Update whenever the framework grows.*
