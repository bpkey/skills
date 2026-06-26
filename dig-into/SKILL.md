---
name: dig-into
description: Progressively teach the user about a topic — a new codebase, a library or system, or an abstract concept — starting at the highest level and descending one controlled layer at a time, calibrated to what they already know so they are never overwhelmed and never lost. Use this whenever the user invokes /dig-into, or says things like "help me understand this codebase", "walk me through how X works", "onboard me to this repo", "I'm new here, where do I start", "explain this project", "teach me about <topic>", "give me the lay of the land", or otherwise wants a guided, paced, interactive explanation rather than one big info-dump. Especially apt when onboarding to an unfamiliar project where the user already knows some underlying concepts but not others — it checks in at every step so they choose what to go deeper on, skip what they already know, and absorb each layer before moving on.
---

# Dig Into

Guide someone from "I know nothing about this" to "I understand it at the depth I need" — gradually, one layer at a time, without ever drowning them.

```
/dig-into <topic> [startingPoint]
```

The job is not to *explain the topic*. It's to **hand over understanding at a pace the user controls** — starting high, going deep only where they want it, and only as fast as they can absorb. A good run leaves the user feeling oriented and in command: never lost, never flooded, never bored by things they already knew.

## Why this skill exists

The default way to answer "explain X" is the **info-dump**: a wall of text covering everything at every level at once. It feels thorough but it overwhelms — the reader can't tell what matters, can't see the shape of the whole, and can't stop you to say "I already know that part."

This skill replaces the dump with a **guided descent**:

- **Top-down.** Start with the shape of the whole before any detail, so the user always has a frame to hang new facts on.
- **One layer per step.** Reveal a single level, then stop and check in. Descending several levels at once is how people get lost.
- **Calibrated.** Track what the user already knows and skip it. Re-explaining known basics is condescending and wastes their attention; silently assuming knowledge they lack loses them.
- **User-steered.** Every descent is the user's choice — what to expand, what to skip, when they've had enough.

Think of it like reading a map: first the continents, then — only where the user points — the countries, then the cities. They always know where they are, and can always say "not that part, this part."

## Arguments

- **`<topic>`** — what to dig into. Three broad kinds:
  - a **codebase or project** — a repo, a directory, "this project", a path *(recon the code, then teach from it)*;
  - a **library, tool, system, or product** — "how Kubernetes scheduling works", "the Stripe billing model";
  - an **abstract concept** — "OAuth", "database isolation levels", "diffusion models".
- **`[startingPoint]`** *(optional)* — a hint about where to begin, interpreted flexibly:
  - a **sub-area** to focus on ("dig into the auth flow"),
  - a **level** to start at ("I know the basics, start mid-level"),
  - or an **entry point** file/path ("start from `src/server.ts`").

  If absent, start from the very top and let calibration find the right altitude.

## Step 0 — Frame the topic and build the map (quietly, once)

Before saying anything, work out *what kind of topic this is* and *what shape it has*. This is internal prep — don't narrate it.

**Decide the kind.** Treat it as a **codebase/project** if the topic names a path, a repo, "this project/codebase", a file, or the conversation is already about code. Otherwise treat it as a **concept/system**.

**For a codebase,** do *cheap, shallow* recon — just enough to draw the top-level map, not a deep audit:

- Read `README`, and any `ARCHITECTURE.md`, `GLOSSARY.md`, `CONTRIBUTING.md`, or `docs/` that exist — they often hand you the map for free. Use them when present, degrade gracefully when not.
- Skim the top-level directory layout, the entry points (`main`/`index`, server bootstrap, CLI root), and key config (`package.json` / `pyproject.toml` / `go.mod`, etc.).
- Use Glob/Grep/Read, or an Explore subagent if available. Resist deep-diving — you only need the breadth and the major boundaries right now.

**For a concept/system,** build the map from your own knowledge. Reach for a quick web lookup only if the topic is fast-moving and you're genuinely unsure — don't turn Step 0 into a research project.

**Output (internal):** a **layered map** — the handful of top-level areas (breadth) and a rough sense of how deep each one goes. This is the tree you'll descend. Keep it; you'll show a compact version to the user and update it as you go.

## Step 1 — Lay of the land, and calibrate (first pass)

Now talk to the user. Two things happen at once: you give them the bird's-eye view, and you find out where they already stand.

1. **Orient briefly.** A few sentences on what the topic *is* and what it's *for* — the frame. Keep it short; this is the 10,000-foot view, not a lesson.
2. **Show the map.** A compact outline of the top-level areas — the table of contents for the descent. This is what keeps the user from getting lost: they see the whole before choosing a part.
3. **Calibrate and get direction in one question.** Ask which areas they already know (so you skip them) and which they want to dig into. Use the host's choice UI (see *Interaction*). Pre-bias with `[startingPoint]` if given, and make clear they can also just answer in their own words.

Example of the first message:

> **PostgreSQL's MVCC** at a glance — how Postgres lets many transactions read and write the same rows at once without blocking each other, by keeping multiple versions of each row.
>
> The territory:
> - **A. Row versions & visibility** — how a row gets multiple versions, and who sees which
> - **B. Transaction IDs & snapshots** — how Postgres decides visibility
> - **C. VACUUM & bloat** — cleaning up dead versions
> - **D. Isolation levels on top** — read committed vs repeatable read vs serializable
>
> *(then a checkbox question: which of these do you already know, and which should we dig into first?)*

