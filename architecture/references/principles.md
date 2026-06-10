# Principles — the full checkable catalog

Each principle is stated as: **Rule → why a senior cares → which blast-radius term it serves
(Locate / Load / Verify) → a yes/no check.** "Blast radius" = the files you must read to make a
change AND be confident nothing else broke. Lower and more *visible* blast radius is the unifying
target; almost every rule here is a way to lower it.

The order roughly tracks how often a violation is what actually gets flagged in review.

---

## P1 — Conform to the codebase before expressing any preference
**Rule:** before writing, locate ≥2 existing examples of the thing you're adding (a route, a
`lib/<concern>` module, a component, an error path) and match their structure, naming, granularity,
and export style. If none exist, match the nearest analogue. Cite the file you patterned after.
**Why:** the top reason senior reviewers reject agent output is that it's locally correct but
globally foreign — a second dialect inside one codebase. A "better" pattern that's inconsistent is
worse than a "worse" one that's uniform.
**Serves:** Locate + Load (one mental model for the whole repo).
**Check:** can you name the sibling file each new unit was patterned after?

## P2 — High cohesion, low coupling, organized by feature/concern
**Rule:** a module owns one concern end-to-end (logic + its types + its tests). A change to one
concern must not require edits scattered across unrelated folders. Import only another module's
public entrypoint, never its internals.
**Why:** reviewers test this by asking "if I delete this feature, how many files do I touch, and do
unrelated ones break?" Feature folders make the blast radius legible.
**Serves:** Locate (one folder) + Verify (radius bounded by the folder).
**Check:** for a representative feature, are most files it touches in one subtree? Could you delete it
by removing one folder plus a few registration lines?

## P3 — Dependency direction is one-way; boundaries are explicit and typed
**Rule:** dependencies flow inner→outer — pure/domain logic must not import UI or infrastructure; UI
imports domain, never the reverse; no cycles. Cross a boundary only through a typed contract (a
signature, a `type`/`interface`, a schema). Validate external input (form bodies, env, webhook
payloads) at the boundary; pass typed values inward.
**Why:** inverted or circular dependencies are spotted in seconds and rot a codebase fastest.
**Serves:** Verify (no spooky action at a distance) + Load (the contract replaces reading the impl).
**Check:** can you draw the dependency arrows and confirm they all point one way, no cycles?

## P4 — Explicit over magic
**Rule:** no hidden control flow — no reflection, string-keyed dispatch where a switch would do, no
implicit global mutation, no metaprogramming a reader must simulate. Trace input→output by reading,
not by running a debugger. The only sanctioned "magic" is a documented convention, documented with
its silent-failure consequence.
**Why:** magic is a debt the next person pays; reviewers downgrade anything whose runtime behavior
they can't predict from the source. An agent literally cannot execute hidden bindings — it guesses.
**Serves:** Verify (static traceability) — the single biggest lever on invisible blast radius.
**Check:** for any call site, can you reach the concrete implementation by following types/imports
through reads, with no execution? If a binding is a string lookup, is the full map in one file?

## P5 — Strong types as compressed specs
**Rule:** `strict` on. No `any`; no `as` except to narrow a value you've already runtime-checked; no
`!` to dodge a real null; no `@ts-ignore`/`@ts-expect-error` to silence a real error. Public
functions get explicit return types. Discriminated unions over boolean-flag soup; `never` in switch
defaults for exhaustiveness. Name domain primitives (`UserId`, not bare `string`).
**Why:** a reviewer reads `any`/`as` as "the author gave up on the type system here" and audits
everything downstream. A precise type is a spec the reader trusts without opening the body.
**Serves:** Load (skip the body) + Verify (compiler surfaces the blast radius).
**Check:** can you understand each unit's contract from signatures alone? Any `any`/`as`/`!` that
isn't a post-check narrowing?

## P6 — Errors are values you handle, not noise you swallow
**Rule:** never an empty catch. Each error path either handles (recover + log with context),
translates (wrap into a typed error the boundary returns), or propagates (throw to a layer that
handles it) — pick one, explicitly. Never log secrets.
**Why:** swallowed errors are how code "works in the happy path, silent in prod." Reviewers grep for
empty catches first.
**Serves:** Verify (failure paths are traceable).
**Check:** does every catch visibly handle/translate/propagate? Any default that masks a missing
invariant?

## P7 — Composition over inheritance; small functions over deep hierarchies
**Rule:** prefer functions, plain objects, composed components. No class hierarchy ≥2 deep unless a
framework boundary demands it. Share behavior by extracting a function/hook, not by subclassing.
**Why:** inheritance scatters behavior across the hierarchy — extra-costly for an agent, which must
load every ancestor to know what a method does. A deep tree in a functional codebase is a smell.
**Serves:** Load (behavior is local, not inherited).
**Check:** is shared behavior a called function, not an inherited method?

