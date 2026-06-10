# Review rubric — the audit checklist

Used in **REVIEW mode** (assessing structure, no code written this turn) and as the self-review an
agent runs on its own output before presenting in BUILD mode.

Each item is a yes/no with **evidence to cite** — not a vibe. The 7 fitness-function tests in
`SKILL.md` are the summary; this is their full expansion, grouped by concern. In review mode, every
failed item becomes a finding: cite the failed check + the exact file/line, give the **minimal**
conforming fix, and rank by severity (security/frozen-contract > correctness > conformance/boundary
> the rest). Recommend; do not refactor. Offer to apply high-severity fixes one at a time, with
approval.

---

## Conformance
- [ ] Each new/changed unit was patterned after a cited existing sibling; no new dialect introduced.
      *Evidence: list new units → the sibling each matched.*
- [ ] Every applicable documented invariant (CLAUDE.md, skills, ADRs) obeyed; nothing a doc says was
      deliberately removed has been reintroduced.
- [ ] Naming matches the repo's ubiquitous language and casing; externally-referenced identifiers
      (URLs, asset names, env vars, API/DB fields) left stable or migrated explicitly.

## Structure & dependencies
- [ ] Each new file has one responsibility; no god-file, no confetti — granularity matches the repo.
- [ ] Organized by feature/concern; deleting the feature touches a bounded, predictable file set.
      *Evidence: name the subtree + the registration lines a delete would touch.*
- [ ] Dependency direction is one-way (domain/lib doesn't import UI); no cycles; boundaries crossed
      only via typed contracts.
      *Evidence: the import lines added, with their direction.*
- [ ] No pass-through layer or single-implementation interface that isn't a documented seam.

## Types, errors, state
- [ ] No `any`; no `as` except post-check narrowing; no `!` dodging real nulls; no `@ts-ignore`.
      Public functions have explicit return types.
- [ ] External input validated at the boundary; multi-state values modeled as discriminated unions.
- [ ] No empty catch; every error path handles/translates/propagates explicitly; no secrets logged.
- [ ] No hidden mutable global state; config/env read at the boundary and passed inward.
- [ ] Control flow is statically traceable — no string-keyed/reflective dispatch the reader can't
      follow (or its full mapping is enumerable in one file).

## Restraint
- [ ] Built only the stated requirement; no unrequested infra/knobs/abstractions (or surfaced them
      as questions).
- [ ] No abstraction without the rule of three + a present second caller; no pattern theater.
- [ ] Reused existing utilities/official tools instead of reinventing.
- [ ] Comments explain *why*/invariant, not *what*.

## Contracts & longevity
- [ ] No frozen contract (URL, asset filename, env name, public response shape, DB column)
      renamed/moved without a migration path.
- [ ] Documented invariants kept in sync in the same change (new data shape → renderer + doc; new
      page → sitemap; data-flow change → privacy/disclosure; new decision → ADR + glossary).

## Verification
- [ ] Invariants have tests stating them; tests target behavior, not internals.
- [ ] New behavior was written test-first (test precedes code); trivial glue exempt.
- [ ] The repo's test posture was stated (TDD / suite+CI / essentially none) — surfaced, never silent.
- [ ] A single *sound* testing convention was used (no second test *dialect*); only *coverage* is
      uneven. A poorly-architected existing test pattern was flagged + a better one recommended, not
      cemented as the norm.
- [ ] Decisions to adopt/change a convention or go wider than the ask were surfaced as
      recommendations for the user to choose — not silently defaulted in either direction.
- [ ] Missing tests on working, untouched code were NOT raised as per-file findings; an untested
      invariant is a finding only when high-severity (security/correctness/frozen contract).
      Test-change volume matches the scope the user asked for.
- [ ] If a broad "bring to standard" migration was in scope, it targets *full* conformance (driven to
      completion), not a permanently two-speed repo.
- [ ] typecheck + lint + production build pass — not just a clean dev compile (CI is stricter).
- [ ] For UI/behavior changes, verified in the running app, not only "build passed."

## The 7-test summary (fast pass)
1. **Cold-start** — from tree + `ARCHITECTURE.md` alone, where does feature X live and what depends
   on it?
2. **One-hop** — understanding any one behavior reads ≤ ~3 files.
3. **Conformance** — every new/changed file follows the prevailing pattern, or an ADR records why
   not.
4. **Boundary** — no forbidden import; dependencies point one way.
5. **Name-predicts-content** — each new name predicts its file's contents unopened.
6. **No-speculation** — every abstraction has a present caller or a recorded reason.
7. **Artifacts & verification** — artifacts updated in the same change; invariants tested;
   typecheck + lint + build green.

## Final gate
- [ ] A senior reading the diff cold can trace input→output without a debugger, predict the blast
      radius, and find nothing they'd ask to be redone. If any item is "no," fix it or flag it
      explicitly — don't ship silently.
