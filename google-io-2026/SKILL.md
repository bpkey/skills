---
name: google-io-2026
description: A categorized, sourced reference catalog of every AI product, model, and feature Google announced at Google I/O 2026 (May 19–20, 2026), plus the pre-existing products they build on. Use this whenever the user asks "what is <some Google AI product>", "which Google AI tool should I use for <task>", "what did Google announce at I/O 2026", "what's the difference between Gemini 3.5 Flash and Pro / Antigravity vs the old Gemini CLI / the AI Plus vs Pro vs Ultra tiers", or is generally trying to make sense of Google's AI landscape (Gemini, Search AI, Workspace AI, Android XR, dev/agent tooling). Also trigger when the user is unsure whether a product (Project Astra, Mariner, Moohan, NotebookLM, Veo) was actually an I/O 2026 reveal — this skill records what was NOT announced there to clear up the common press confusion. Reference-only: it answers and points to official sources, it does not modify anything.
---

# Google I/O 2026 — AI Landscape Catalog

A reference for navigating everything Google announced at **Google I/O 2026** (keynote **May 19, 2026**, Shoreline Amphitheatre; on-demand sessions from May 21) — and the older products those announcements build on. It exists to answer two kinds of question quickly:

- **"What is X?"** — a sourced one-paragraph entry per product (what it is, what it's for, status, link).
- **"Which one do I use for Y?"** — the decision guides below and the "when to use it / vs alternatives" line on each entry.

## How to use this skill

1. **Figure out the domain** from the question and read **only** the relevant reference file (routing table below). Don't preload everything — each file is self-contained.
2. For "which should I use" questions, start with the **Decision guides** section here, then open the domain file for detail.
3. **Always cite the official source** from the entry when you answer, and **state the status** (a thing "announced at I/O" is often not yet shipped). Use the status legend below.
4. If the user attributes something to I/O 2026 that wasn't there, check `references/context-and-disambiguation.md` before agreeing — Google reuses brand names heavily and the press routinely mixes up I/O 2025/2026.

## ⚠️ Sourcing & freshness caveat — read before answering

This catalog was compiled on **2026-05-25**, days after the event, from official Google sources (blog.google, deepmind.google, cloud.google.com/blog, developers.googleblog.com, firebase.blog) cross-checked against reputable press (The Verge, TechCrunch, 9to5Google, The Decoder). Two consequences:

- **Statuses drift fast.** Many items were "rolling out next month" or "coming summer 2026" at announcement. Before stating something is available, re-check the linked source. When in doubt, say "as of I/O 2026 it was <status>."
- **Some figures are press-sourced, not official** (notably the AI Plus / AI Pro exact prices). These are flagged inline. Don't present a press-sourced number as an official Google figure.

If a question needs a status more current than this snapshot, fetch the linked official page.

## Status legend

| Tag | Meaning |
|-----|---------|
| **GA** | Generally available / rolling out to everyone now |
| **Preview** | Public preview / beta / Labs — usable but not final |
| **Waitlist/Gated** | Limited: trusted testers, specific tier, or specific region |
| **Announced-only** | Shown at I/O but "coming soon" / not yet usable |
| **Research** | Research prototype, not a product you can build on |
| **Context** | Pre-existing product included for landscape context (not an I/O 2026 reveal) |

## The landscape at a glance

Google I/O 2026's throughline was the shift **from AI tools to AI agents**, anchored by the **Gemini 3.5** model family and **Gemini Omni** (any-input-to-video), with **Antigravity 2.0** as the new agent-first developer surface and **Gemini Spark** as the consumer personal agent.

| Domain | Headliners | Reference file |
|--------|-----------|----------------|
| Foundation models & generative media | Gemini 3.5 Flash/Pro, Gemini Omni, Gemma 4, Nano Banana | `references/foundation-models.md` |
| Developer & cloud / agent building | Antigravity 2.0, Managed Agents, AI Studio, ADK 2.0, A2A, Gemini Enterprise Agent Platform | `references/developer-and-cloud.md` |
| Consumer assistant & Search | Gemini app (Spark, Daily Brief, Live), AI Mode, Search Agents, Universal Cart | `references/consumer-and-search.md` |
| Workspace, Android & XR | AI Inbox, Gmail/Docs Live, Google Pics, Gemini in Android 17, Android XR glasses | `references/workspace-android-xr.md` |
| Pricing & access tiers | AI Plus / AI Pro / AI Ultra ($100 & $200) | `references/pricing-and-access.md` |
| Context & disambiguation | What was NOT at I/O 2026 (Astra, Mariner, Moohan, Veo, Jules…), prior products | `references/context-and-disambiguation.md` |

## Routing table — load on demand

| If the question is about… | Read |
|---------------------------|------|
| Models, Gemini versions, video/image/music generation, Gemma, DeepMind research | `references/foundation-models.md` |
| APIs, AI Studio, Vertex/Gemini Enterprise, coding agents, IDEs, ADK/A2A, Firebase, CLIs | `references/developer-and-cloud.md` |
| The Gemini app, personal agents, Google Search AI features, shopping | `references/consumer-and-search.md` |
| Gmail/Docs/Keep AI, Google Pics, Android 17, smart glasses / headsets | `references/workspace-android-xr.md` |
| "How much does it cost", what's free vs paid, which tier unlocks what | `references/pricing-and-access.md` |
| "Was X announced at I/O 2026?", Astra/Mariner/Moohan/NotebookLM/Veo/Jules status | `references/context-and-disambiguation.md` |

## Decision guides

Short answers to the most common "which one" questions. Open the linked file for the full entry.

### Which Gemini model?
- **Gemini 3.5 Flash** (GA) — the default for almost everything: fast, cheap, strong at coding and agentic tasks; beats the prior 3.1 Pro on those benchmarks. Use unless you specifically need more reasoning depth.
- **Gemini 3.5 Pro** (announced-only, ~June 2026) — the heaviest reasoning/science/engineering tasks. Reach for it only when Flash isn't deep enough.
- **Gemini Omni / Omni Flash** — when the *output* is video (or other media), generated/edited from mixed inputs. Not a text-chat model.
- **Gemma 4** — when you need **open weights / self-hosting** instead of the API-only Gemini line.
→ `references/foundation-models.md`

### Which way to build an agent (developer)?
- **Google AI Studio + Antigravity** — fastest path from prompt to a working app/prototype; start here for hobby/prototype.
- **Managed Agents (Gemini API)** — you want a *hosted* agent runtime (sandboxed Linux per agent) without managing infrastructure.
- **ADK 2.0** (incl. ADK Kotlin for on-device) — code-first, graph-based, maximum control; build custom agent meshes.
- **Gemini Enterprise Agent Platform** (the rebranded Vertex AI) — enterprise scale with governance, identity, eval, and security.
- **A2A protocol** ties these together so agents from different frameworks interoperate.
- ⚠️ **Gemini CLI is being retired** → replaced by **Antigravity CLI**; it stops serving Pro/Ultra/free users **June 18, 2026**. Don't recommend Gemini CLI for new work.
→ `references/developer-and-cloud.md`

### Which subscription tier (consumer)?
- **Free** — basic Gemini app + AI Overviews/Mode in Search; much of the new Search generative UI is free.
- **AI Plus** (~$7.99/mo, *press-sourced*) — Gemini Omni, 3.5 Flash, and (US) AI Inbox + Daily Brief.
- **AI Pro** (~$19.99/mo, *press-sourced*) — higher limits, the "Live" Workspace features, now bundles YouTube Premium Lite.
- **AI Ultra $100/mo** (new mid tier) — 5× Pro usage limits, 20 TB, priority Antigravity, YouTube Premium.
- **AI Ultra $200/mo** (cut from $250) — 20× limits; exclusive: **Gemini Spark**, **Project Genie**, and (per press) **Project Mariner**.
→ `references/pricing-and-access.md`

### Image / video / media generation — which tool?
- **Gemini Omni** — conversational video generation & editing (Gemini app, Flow, YouTube Shorts).
- **Nano Banana** — image generation, embedded in **Google AI Studio** (for app UI) and **Google Pics** (Workspace image creation/editing).
- For Veo / Imagen / Lyria specifically, see the disambiguation file — those were **2025** launches, not new at I/O 2026.
→ `references/foundation-models.md` and `references/workspace-android-xr.md`

## Maintaining this skill

When updating after a later event or status change: keep the per-entry schema (**What it is / What it's for / When to use it / Status / Source / Announced**), keep official sources as the primary citation, and keep press-sourced facts explicitly flagged. If an "announced-only" item ships, update its status and date rather than deleting the history.
