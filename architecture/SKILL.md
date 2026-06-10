---
name: architecture
description: Use whenever designing, reviewing, refactoring, or evolving the STRUCTURE of a codebase — module boundaries, layering, where new code should live, naming a package or service, an architecture-worthy decision, or auditing existing structure. Triggers on phrases like "design the architecture", "where should this live", "review the structure", "is this the right abstraction", "refactor for X", "set up a new project", adding a module/service/layer, or any change that crosses module boundaries. Produces architecture that satisfies senior human reviewers AND is optimized for AI comprehension and token efficiency. NOT for single-function edits, styling, or bug fixes that stay inside one file.
---

# Architecture — senior-approved AND AI-optimal

Produce and maintain architecture a senior architect would approve in review **and** that a
fresh AI agent can understand from the file tree plus one entry document, without reading
every file. When the two pull apart, optimize for the **reader with the least context** —
that single rule serves the busy reviewer and the cold-start agent at once.

These two goals are mostly the *same* optimization: locality, low coupling, explicitness,
precise names, typed contracts, and no runtime magic are what make code legible to a senior
reviewer *and* cheap for an agent to navigate. They diverge in only a few places (DRY-vs-
locality, comment density, file granularity, speculative indirection) — and the sophisticated
expert view resolves each toward the AI-optimal side anyway. The priority order below pins down
the divergences so you don't have to re-litigate them each time.

If a change stays inside one file and crosses no module boundary, this skill does not apply —
proceed normally.

## The one metric everything serves

**Minimize the blast radius of a typical change** — the set of files you must read to make
AND safely verify it — **while keeping that blast radius fully visible** via greppable unique
names and static types. Small-but-hidden is worse than large-but-visible: an agent (or human)
that can *see* its full blast radius changes safely even when it's large; one that can't ships
silent breakage. Decompose any structural choice into: does it lower the cost to **locate** the
right place, **load** what's needed to edit correctly, and **verify** nothing else broke?

**Blast radius has a second axis: write contention.** The first axis (above) is the *read/verify*
radius. The second is how many *distinct, unrelated changes* — and, increasingly, how many
*concurrent agents or authors* — must edit the **same file** to do unrelated work. A file every
change funnels through is a serialization point and a merge-conflict magnet: parallel work on
unrelated features collides, edits clobber one another, and the file's git history is unreadable.
This axis matters more every year as parallel-agent workflows become normal — a 3000-line file is a
single lock that every agent contends on. Co-locate by concern so unrelated changes land in
*different* files. When one file keeps showing up in unrelated diffs, or several agents keep
colliding on it, **that contention is itself a reason to split** — independent of how navigable the
file is to read. (A file can be perfectly readable and still be a contention bottleneck.)

## Priority order (resolve conflicts top-down; name the rule you invoked)

1. **Security & legal invariants** — no secrets in code, scoped access, no data/auth leaks, consent/privacy accuracy. Never traded.
2. **Frozen external contracts** — public URLs, asset filenames, env-var names, public API/response shapes, DB columns. Never break silently; require an explicit migration path.
3. **Correctness & explicit error handling** — over elegance. No swallowed errors.
4. **Conform to this repo's existing conventions** — documented rules (CLAUDE.md, skills) and the prevailing pattern beat your personal/ideal pattern. Propose a better idea separately; never start a second dialect. **Exception — when the prevailing pattern IS the anti-pattern** (the target file is already a god-file, or a doc/ADR/review says the codebase is moving *off* this pattern): conform to the **direction the repo is moving** — its decomposition plan, its already-extracted sibling modules — not to the local mess. "Put it where everything else already lives" is precisely how a god-file grows another 2000 lines; mechanical conformance to a bloated file is the trap this rule must not become. **And when conforming would itself significantly violate a higher-priority rule above** (a security leak, a broken contract, a swallowed error, a navigability black hole) — i.e. the prevailing pattern is *wrong*, not merely unfamiliar — do NOT silently conform (you would propagate a likely **systemic** defect everywhere that pattern already lives) and do NOT silently fix it locally (a second dialect). **Stop, surface it to the user as a probable system-level problem, and confirm the direction before proceeding.** A defect that is both *prevailing* and *principle-violating* is exactly the kind worth fixing sooner rather than later — and whether to fix it repo-wide now, fix-local, or knowingly conform-for-now is the user's call, not a silent default.
5. **Navigability & context-locality** — a cold reader finds the right file from names + structure; the blast radius is small and fully visible. (Where human-review and AI-comprehension converge.)
6. **Type safety** — never weaken types to satisfy a lower-priority preference.
7. **Locality over DRY** — keep things that change together together; rule of three before abstracting.
8. **Simplicity / YAGNI** — fewer moving parts beats extensibility and pattern-purity.
9. **Composition over inheritance** — when both are viable.
10. **Personal/stylistic taste** — last; match the surrounding file and move on.