## P8 — YAGNI / simplest thing that solves the actual problem
**Rule:** build only what the stated requirement needs. No config knobs, plugin systems, generic
"managers," or extension points for hypothetical futures. If future-proofing seems warranted, raise
it as a one-line question — don't bake it in.
**Why:** speculative generality is the most common agent over-reach and the most expensive to remove
later, because it metastasizes into the type system and every call site.
**Serves:** Load + Locate (fewer moving parts, no dead indirection).
**Check:** does every piece you added serve a present requirement?

## P9 — Rule of three before abstracting
**Rule:** don't extract a shared abstraction until the *third* concrete duplication, and only when
the three are the same *decision* (not coincidentally the same shape). Two usages stay duplicated.
Name the abstraction after the concept, not the mechanism.
**Why:** premature DRY couples things that only looked alike; the wrong abstraction is harder to undo
than duplication. Seniors prefer two honest copies to one leaky `BaseHandler`.
**Serves:** Verify (a shared util has a wide, often invisible radius; duplication is local).
**Check:** does each abstraction have ≥3 real call sites of the same decision?

## P10 — Naming = ubiquitous language; longevity is a constraint
**Rule:** names describe role/intent, reuse the domain's existing vocabulary, and are unique enough
to grep (no `data`/`handler`/`util`/`manager`/meaningful-`index`). One canonical term per concept
across name, type, file, route, table. Treat externally-referenced identifiers (URLs, asset
filenames, env-var names, API field names, DB columns) as **frozen contracts** — rename only with a
migration path.
**Why:** names are the API of the code and the agent's search index. A careless rename of a frozen
identifier can break a sent email or a printed QR code forever.
**Serves:** Locate (search precision) + Load (one word = one node in the model).
**Check:** does grepping a core identifier return mostly-relevant hits? Is each concept one word
everywhere? Are externally-referenced names left stable?

## P11 — File granularity sweet spot
**Rule:** one coherent concept per file, whose public surface fits a screen-ish read and whose
collaborators are few and named. Neither god-files (multi-hundred-line files mixing concerns) nor
confetti (one-symbol-per-file requiring many hops to assemble one behavior). Match the codebase's
existing granularity.
**Why:** god-files inflate Load (page through irrelevant code, blow the window); confetti inflates
Locate + hops.
**Serves:** Locate + Load.
**Check:** heuristics, not hard limits — flag files mixing ≥2 unrelated responsibilities, and
directories where you must open many tiny files to understand one behavior.

**Split trip-wires (the missing forcing function).** "No hard limits" must not become "no limits."
A god-file almost never arrives in one commit — it accretes, one conformant "just add it here"
function at a time, because P1 (conform to the prevailing pattern) actively *endorses* adding to the
biggest file. Counter it with explicit trip-wires checked **before adding to an existing file**; if
any fires, extract first, then add:
- *size × concerns*: past a few hundred lines AND already ≥2 separable concerns;
- *named debt*: a doc/ADR/review already says to split it (the plan is a trip-wire, not a hall pass);
- *contention*: it keeps showing up in unrelated diffs / multiple agents collide on it (see P17);
- *precedent*: a sibling was already extracted from it — conform by extracting the next one.

**When the prevailing pattern IS the anti-pattern.** P1 says conform — but conforming to a god-file
perpetuates it. Resolve P1 toward the *direction the codebase is moving* (its decomposition plan, its
already-extracted modules), not the local mess. Mechanical conformance to a 3000-line file is the
failure mode, not the rule.
**Escalate, don't silently propagate.** If conforming would *significantly* violate a higher-priority
rule (security, a frozen contract, correctness, navigability) — not just "this file is big" but "the
prevailing pattern is wrong" — neither silently conform (you'd spread a likely **systemic** defect to
every place that pattern already lives) nor silently fix it locally (a second dialect). **Stop and
raise it with the user as a probable system-level problem, and confirm the direction.** A defect
that is both prevailing and principle-violating is the highest-value kind to fix early, and the
fix-wide / fix-local / conform-for-now call is the user's, not a default you pick silently.