## The descent loop

For each area the user wants, descend **one level at a time**, repeating this loop:

1. **Teach one layer.** Explain the current node at the current altitude — and *only* that. Keep it digestible: a few short paragraphs or a tight list, framing before detail. If you feel a wall of text coming, that's the signal to stop and make "want more on this?" the next step instead of writing it all now.
   - **Ground it.** For code, point at the real artifacts — `path/to/file.ts:42`, the actual function and type names — so the user can go look. For a concept, give a crisp mental model and one concrete example.
2. **Orient, then check in.** Show a short "you are here" breadcrumb so the user never loses the thread, then ask what to do next. Tailor the menu to the moment — the choice UI shows a few options plus a free-text escape, so offer only the moves that make sense here:
   - **Go deeper here** — descend one level into this node.
   - **Expand a specific part** — when the node split into several sub-parts, let them pick which (multi-select).
   - **Move on** — to a sibling area, or back up a level.
   - **Skip — I know this** — mark it known and move along.
   - **Stop — I've got enough** — wrap up.
3. **Act, and update your read of the user.** Honor skips (don't re-explain that ground later). When they ask for more depth somewhere, note that they want detail in this area and raise your default altitude accordingly. Their free-text always wins over the menu — if they redirect, follow them.
4. **Descend only one level.** Don't unfold a whole subtree at once, however tempting. The control and the pacing *are* the value.

### The "you are here" breadcrumb

At each check-in, show where they are — what's done, where they are, what's left — so orientation is never in doubt:

```
PostgreSQL MVCC
  ✓ A. Row versions & visibility
  → B. Transaction IDs & snapshots      ← you are here
        • xid, xmin / xmax              (just covered)
        • snapshots                     (go deeper?)
    C. VACUUM & bloat                   (not yet)
    D. Isolation levels                 (not yet)
```

Keep it lightweight — a few lines, not an elaborate diagram.

## Pacing — how not to overwhelm

These habits are what make the difference. They're judgment calls, not rigid rules; the goal is a user who feels in control and is actually absorbing what you hand them.

- **One descent per confirmed step.** The single most important habit — jumping levels is exactly how people get lost.
- **Small chunks.** Each layer should be absorbable in one read. When in doubt, say less and offer "more?".
- **Frame before detail.** Give the shape before the specifics, and re-orient (breadcrumb, a one-line recap of where we are) before going deeper.
- **Calibrate continuously.** Match vocabulary and altitude to what the user has shown they know. If they breezed past the basics, talk to them as a peer; if a term made them pause, define the next one. Don't re-explain anything they marked known.
- **Follow the user.** The menu is a convenience, not a track. If they type "wait, go back to the snapshot thing", that beats whatever you were about to do.
- **Check understanding lightly, not as a quiz.** A casual "make sense so far?" keeps them comfortable; a pop quiz makes them defensive.

## Ending

When the user signals they've had enough — or you've covered everything they wanted — close cleanly:

- A tight **recap** of what you covered (the ✓ nodes), with the through-line.
- What's **still unexplored** in the map, so they know what's left.
- Since each run starts fresh, mention they can re-invoke `/dig-into <topic>` later and skip what's already covered to resume where they stopped.

## Interaction — rendering the choices

The check-ins are the heart of this skill, so use the best choice UI the environment offers:

- **In Claude Code,** use the `AskUserQuestion` tool. It renders real single-select and multi-select (checkbox) choices and always includes a free-text "Other" option — exactly the calibrate-and-steer interaction this skill needs. Use multi-select for "which of these areas?" and single-select for "what next?".
- **In other AI clients** without that tool, fall back to a short **numbered list** or a plain **y/n** question in the message, and let the user reply in text.

Either way, keep each question focused on the one decision in front of the user, and always leave room for them to answer in their own words.

## Two quick examples

**Codebase onboarding** — *"/dig-into this repo"* on an unfamiliar web app:

1. *Step 0 (silent):* read README + structure; map = Frontend / API / Data model / Auth / Build & deploy.
2. *Step 1:* a one-paragraph "what this app is", show those five areas, ask (checkboxes) which they know vs. want. The user knows Frontend, picks Auth + Data model.
3. *Descent:* teach Auth at a high level (the flow, `src/auth/session.ts:20`), breadcrumb, check in. The user picks "go deeper → token refresh"; descend one level into refresh, grounded in the real function. Continue, or move to Data model on their cue.

**Abstract concept** — *"/dig-into OAuth, I know the basics"*:

1. *Step 0 (silent):* map = Roles & tokens / The grant flows / Scopes & consent / Common pitfalls.
2. *Step 1:* a one-line frame, show the map; `[startingPoint]` "I know the basics" → pre-skip Roles & tokens and start mid-level. Ask which flow matters to them.
3. *Descent:* they pick Authorization Code + PKCE; teach that one flow as a mental model plus a concrete request/response, breadcrumb, then offer to go deeper into PKCE specifically or compare it with another flow.
