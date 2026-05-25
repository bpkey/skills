# Consumer Assistant & Search — I/O 2026

The Gemini app (personal assistant) and Google Search AI features. For pricing/tier gating see `pricing-and-access.md`. Status tags defined in `SKILL.md`.

Stated scale at I/O 2026: Gemini app **900M MAU** (up from 400M), AI Overviews **2.5B+ MAU**, AI Mode **1B+ MAU**.

## Contents
**Gemini app:** [Gemini Spark](#gemini-spark) · [Daily Brief](#daily-brief) · [Gemini Live](#gemini-live-redesigned) · [Neural Expressive redesign](#neural-expressive-redesign) · [Compute-used limits](#compute-used-usage-model)
**Search:** [AI Mode](#ai-mode-on-gemini-35-flash) · [New Search box](#new-search-box) · [Search Agents](#search-agents-information-agents) · [Generative UI](#generative-ui-in-search) · [Custom Search experiences](#custom-search-experiences) · [Personal Intelligence](#personal-intelligence) · [Ask YouTube](#ask-youtube) · [Universal Cart](#universal-cart)

> Models that power these (Gemini 3.5 Flash, Gemini Omni) live in `foundation-models.md`.

---

# Gemini app

## Gemini Spark
- **Category:** gemini-app (personal agent)
- **What it is:** A 24/7 personal AI agent that navigates your digital life and takes actions on your behalf (works even when devices are offline). Roadmap: email/text access, custom sub-agents, payment authorization with budget controls.
- **What it's for:** Autonomous, ongoing personal task execution across your apps.
- **When to use it / vs alternatives:** For delegated multi-step personal tasks, not one-off prompts. This is the **2026 successor branding** to the older "universal assistant / Astra / Mariner" narrative.
- **Status:** **Waitlist/Gated** — Beta, rolling out to **$200 AI Ultra** subscribers in the U.S. ~late May 2026.
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/
- **Announced:** May 19, 2026

## Daily Brief
- **Category:** gemini-app
- **What it is:** An agent that organizes and prioritizes your day into a personalized digest (email/calendar/tasks) based on your goals.
- **What it's for:** A morning prioritization summary across connected Google apps.
- **When to use it / vs alternatives:** Passive daily triage; requires connecting Google apps.
- **Status:** **GA (gated by region)** — rolling out from May 19 to all Google AI subscribers (18+), U.S. first.
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/
- **Announced:** May 19, 2026

## Gemini Live (redesigned)
- **Category:** gemini-app
- **What it is:** Enhanced real-time voice conversation — opens immediately and inline, with a faster/smarter model and reduced background-noise interference (regional dialect options coming).
- **What it's for:** Natural spoken back-and-forth with Gemini.
- **When to use it / vs alternatives:** Hands-free / voice interaction vs typed prompts.
- **Status:** **GA** — available now in the updated Gemini app.
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/
- **Announced:** May 19, 2026

## Neural Expressive (redesign)
- **Category:** gemini-app (UI)
- **What it is:** A new design language — fluid animations, vibrant colors, new typography, haptics; a pill-shaped prompt box with a single "+" Tools menu and fullscreen navigation drawer.
- **What it's for:** Refreshed Gemini app UI (not a capability change).
- **Status:** **GA** — rolling out to Android, iOS, and web.
- **Source:** https://9to5google.com/2026/05/19/google-io-2026-news/ *(press-sourced)*
- **Announced:** May 19, 2026

## Compute-used usage model
- **Category:** gemini-app (limits)
- **What it is:** The Gemini app is moving from daily prompt limits to a **"compute-used"** model that factors prompt complexity, features, and chat length; limits refresh every 5 hours up to a weekly cap.
- **What it's for:** Replacing fixed daily prompt caps (relevant when explaining why limits behave differently).
- **Status:** **Rolling out** (transition announced).
- **Source:** https://9to5google.com/2026/05/19/google-io-2026-news/ *(press-sourced)*
- **Announced:** May 19, 2026

---

# Search

## AI Mode (on Gemini 3.5 Flash)
- **Category:** search
- **What it is:** Google's most powerful AI Search experience, now upgraded to Gemini 3.5 Flash; searches across text, images, files, videos, and Chrome tabs (1B+ MAU).
- **What it's for:** Conversational, multimodal, reasoning-heavy search.
- **When to use it / vs alternatives:** Complex, multi-part questions beyond a classic keyword query.
- **Status:** **GA** — upgraded May 19, global.
- **Source:** https://blog.google/innovation-and-ai/sundar-pichai-io-2026/
- **Announced:** May 19, 2026

## New Search box
- **Category:** search
- **What it is:** Billed as the "biggest upgrade to the Search box in over 25 years" — multimodal inputs integrated with AI Overviews and a seamless flow into AI Mode follow-ups.
- **What it's for:** Asking by text/image/file/video from one box.
- **When to use it / vs alternatives:** The default Search entry point.
- **Status:** **GA** — live May 19, worldwide (desktop/mobile).
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/
- **Announced:** May 19, 2026

## Search Agents (Information Agents)
- **Category:** search
- **What it is:** Customizable, persistent agents that monitor web/news/social/real-time data 24/7 and send synthesized updates on topics you specify.
- **What it's for:** Standing monitoring / research tasks.
- **When to use it / vs alternatives:** Ongoing tracking vs a one-time search.
- **Status:** **Announced-only** — rolling out summer 2026, first to AI Pro/Ultra.
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/
- **Announced:** May 19, 2026

## Generative UI in Search
- **Category:** search
- **What it is:** On-the-fly custom layouts, interactive visuals, tables, graphs, or simulations built with Antigravity + Gemini 3.5 Flash agentic coding.
- **What it's for:** Dynamically generated, interactive answers.
- **When to use it / vs alternatives:** When a static text answer is insufficient (comparisons, simulations).
- **Status:** **Announced-only** — rolling out summer 2026, free for everyone.
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/
- **Announced:** May 19, 2026

## Custom Search experiences
- **Category:** search
- **What it is:** Personalized dashboards / trackers ("Mini Apps") for ongoing projects (wedding planning, moving, etc.).
- **What it's for:** Reusable, task-specific Search surfaces.
- **When to use it / vs alternatives:** Multi-session projects vs single queries.
- **Status:** **Announced-only** — "coming months," starting with subscribers (U.S.).
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/
- **Announced:** May 19, 2026

## Personal Intelligence
- **Category:** search (also surfaces in Gemini)
- **What it is:** A secure, opt-in connection to Gmail and Google Photos (Calendar soon) that personalizes answers, with transparency/control framing.
- **What it's for:** Personalized, context-aware results grounded in your own data.
- **When to use it / vs alternatives:** When you want answers based on your own Google data. This (plus Gemini Spark) is the 2026 home for the assistant capabilities once branded "Project Astra."
- **Status:** **GA (expanding)** — to ~200 countries / 98 languages, no subscription required.
- **Source:** https://blog.google/innovation-and-ai/sundar-pichai-io-2026/
- **Announced:** May 19, 2026

## Ask YouTube
- **Category:** search
- **What it is:** Conversational search that compiles relevant videos/Shorts into a structured response.
- **What it's for:** Finding answers across video content.
- **When to use it / vs alternatives:** Video-first questions vs text Search.
- **Status:** **Preview/Gated** — rolling out this month as an experiment for a subset of U.S. English desktop searchers; per 9to5Google, available to YouTube Premium subscribers via youtube.com/new.
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/ ; https://9to5google.com/2026/05/19/google-io-2026-news/
- **Announced:** May 19, 2026

## Universal Cart
- **Category:** search (shopping)
- **What it is:** An intelligent cross-surface shopping cart/hub — add from Search/Gemini/YouTube/Gmail, with background price monitoring, stock alerts, compatibility flagging, Google Wallet payment optimization, and checkout via a Universal Commerce Protocol.
- **What it's for:** Unified, agent-assisted shopping across Google.
- **When to use it / vs alternatives:** Multi-retailer carts and deal tracking vs per-site checkout.
- **Status:** **Announced-only** — rolling out summer 2026 across Search and the Gemini app (U.S.); YouTube and Gmail to follow.
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/
- **Announced:** May 19, 2026

---

## Disambiguation
- **Project Astra** was the I/O **2025** "universal assistant" research banner. In 2026 the consumer agent story is **Gemini Spark** + **Personal Intelligence** — no new Astra announcement was found for I/O 2026.
- **Project Mariner** (web-browsing agent) appears in 2026 only as a **$200 AI Ultra exclusive**, not a fresh reveal; its detailed feature descriptions are I/O 2025 material.
- See `context-and-disambiguation.md` for the full list.