**Deferred decomposition is worse than none.** A split that is designed and then scheduled "later /
riskiest last" with no forcing function does not get executed: the file grows, the plan's line
numbers rot, and the written plan reads as "handled" so nobody acts. "Shippable at every step" is
satisfied by extracting **one module at a time** — it is not a license to never start. Execute the
*first cut in the same change* that diagnoses the problem (highest-leverage or lowest-coupling
module), and install a forcing function (CI size gate, "no new top-level symbols in this file",
CODEOWNERS) so the remainder can't be deferred forever.
**Stronger check:** if a review/doc names a file as a god-file, did *this* change move at least one
concern out of it — or did it just add the plan and more lines?

## P17 — Write-contention is part of blast radius
**Rule:** treat "how many unrelated changes (and concurrent authors/agents) must edit this one file"
as a first-class structural cost, alongside the read/verify radius. Split a file that is a
serialization point even when it reads fine. Co-locate by concern so unrelated work lands in
different files.
**Why:** a single large file is one lock. Sequential teams feel this as merge conflicts and an
unreadable git history; parallel-agent workflows feel it as agents clobbering each other's edits —
the same failure the read/verify radius doesn't capture, because a file can be perfectly navigable
*and* a contention bottleneck. As multi-agent development becomes the norm, this axis dominates more
of the real cost.
**Serves:** Verify (fewer cross-change collisions) + a new "Parallelize" term (independent work
proceeds independently).
**Check:** does the hot file appear in most unrelated PRs/diffs? Would two agents asked to do two
unrelated tasks both have to edit it? If yes, the concern boundaries are wrong — split by what
changes independently.

## P18 — Re-derive the real invariant before obeying a constraint as a limit
**Rule:** a stated constraint ("no build step", "stdlib only", "one global script scope",
"single-file tool") forbids a *mechanism*; it rarely forbids *all* structure. Before concluding
"this can't move / must stay one file", write the actual invariant in one line and test whether a
conforming split satisfies it.
**Why:** constraints get cargo-culted into stronger forms than they are, and the over-strong reading
freezes exactly the biggest blobs as "un-splittable" — the highest-value thing to split. Examples of
the real invariant being looser than the folklore: "no bundler" still permits concatenating asset
files at startup (pure stdlib I/O, one `<script>` emitted → one global scope preserved); "stdlib
only" still permits many imported modules; "ship one file" can be met by an assembler/build that
emits one file from many sources.
**Serves:** Load + Locate (unfreezes the blobs that hurt most) + Verify (the real invariant, once
named, is testable).
**Check:** for every "we can't split this because <constraint>", is the constraint the *actual*
invariant, or a stronger restatement? Does a concatenate/import/assemble approach honor the real one?

## P12 — Minimize indirection hops
**Rule:** every layer that merely forwards (pass-through wrapper, anemic service calling one repo
method, re-export barrel that obscures origin, "for flexibility" abstraction with one impl) costs a
read and a search false-positive. Inline single-implementation abstractions; introduce indirection
only at ≥2 real implementations or a documented seam.
**Why:** classic YAGNI/"avoid speculative generality," with a sharper agent cost model: each hop is
+1 read and +1 ambiguity.
**Serves:** Load + Locate.
**Check:** count hops from entrypoint to the code doing real work. Any interface/abstract class with
exactly one implementation that isn't a documented seam? Any barrel that breaks grep-to-definition?

## P13 — Static traceability over runtime resolution
**Rule:** prefer direct, statically-typed calls over string-keyed registries, reflection, dynamic
`getattr`/`eval`, or an event bus as primary control flow. If you must use a registry/plugin
pattern, make registration explicit and centralized so the full table reads in one file.
**Why:** runtime-resolved dispatch makes the blast radius *invisible* — the worst failure mode.
**Serves:** Verify.
**Check:** can you follow every binding by reading? Is any dynamic mapping enumerable in one place?

## P14 — Public surface vs private internals, marked
**Rule:** make what's public vs internal explicit (exports, `internal` packages, access modifiers).
The verify-radius of an *internal* change is the module; of a *public* one, the repo.
**Why:** knowing which is which is what lets you scope a change's safety at all.
**Serves:** Verify (defines the radius).
**Check:** per symbol, can you tell whether changing it is module-local or repo-wide, from
declarations alone?

## P15 — Test-first by default; tests express the spec; verification gates "done"
**Rule:** behavior with an invariant gets a test stating the invariant, and the default discipline is
to write that test *first* (red-green-refactor), not after. Tests target behavior at the boundary,
not private internals. "Done" is gated by typecheck + lint + production build + tests — not a clean
dev compile.
- **Greenfield:** test-first is the norm from the first commit; exempt only trivial glue with no
  logic (wiring, config, pure pass-through).
