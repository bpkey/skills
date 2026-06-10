# Artifacts — the cold-start documentation set

An agent starts every session cold, with no memory of the codebase; a human teammate is onboarded
once and carries the model for months. These artifacts are that onboarding, written down — which is
why they pay off far more for agent comprehension than humans tend to expect, and why a senior
reviewer also welcomes them on any system meant to last.

**Three rules for all of them:**
1. **Co-locate** with what they describe (so they surface in search near the code).
2. **Keep terse** — tables and bullets, one fact per line, link rather than restate. The union of
   `ARCHITECTURE.md` + `GLOSSARY.md` + `EXTENDING.md` should give a competent cold-start orientation
   in a few thousand tokens.
3. **Update in the same change as the code.** A stale artifact is worse than none — it actively
   misleads. Keeping it current is part of "done."

**Conform first.** In a repo that already documents its conventions (e.g. a rich root `CLAUDE.md`
with an architecture section, or existing `docs/`), **extend the existing docs** rather than adding
parallel files. Introduce a new artifact file only when there's no existing home for it.

---

## `ARCHITECTURE.md` (repo root) — the entry document

The first file a cold reader opens. Say so in its first line. Target under ~150 lines.

Contains:
- A **tree of top-level directories**, each with a one-line purpose.
- The **layer model and allowed dependency direction** (which layer may import which; what depends on
  nothing).
- The **entrypoints** (where execution starts: routes, `main`, the server).
- The **canonical commands**: build, test, run, lint, typecheck.

Skeleton:

```markdown
# Architecture

Read this first. It maps the codebase so you can find any concern without reading every file.

## Layout
- `app/`        — routes and pages (entrypoints). Imports `lib/`, never the reverse.
- `lib/`        — domain + application logic, organized by concern (`lib/<concern>/`). Pure; no UI.
- `components/` — shared UI. Imports `lib/`.
- `<infra>/`    — deployment/config. Imports nothing in app code.

## Dependency direction (one-way, no cycles)
app, components  →  lib  →  (nothing)
External input is validated at the boundary (route handlers, lib entrypoints).

## Entrypoints
- HTTP: `app/**/route.ts`, pages under `app/`
- (jobs/CLI/etc. as applicable)

## Commands
- dev:       `<cmd>`
- build:     `<cmd>`     # the gate CI runs; stricter than dev
- test:      `<cmd>`
- typecheck: `<cmd>`
- lint:      `<cmd>`
```

---

## `GLOSSARY.md` — the ubiquitous language

One canonical term per domain concept, used everywhere (name, type, file, route, table). The agent
reads it once and the whole codebase's vocabulary decompresses.

```markdown
# Glossary

| Term    | Meaning                                                | Defined in             |
| ------- | ------------------------------------------------------ | ---------------------- |
| Product | A purchasable item shown on a catalog page             | `lib/catalog/types.ts` |
| Cart    | A visitor's in-progress set of line items pre-checkout | `lib/cart/types.ts`    |
```

Rule: if two words are used for one concept (`user`/`account`/`member`), pick one and rename the
others — synonyms force a reader to load extra context to learn they're aliases.

---

## `EXTENDING.md` — the seam catalog

Where new things plug in. This is the map for *building* (not just reading), and the source of
grounded feature ideas: an agent that can see the seams proposes features that fit them.

```markdown
# Extending

## Add a new product page
1. Add strings to `lib/strings.ts` under a new `catalog.<slug>` key (match an existing shape).
2. Add the route at `app/(site)/products/<slug>/page.tsx` (copy `products/sample-product`).
3. Register it in `app/sitemap.ts`.
4. If it needs a markdown twin, add a composer in `lib/content/pages.ts`.
Invariant to preserve: pages never render their own `<main>`/`<Footer>` — the route group owns them.

## Add a new <thing>
- Implement `<Interface>` in `<dir>/`, register at `<file>`, copy test `<test>`.
```

Each seam names: the interface/shape to implement, the folder it lives in, the registration site, the
test to copy, and the invariant a new instance must preserve.

---

## Per-file module header — the local contract

3–8 lines at the top of each significant file. The **invariants** are the gold: they encode the
unwritten rules that make a change safe — exactly what an agent can't infer and a human learns by
being told.

```ts
/**
 * Consent state machine: resolves a visitor's region + signals into an allowed-tracker set.
 * Public: resolveConsent(input): ConsentDecision
 * Invariants:
 *   - Strict-region visitors default to all-denied until an explicit choice.
 *   - GPC always wins over a stored preference.
 * Collaborators: reads region from `lib/consent/region.ts`; consumed by `components/ConsentProvider`.
 */
```

State **purpose** (one line), **public contract** (what it exposes), **invariants** (what must stay
true), and non-obvious **collaborators**. Skip narration; state surprises.

---

## ADRs — `docs/adr/NNNN-title.md`

One per non-obvious decision. The **rejected alternatives + why** is the part code can't reconstruct
— and the part an agent will otherwise "helpfully" undo. Keep each to a page. Link the ADR id from
the code it governs (`// see ADR-0007`).

```markdown
# ADR-0007 — Single-signal theme via `data-theme`

## Status
Accepted

## Context
The site needs light/dark with an OS default and a user override that a dev toggle can force.

## Decision
Resolve OS preference + stored override to `<html data-theme>` in a pre-paint bootstrap. All CSS
keys off `[data-theme]`. Nothing reads `@media (prefers-color-scheme)` directly.

## Consequences
One source of truth; the dev toggle and OS both flow through the same resolution path.

## Rejected alternatives
- Raw `@media (prefers-color-scheme)`: a dev override can't force it, and mixing it with a class
  toggle flips only half the page (we shipped this bug once).
```

---

## Optional — `CONVENTIONS.md` (or a section in `ARCHITECTURE.md`)

The handful of repo-wide rules not visible in any single file: error-handling policy, logging
contract, money/time/units conventions, null-vs-absent, ID formats. State the ambient contract once
so every file's verify-radius shrinks. Fold into `CLAUDE.md` or `ARCHITECTURE.md` if the repo already
has a home for it — don't add a file for the sake of it.