If two equal-rank rules still conflict, or the right call is genuinely ambiguous, **stop and
ask one clarifying question** rather than guessing.

## Set your mode first (state it in one line each)

- **Context — BROWNFIELD (default) vs GREENFIELD.** Brownfield if the target area has ≥1
  existing module/feature with a discernible pattern. Greenfield only if it's an empty repo
  or a genuinely new top-level area with no precedent.
- **Activity — BUILD vs REVIEW.** Build = adding/changing code. Review = assessing, no code
  is written this turn.

### BROWNFIELD — observe and conform BEFORE designing

This is your first action, every time. A senior engineer joining a codebase reads before they
write; the #1 reason agent output gets rejected is that it's locally correct but globally
foreign — a second dialect inside one codebase.

1. **Read the contracts:** root + nested `CLAUDE.md`, `.claude/skills/*`, `README`, any
   `ARCHITECTURE.md` / `GLOSSARY.md` / `EXTENDING.md`, `tsconfig` (strictness), lint/format
   config, `package.json` scripts (real build/test/dev commands).
2. **Map the layout:** top-level dirs, feature-folders vs layer-folders, file granularity,
   route groups.
3. **Find ≥2 prior examples** of the exact thing you're adding — these are your templates.
   Cite the file you patterned after.
4. **Extract the idioms:** error shape, naming/casing, import style, how strings/assets/config
   are referenced, how boundaries are typed and validated.
5. **Identify documented invariants and scar-tissue rules** (frozen URLs, single-signal
   patterns, "this section exists because we shipped X once"). These are non-negotiable; never
   reintroduce a pattern a doc says was deliberately removed.
6. **Confirm the verification gate:** the exact typecheck/lint/build/test commands that mean
   "done" here.
7. **Read and state the test posture.** Note whether the repo practices test-first/TDD, has a
   real suite + CI gate, or essentially no tests — **and whether any existing tests are soundly
   architected** (behavior at the boundary, not brittle internals). Say so every time, however
   small the task: a project not on TDD — or one whose few tests model a bad pattern — is
   something the user should always learn from this skill, not discover later.
8. **State the prevailing pattern in one sentence, then design in the repo's own vocabulary.**

### Before you add to an existing file — the split trip-wires

Adding "just one more function" to a file that is already too big is *the* way a god-file forms,
and rule #4 (conform) is what rationalizes it each time. So before adding to an existing file, check
these trip-wires; **if any fires, split first** (extract a cohesive module, or carve your addition
into a new one), then add:

- **Size × concerns:** the file is past a few hundred lines AND already holds ≥2 separable concerns.
  (Heuristic, not a hard LOC cap — one genuinely cohesive concern can be long. The smell is
  *length × number of concerns*, not length alone.)
- **Named debt:** a doc, ADR, `ARCHITECTURE.md`, or review already says this file should be split or
  lays out a decomposition plan for it. That plan is a trip-wire, **not** a permission slip to add
  more "until someone does the split."
- **Contention:** the file keeps appearing in unrelated diffs, or multiple authors/agents keep
  colliding on it (the write-contention axis above).
- **Precedent:** sibling modules were already extracted from this file (or its kind) — the pattern to
  conform to is "extract the next one," not "grow this one."

**Deferred decomposition is itself the trap.** A split that is planned and then scheduled "later /
riskiest last" with no forcing function does not happen — the file keeps growing while everyone
points at the plan, and the plan's own line-number map rots. (This is the single most common way a
diagnosed god-file stays a god-file.) "Always shippable" is satisfied by **one extraction at a
time** — it is not a license to never start. So: do the **first cut now**, in the same change —
pick the highest-leverage or lowest-coupling module and extract it — and add a forcing function so
the rest can't be deferred indefinitely (a size check in CI, a "no new top-level symbols in this
file" rule, a CODEOWNERS entry). A written-but-unexecuted plan is worse than no plan: it reads as
"handled."

### Test discipline in an existing project — surface always; change in proportion to the ask

A brownfield repo often has weak or no tests, and an architecture pass shouldn't silently turn into
a mass test-backfill the user never asked for. Two obligations that don't trade against each other:

