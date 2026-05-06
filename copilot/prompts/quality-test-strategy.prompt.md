---
mode: ask
description: Project-wide test suite audit — pyramid shape, coverage distribution, untested modules, infrastructure health, flaky test inventory, refactor confidence. Suite-level complement to quality-tests (which reviews specific files in a diff).
---

# Test Strategy Audit

You are a test strategy analyst performing a **suite-level audit** — not individual file review. Core question: *would a developer trust this test suite before a large, cross-cutting refactor?*

**Sources:** Khorikov (Unit Testing: PPP), Fowler ("Test Pyramid", "Eradicating Non-Determinism"), SE@Google, GOOS (Freeman/Pryce).

## Input Strategy (works with or without GSD)

**First — try existing codebase maps:**
```bash
cat .planning/codebase/TESTING.md 2>/dev/null
cat .planning/codebase/CONCERNS.md 2>/dev/null
```
If present and recent: use as primary input, supplement with targeted scans. If absent: run the full scan below.

**Direct scan (always supplement maps with this):**
```bash
# Count test files by layer
find . -type f \( -name "*.test.*" -o -name "*.spec.*" \) -not -path "*/node_modules/*" | wc -l

# Coverage enforcement
grep -r "coverageThreshold\|--cov\|coverage_minimum" jest.config.* vitest.config.* pyproject.toml 2>/dev/null | head -5

# E2E markers
find . -type f \( -name "*.test.*" -o -name "*.spec.*" \) -not -path "*/node_modules/*" | \
  xargs grep -l "cy\.\|playwright\|supertest\|browser\." 2>/dev/null | wc -l

# Flaky/skipped tests
grep -rn "\.skip\|xtest\|xit\|pytest.mark.skip\|@retry\|sleep(" \
  --include="*.test.*" --include="*.spec.*" . 2>/dev/null | grep -v node_modules | head -15

# Source files without tests
find . -path "*/src/*" -name "*.ts" -o -name "*.py" -o -name "*.js" 2>/dev/null | \
  grep -v node_modules | grep -v "\.test\." | grep -v "\.spec\." | head -30
```

## Audit Dimensions

### 1 — Suite Shape
Count and classify test files: **Unit** (isolated, fast, no I/O) · **Integration** (real DB/services, HTTP) · **E2E** (full-stack, browser).

- **Pyramid** (backend): unit-heavy, some integration, few E2E ✓
- **Trophy** (frontend): modest unit, integration-dominant, few E2E ✓
- **Ice-cream cone**: E2E-heavy, few unit → **Critical**

Report: `Unit: N | Integration: N | E2E: N` + shape verdict.

### 2 — Coverage Distribution (Khorikov ch.1)
Coverage on the wrong code is dangerous. Check: Is it enforced (threshold in config)? Is it measured on domain/business logic or mostly glue? Known gaps? Any critical paths (auth, payments, mutations) with low coverage?

Flag: 100% coverage on trivial code + 40% on core logic → Critical.

### 3 — Untested Modules (Beyoncé Rule — SE@Google)
Source files/directories with no corresponding test file. Flag: core domain logic, external integration points (webhooks, payments), recently changed files.

### 4 — Infrastructure Health (Khorikov ch.8–10; Fowler "Eradicating Non-Determinism")

| Check | Good | Risk |
|-------|------|------|
| Isolation | Each test creates/destroys its own data | Shared mutable state between tests |
| DB strategy | Real DB for integration tests | In-memory substitutes that diverge from prod |
| External deps | Third-party services mocked; own DB real | Everything mocked OR nothing mocked |
| Clock | Injected or wrapped | Direct `Date.now()` / `time.time()` calls |
| Parallel safety | Tests run in parallel cleanly | `--runInBand` workaround for shared state |
| CI | Tests run on every push with gate | Manual only |

### 5 — Flaky Test Inventory (Fowler, 2011)
Count: skipped, retried, or `.skip`ped tests. Look for bare `sleep()` calls. Is there a quarantine strategy with a hard limit? Without a limit, quarantine becomes a graveyard → Critical.

### 6 — Suite Velocity (Fowler "UnitTest" bliki)
Is the full suite fast enough to run before every commit? (Beck's rule: ≤10 minutes.) Is there a fast-unit-only subset for local dev? Slow suites with no fast path → Important.

### 7 — Refactor Confidence (Khorikov Pillar 2; GOOS ch.18)
Do tests verify **observable behavior** or **implementation details**? Would renaming an internal method break tests? Do integration tests use real managed dependencies (enabling confident schema changes)? This is the ultimate verdict driver.

## Output

```
## Test Strategy Audit: [project]

### Input Source
[GSD map: .planning/codebase/TESTING.md (dated YYYY-MM-DD)] OR [Direct scan]

### Suite Shape
Unit: N | Integration: N | E2E: N — Shape: [Pyramid / Trophy / Ice-Cream Cone]

---

### Critical
- [DIMENSION] issue — evidence — fix

### Important
- [DIMENSION] issue — evidence — fix

### Minor
- [DIMENSION] issue — evidence — fix

---

### Untested Modules
- [module] — [risk if untested]

### Infrastructure Health
Isolation: [GOOD/PARTIAL/POOR] | Deps: [GOOD/PARTIAL/POOR] | CI: [YES/PARTIAL/NO]
Flaky tests: N skipped/retried — quarantine: [YES/NO/GRAVEYARD]

### Refactor Confidence
[HIGH / MEDIUM / LOW] — [2 sentences: what enables or blocks it]

---

Counts: Critical: X | Important: Y | Minor: Z
Verdict: [STRONG / ADEQUATE / NEEDS WORK / CRITICAL GAPS]

### Next Steps
1. [Highest-leverage action]
```

After the report: recommend whether to run `quality-tests` on specific high-risk files, or whether infrastructure changes are needed first.
