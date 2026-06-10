# Anti-patterns — the DO-NOT catalog

The specific moves that get agent-generated architecture rejected by senior reviewers. Each entry:
**the smell → why it's rejected → the rule that prevents it.** The highlights line in `SKILL.md` is
the index into this list.

---

1. **Premature / speculative abstraction.** Generic `BaseService`, `<T>` everywhere, options bags
   for one caller, an interface "for when we have more than one."
   → *Why:* couples things that only looked alike; the wrong abstraction is harder to undo than
   duplication, and it spreads into the type system and every call site.
   → *Rule:* no abstraction without the rule of three AND a present second caller. Inline first;
   extract on demand.

2. **Design-pattern theater.** Factory / Strategy / Observer / Singleton wrappers around what a plain
   function or module already does.
   → *Why:* indirection with no payoff; the reader pays a hop to reach trivial behavior.
   → *Rule:* name the pattern and justify the second concrete need in one sentence, or don't use it.
   Default to a plain function/module.

3. **Intra-repo inconsistency (a second dialect).** New code in a different naming/error/folder style
   than its neighbors.
   → *Why:* the single most common rejection — locally correct, globally foreign. Forces every reader
   to hold two mental models.
   → *Rule:* conform first; cite the sibling you matched. If you must deviate, say why in one line and
   flag it.

4. **God-files.** A 600-line route/component/util doing routing + validation + business logic +
   formatting.
   → *Why:* you load the whole thing to change ten lines; the relevant slice is buried.
   → *Rule:* one responsibility per file; split along the existing concern map, matching granularity.

5. **Confetti of micro-files.** Twelve one-export files where the codebase keeps cohesive modules.
   → *Why:* assembling one behavior takes many hops and many search hits.
   → *Rule:* match the codebase's file granularity; co-locate things that change together; don't split
   for splitting's sake.

6. **Reinventing existing utilities.** A hand-rolled debounce / scroll-lock / date helper / HTTP
   client when one already exists in `lib/` or the deps — or a custom tool when an official one ships.
   → *Why:* duplicate maintenance, drift, and a second way to do one thing.
   → *Rule:* grep `lib/` and the deps before writing a helper; flag the official tool before building
   a custom one (per the global rule). Reuse or ask.

7. **Ignoring established idioms / reintroducing a removed pattern.** Adding `@media (prefers-color-
   scheme)` to a single-signal `[data-theme]` codebase; hardcoding `/public` paths; inlining
   user-facing strings.
   → *Why:* documented conventions are binding; "this was deliberately removed" rules exist because
   the pattern already caused a bug once.
   → *Rule:* read the docs (CLAUDE.md, skills) for the surface you're touching; never reintroduce a
   pattern a doc says was removed.

8. **Unrequested infra / scope creep.** Watchdogs, retry layers, caching, feature flags, extra headers
   nobody asked for.
   → *Why:* adds moving parts, surface area, and footprint the user didn't request and now must
   maintain.
   → *Rule:* build only the stated requirement; surface anything extra as a question; never bake it in
   unilaterally.

9. **Comment noise narrating the code.** `// loop over users`, `// set the value`.
   → *Why:* restates what the code already says; rots out of sync; adds tokens with no signal.
   → *Rule:* comments explain *why* (the non-obvious constraint, the "this exists because we shipped X
   once") and state invariants — never *what*. Delete any comment a competent reader doesn't need.

10. **Leaky abstractions.** A "repository" that returns the raw DB row; a "client" wrapper whose
    callers must know its internals.
    → *Why:* the boundary doesn't actually encapsulate, so it's pure cost — a hop that hides nothing.
    → *Rule:* a boundary fully encapsulates or doesn't exist. The return type must not expose the
    implementation substrate. If it leaks, delete the wrapper and use the thing directly.

11. **Hidden global state.** Module-level mutable singletons, ambient caches, env read deep in business
    logic.
    → *Why:* spooky action at a distance; the verify-radius becomes the whole program.
    → *Rule:* no mutable module-level state; read config/env at the boundary and pass it inward.

12. **Silent failure / swallowed errors.** Empty catch, `?.` chains hiding a missing-data bug, defaults
    masking a contract break.
    → *Why:* works in the happy path, silent in prod — the failure no test caught.
    → *Rule:* every catch handles/translates/propagates explicitly; never paper over a missing invariant
    with a default.

13. **Convention drift in docs.** Adding a new data shape / page / processor but not the renderer / the
    sitemap / the privacy disclosure / the doc table.
    → *Why:* the code and its documented invariant fall out of sync — content silently disappears, or a
    legal/SEO surface goes stale.
    → *Rule:* if a change touches a documented invariant, update code, doc, and verification in the same
    change, or stop and flag it.

14. **Type-checker silencing.** `any` / `as` to force a cast / `!` to dodge a real null /
    `@ts-ignore` / `@ts-expect-error` to pass the build.
    → *Why:* a reviewer reads it as "gave up here" and audits everything downstream; it defeats the
    spec the type was supposed to be.
    → *Rule:* casts only narrow post-check; fix the root cause, don't silence it. CI is stricter, not
    looser, than local dev.

15. **Runtime-resolved dispatch the reader can't follow.** String-keyed handler maps, reflection,
    convention-based routing computed from a string, event buses as primary control flow.
    → *Why:* makes the blast radius invisible — you can't see what a change breaks.
    → *Rule:* prefer static dispatch; if a registry is genuinely needed, keep the full mapping
    enumerable in one file.

16. **Growing a known god-file instead of splitting it (conformance as the excuse).** The target
    file is already huge and mixes concerns; you add your function to it "to match the prevailing
    pattern." Every author does this, so it never stops growing.
    → *Why:* P1 (conform) is being used to justify perpetuating an anti-pattern. A god-file is
    *built* one conformant addition at a time — that is the mechanism, not a defense.
    → *Rule:* check the split trip-wires (P11) before adding to an existing file; when the prevailing
    pattern IS the anti-pattern, conform to the codebase's *intended direction* (decomposition plan,
    already-extracted siblings), and extract before you add.

17. **Deferring a written decomposition plan with no forcing function.** A review/ADR/`ARCHITECTURE.md`
    diagnoses the god-file and lays out the split — then schedules it "later / riskiest last," and the
    change ships adding *more* lines plus the plan.
    → *Why:* the plan never executes — the file keeps growing, the plan's line-number map rots, and
    the written plan reads as "handled," so nobody acts. A planned-but-unexecuted split is worse than
    no plan. ("Shippable at every step" is one extraction at a time, not zero extractions ever.)
    → *Rule:* execute the *first cut in the same change* that diagnoses the problem (highest-leverage
    or lowest-coupling module), and install a forcing function (CI size gate / "no new top-level
    symbols here" / CODEOWNERS) so the rest can't be deferred indefinitely.

18. **Over-reading a real constraint into "un-splittable."** "No bundler, so the whole frontend must
    be one string"; "stdlib only, so it must be one file"; "single-file tool, so it can't be modules."
    → *Why:* the constraint forbids a *mechanism* (a bundler, a pip dep), not *all* structure. The
    over-strong reading freezes the biggest blob — the highest-value thing to split — as off-limits.
    → *Rule:* state the actual invariant in one line and test a conforming split against it (P18).
    "No bundler" still permits concatenating asset files at startup → one `<script>` → one global
    scope. "Stdlib only" still permits many imported modules.