- **Always surface the gap.** Whatever the task's size, if the repo isn't test-first (no suite, no
  CI gate, low coverage on the area you touched), say so plainly and offer a path. Visibility is
  never scaled down — the user should learn the project isn't on TDD *from this skill*, not discover
  it later. This is the constant.
- **Scale the *change* to the request.** How much test work you actually do tracks what was asked:
  - **Narrow ask** (a quick opinion, one feature, "just add this code") → **forward ratchet only**:
    write the new behavior test-first, and add a characterization test before you modify untested
    code so you can change it safely. Do **not** backfill tests across untouched, working code. Note
    the gap, offer the path, stop. (If the testing situation needs a *wider* decision — no
    convention, or a bad existing one — surface a recommendation per the collaborative rule below
    rather than silently proceeding.)
  - **Broad ask** ("make this project conform to the skill", "bring it up to standard", "move us to
    TDD") → the target is the **whole project**, not a sample — don't cap an explicitly broad
    mandate as "incremental." Adding tests is additive and low-risk (it doesn't change behavior), so
    unlike a god-file split there's no safety reason to stop short: drive it to completion. Sequence
    **highest-risk invariants first** so value lands early and a large job reviews in coherent units,
    and add a CI coverage floor to **lock the standard in and stop regressions** — not as license to
    stop early. If characterizing legacy code surfaces a bug or ambiguous behavior, **surface it and
    ask** — don't silently encode the current behavior as "correct."

**Coverage gap ≠ test dialect.** Uneven *coverage* during a migration is expected and self-resolves
as the ratchet advances — it is **not** a second dialect. A second dialect is an inconsistent test
*style* (two frameworks, two folder layouts, two ways of asserting). So one testing convention
governs new tests, narrow or broad — but "one convention" is not "cement whatever exists": conform
to the repo's pattern only if it's **sound**. If a stray existing test is poorly architected for TDD
(asserts internals, brittle, not behavior at the boundary), that's the *prevailing-pattern-IS-the-
anti-pattern* case (rule #4) — don't cement it as the norm and don't silently diverge into a second
style; surface it and recommend a better convention, user decides. What's allowed to be uneven is
only *how much* is covered, never *how* it's tested.

**Brownfield testing decisions are collaborative.** Adopting or changing a test convention, fixing a
bad existing test pattern, or going wider than the literal ask are **ASK + recommend** moves, not
silent defaults. Surface the state and offer a recommendation that **may be wider than what the user
asked for, when good architecture justifies it** (a high-risk untested invariant, an actively harmful
test pattern, a convention vacuum that *will* cause divergence) — then let the user choose. Keep it
proportionate: the default *action* stays scoped to the ask; the *recommendation* to go wider is
justified and the user's call, so the skill never nags "tests everywhere" on every small touch. (This
is the skill's existing ASK-vs-DECIDE / ASK+flag posture, applied to tests.)

The payoff: an existing project can *get there* over time — every touch ratchets coverage forward,
the gap stays visible, and wider moves happen by informed user choice.

### GREENFIELD — establish and record the pattern

1. Pick the **smallest** structure the first real feature needs — feature/concern folders,
   strict types, named exports, a verification script. No speculative layers.
2. **Test-first is the norm, not the exception.** Stand up the test runner as part of that
   initial structure, and write the test that states a behavior *before* the code that
   satisfies it — for every unit carrying a real invariant. Record red-green-refactor as the
   established discipline in `CLAUDE.md` + `ARCHITECTURE.md` from the first commit, so the repo
   is born test-first and every later contribution conforms. (Exempt only trivial glue with no
   logic — wiring, config, pure pass-through; invariant-bearing behavior is never exempt.)
3. Choose **one mechanism per concern** and write the conventions into `CLAUDE.md` +
   `ARCHITECTURE.md` as you set them, so the repo becomes brownfield-with-rules immediately.
4. Create the cold-start artifacts seeded with the initial structure (see Artifacts).
5. Surface any non-trivial architectural choice (state management, data layer, auth) as a
   decision to confirm, not a silent commitment.

## Core rules (one-liners; full catalog with the why + check in `references/principles.md`)

- **Cohesion/coupling:** a module owns one concern end-to-end; import only another module's
  public entrypoint, never its internals. Deleting a feature touches a bounded, predictable
  set of files.
- **Dependency direction:** one-way and acyclic (pure/domain logic must not import UI; UI
  imports domain, never the reverse). Cross a boundary only through a typed contract; validate
  external input at the boundary.
- **Naming = ubiquitous language:** one term per concept everywhere; names describe role/intent;
  unique and greppable (no `data`/`handler`/`util`/`manager`). Names are the index an agent
  searches by.
- **Explicit over magic:** no hidden control flow, reflection, string-keyed dispatch, ambient
  mutable globals, or runtime-resolved bindings an agent can't follow by reading. Prefer boring,
  statically-traceable code even at some verbosity cost — explicitness is compression for a
  reader who can't run the program in their head.
- **Types as compressed specs:** `strict` on; no `any`, no `as` except to narrow a value you've
  already runtime-checked, no `!` dodging real nulls, no `@ts-ignore` to pass the build. Model
  states as discriminated unions. A precise signature lets a reader skip the body.
- **Errors are values:** never an empty catch; every path handles, translates, or propagates —
  explicitly. Never log secrets.
- **Composition over inheritance; small functions over deep hierarchies.**
- **YAGNI:** build only the stated requirement; no config knobs, plugin systems, or generic
  "managers" for hypothetical futures. Surface future-proofing as a question; don't bake it in.
- **Rule of three:** no shared abstraction until the third real duplication of the *same
  decision* (not the same shape), and only with a present second caller.
- **File granularity sweet spot:** one coherent concept per file; no god-files, no confetti —
  match the codebase's existing granularity. Co-locate tests/types/styles with what they describe.
- **Re-derive the real invariant; don't cargo-cult a constraint into a stronger one.** A stated
  constraint ("no build step", "stdlib only", "one global script scope") forbids a *mechanism*, not
  every structure. Before declaring something "can't move / must stay one file", state the actual
  invariant in one line and check whether a conforming split satisfies it: "no bundler" still permits
  concatenating asset files at startup; "stdlib only" still permits many imported modules; "one
  global scope" still permits many source files loaded in order. An over-strong reading of a real
  constraint is how the biggest blobs get frozen as "un-splittable" — re-test the constraint before
  you obey it as a size limit.
- **Minimize indirection hops:** each pass-through layer (wrapper, anemic service, re-export
  barrel that hides origin) is one more read and one more search false-positive. Inline single-
  implementation abstractions.
- **SOLID where it pays** (SRP, DIP at real boundaries, ISP); **reject the cargo cult**
  (one-implementation interfaces, `IFoo`/`FooImpl` pairs, abstract base classes, DI containers
  added "for testing"). An interface with exactly one implementation and one caller is the tell.

## Do NOT (highlights; full catalog in `references/anti-patterns.md`)

Premature/speculative abstraction · design-pattern theater · intra-repo inconsistency (a second
dialect) · god-files · growing a known god-file instead of splitting it (conformance as an excuse) ·
deferring a written decomposition plan with no forcing function · over-reading a real constraint
into "un-splittable" · confetti of micro-files · reinventing existing utilities (grep first; flag
the official tool before building one) · ignoring established idioms / reintroducing a removed
pattern · unrequested infra (watchdogs, retries, caching, flags, headers nobody asked for) ·
comments that narrate the code instead of stating the *why*/invariant · leaky abstractions ·
hidden global state · silent failure / swallowed errors · `any`/`as`/`!`/`@ts-ignore` to quiet
the type-checker.

## Artifacts to maintain (proactively — part of "done"; specs + templates in `references/artifacts.md`)

An agent starts cold every session with no memory; a human teammate gets onboarded once. These
artifacts are the onboarding, written down. Update them in the **same change** as the code (stale
docs are worse than none). Keep terse — tables and bullets, one fact per line, co-located with what
they describe. In a repo that already documents conventions (e.g. a rich `CLAUDE.md`), **extend the
existing docs rather than adding parallel files** — conform first.

- **`ARCHITECTURE.md` (root):** dir tree with a one-line purpose each; the layer model + allowed
  **dependency direction**; entrypoints; the canonical build/test/run commands. The first file a
  cold reader opens; say so. Target under ~150 lines.
- **`GLOSSARY.md`:** one line per domain term → definition → the type/file that defines it. One
  canonical term per concept.
- **`EXTENDING.md`:** the named seams — "to add a new X, implement `Y` in `Z/`, register at `W`,
  copy test `T`." This is the map for building, and the source of grounded feature ideas.
- **Per-file module header (3–8 lines):** purpose, public contract, **invariants** ("amounts are
  minor-unit integers", "this list is always sorted"), and key collaborators. Invariants are the
  safety conditions an agent otherwise can't infer.
- **ADRs (`docs/adr/NNNN-title.md`):** context, decision, and the **rejected alternatives + why**
  (the part code can't reconstruct, and the part an agent will otherwise "helpfully" undo). Link
  the ADR id from the code it governs.

## Feature ideation (the payoff of the second constraint)

A great structural map is what lets an agent reason about *what could be*, not just *what exists*.
When asked for feature/improvement ideas (or proactively, in review), reason from the architecture
map, not by scanning files linearly: propose features that **plug into an existing seam**
(`EXTENDING.md`), **complete the domain model** (a missing entity/state/transition in `GLOSSARY.md`),
**respect the invariants**, and **sit at the right layer** (dependency direction). For each idea,
name: the seam it uses, the files it would touch (its blast radius), and the invariant it must
preserve. A small, visible blast radius is what lets you propose confidently and accurately.

## Definition of done — run before presenting (fitness function; expanded in `references/review-rubric.md`)

All must be YES; give evidence, not a vibe:

1. **Cold-start:** from the tree + `ARCHITECTURE.md` alone, you can state where feature X lives
   and what depends on it.
2. **One-hop:** understanding any single behavior reads ≤ ~3 files.
3. **Conformance:** every new/changed file follows the prevailing pattern, or a divergence is
   recorded in an ADR with a reason.
4. **Boundary:** no forbidden import (no sibling-internal reach, no upward climb past module root);
   dependencies point one way.
5. **Name-predicts-content:** each new name lets a domain-literate reader predict contents without
   opening the file.
6. **No-speculation:** every abstraction/layer has ≥1 present caller or a recorded reason; no
   single-implementation interface "for later."
7. **Artifacts & verification:** ADR-worthy changes updated the artifacts in the same change;
   invariants have tests; typecheck + lint + production build pass (CI is stricter, not looser —
   not just a clean dev compile).

## When to ASK vs DECIDE

- **ASK first** when the decision is irreversible/expensive (new service, new datastore, public API
  shape, a dependency that spreads), cross-cutting (auth, error model, data-flow direction, state
  management), or ambiguous (two existing patterns conflict and neither dominates).
- **ASK + flag (don't just conform)** when conforming to the prevailing pattern would itself
  significantly violate a higher-priority rule (security, a frozen contract, correctness,
  navigability) — the pattern is likely a *systemic* defect, so surface it to the user as a
  system-level problem worth fixing sooner rather than later, instead of silently propagating it or
  silently diverging into a second dialect (priority rule #4).
- **DECIDE yourself** (state it in one line, proceed) when it's local and reversible (placement
  inside an established module, an internal helper extraction) or fully determined by an existing
  pattern that doesn't violate a higher-priority rule (then just conform — but if that pattern *is*
  principle-violating, ASK + flag per above).

## Review/audit mode

Read-only and recommendation-only. Score against `references/review-rubric.md` and the 7 DoD tests.
Output a findings list ranked by severity, each citing the failed test + the exact file/line, with
the **minimal** conforming fix. Do **not** refactor; recommend. Offer to apply high-severity fixes
one at a time, with approval.

**On tests specifically:** always report the repo's test posture as an observation (per the standing
rule above), but do **not** emit a per-file "missing test" finding for working, untouched code — that
turns a structure review into a backfill campaign nobody asked for. An untested invariant becomes a
*finding* only when it's high-severity (security, correctness, a frozen contract); otherwise it's the
forward ratchet's job, not the review's. A review **may recommend more than the user asked for** when
architecture justifies it (a high-risk untested area, an actively bad existing test pattern that
shouldn't become the norm) — as a recommendation for the user to choose, not a mandate. If the user
asked to bring the whole project to standard, recommend a coverage-migration plan targeting *full*
conformance (highest-risk-first, a single *sound* test convention, a CI floor) — sequenced for
review, not capped short.

## Standing rules (always)

Simplest fix that solves the actual problem · don't add unrequested features without asking · flag
existing official tools before building custom · ask one clarifying question when ambiguous · no
time estimates · validate with typecheck + lint + build before claiming done · surface the repo's
test posture whenever it isn't test-first, regardless of task size.

## Going deeper

- Full principle catalog with the why + check for each, and where AI-optimal diverges from naive
  human practice → `references/principles.md`
- The complete DO-NOT catalog with rationale → `references/anti-patterns.md`
- Artifact specs and copy-paste templates → `references/artifacts.md`
- Worked GOOD/BAD before-after pairs → `references/examples.md`
- The audit scoring rubric → `references/review-rubric.md`