- **Brownfield:** four non-competing obligations — (1) **always surface** the repo's test posture
  (no suite / no CI gate / low coverage), however small the task, and offer a path; (2) **one
  *sound* testing convention** from the first test (uneven *coverage* is fine and self-resolving; an
  inconsistent test *style* is a second dialect — P1; but if the existing test pattern is itself bad
  for TDD, don't cement it — flag and recommend a better one, the prevailing-pattern-IS-the-anti-
  pattern case); (3) **decide collaboratively** — adopting/changing a convention or going wider than
  the ask is ASK + recommend (the recommendation may exceed the literal ask when architecture
  justifies it; proportionate, never a reflex), the user chooses; (4) **scale the action to the
  ask** — a narrow request gets the forward ratchet only (new code test-first + characterization
  tests before modifying untested code; no backfilling untouched code), while an explicit "bring the
  project to standard" request targets the *whole project*, driven to completion (highest-risk first;
  a CI coverage floor to lock the standard in). Tests are additive/low-risk, so — unlike a god-file
  split — a broad mandate is not capped as "incremental"; what carries over is "do the ratchet now,
  don't diagnose-and-defer" and the regression-locking forcing function.
**Why:** reviewers treat the test as the executable spec; an untested invariant is one that will
silently break, and a test written *after* the code tends to encode the bug rather than the intended
behavior. The agent uses tests as ground truth for "did my change break something." Surfacing the gap
is what lets a project *reach* TDD incrementally instead of staying untested because no single change
was ever the one to fix it.
**Serves:** Verify + Load (the test documents intended behavior + edge cases, co-located).
**Check:** for new behavior, was the test written before the code? Does each invariant have a test?
Did you state the repo's test posture, and use a single sound convention? Is the volume of test
change proportional to what the user asked for? Do the project's real verify commands pass?

## P16 — SOLID where it pays; reject the cargo cult
**Genuinely apply:** SRP (= cohesion, P2); DIP at *real* boundaries (depend on a typed contract, e.g.
an injected sender with a test seam — not on a concrete client); ISP (narrow props/params, no
god-objects).
**Cargo cult in a TS/functional shop:** interface-per-class, `IFoo`/`FooImpl` pairs, abstract base
classes, DI containers, single-implementation interfaces "for testing," Open/Closed via inheritance.
These add indirection with no second implementation.
**Why:** a senior respects SOLID's intent and is allergic to its ritual over-application. "An
interface with exactly one implementation and one caller" is the tell.
**Check:** does each interface/abstraction have ≥2 implementations or a documented seam reason?

---

## Where AI-optimal diverges from naive human practice — and how to resolve

The meta-rule: **when a classic clean-code reflex (DRY, deep abstraction, terseness) trades away
static traceability or co-change locality, keep traceability and locality.** Coupling and hidden
control flow hurt a bounded-context reader far more than duplication or verbosity do.

- **DRY vs locality.** Reflex: deduplicate every repeated snippet into a shared util. Cost: shared
  utils are coupling (wide, often invisible verify-radius) and grep noise. **Resolution:** DRY
  knowledge/contracts/domain *decisions*; tolerate duplication of *incidental* code. Extract when
  it's the same decision, not the same shape (P9).
- **Comment density / "self-documenting code."** Reflex: "good names need no comments." Cost: names
  convey *what*, not *why* or *what-must-stay-true*. **Resolution:** ban narration comments; require
  contract/invariant/rationale comments and module headers. Comment the surprises, not the syntax.
- **File count.** Reflex: one class per file, deep trees ("clean"). Cost: confetti = hops; god-files
  = window blowout. **Resolution:** group by cohesion and co-change; prefer a moderate number of
  dense, cohesive files; shallow-and-wide beats deep-and-narrow (P11).
- **Indirection depth / "design for the future."** Reflex: speculative interfaces/factories/layers.
  Cost: each is a hop with one impl — pure tax. **Resolution:** concrete by default; abstract on
  evidence (≥2 impls or a documented seam) (P12/P16).
- **Clever terseness.** Reflex: metaprogramming, behavior-rewriting decorators, dynamic dispatch.
  Cost: exactly the runtime magic an agent can't trace. **Resolution:** prefer boring, explicit,
  statically-traceable code even at some verbosity cost (P4/P13).
- **Layered (horizontal) vs vertical slices.** Reflex: `controllers/ services/ models/`. Cost: one
  feature smeared across the whole tree. **Resolution:** primary axis = feature/domain; technical
  layering lives *inside* the feature folder (P2).
- **Config flexibility vs determinism.** Reflex: many env layers, runtime-computed config. Cost:
  effective behavior can't be read from files. **Resolution:** static, readable config; enumerate
  flags with defaults in one file. Flexibility that can't be read is a verify liability.
