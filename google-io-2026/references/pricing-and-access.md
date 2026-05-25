# Pricing & Access Tiers — I/O 2026

Consumer subscription tiers (Google One AI plans) and what each unlocks, plus the developer/enterprise free-access notes. Status tags defined in `SKILL.md`.

## ⚠️ What's official vs press-sourced
The official Google One post (https://blog.google/products-and-platforms/products/google-one/google-ai-subscriptions/) confirmed only the two **AI Ultra** prices ($100 new, $200 reduced from $250). The **AI Plus ($7.99)** and **AI Pro ($19.99)** monthly prices come from reputable **press** (The Decoder, Yahoo/Tom's Guide), not the official post. Flag this when quoting those two numbers.

## Consumer tiers

| Tier | Price/mo | Highlights | Source basis |
|------|----------|-----------|--------------|
| **Free** | $0 | Basic Gemini app; AI Overviews + AI Mode in Search; much of the new Search **Generative UI** is free for everyone | official |
| **Google AI Plus** | **~$7.99** | Gemini Omni, Gemini 3.5 Flash; (US) **AI Inbox** + **Daily Brief** | price = press |
| **Google AI Pro** | **~$19.99** | Higher limits; the Workspace **"Live"** features (Gmail/Docs Live, Talk to Keep); bundles **YouTube Premium Lite** (~$8.99 value) at no extra charge | price = press |
| **Google AI Ultra $100** *(new mid tier)* | **$100** | 5× Pro usage limits in Gemini app/Antigravity; **20 TB** storage; priority Antigravity; YouTube Premium | official |
| **Google AI Ultra $200** *(cut from $250)* | **$200** | 20× Pro limits; **exclusive: Gemini Spark** (US), **Project Genie** (global, 18+), and per press **Project Mariner** | official (price); Mariner = press |

### Notes
- **Gemini Spark** (the 24/7 personal agent) is the headline lock behind the **$200 Ultra** tier (US, beta, ~late May 2026).
- **Project Genie** (interactive world-model environments) is a **$200 Ultra** perk, global, 18+.
- **AI Inbox / Daily Brief** started on Ultra and are expanding down to Plus/Pro (US first).
- The Gemini app is also moving to a **"compute-used"** limit model (refreshes every 5 hours, weekly cap) instead of fixed daily prompt caps — see `consumer-and-search.md`.

## Developer / enterprise access

- **Gemini 3.5 Flash** — GA in the Gemini API via **Google AI Studio** (free tier available for prototyping; paid tiers for production).
- **Gemini Enterprise Agent Platform** (formerly Vertex AI) — new **Starter Tier**: no billing required, first two app deployments free. See `developer-and-cloud.md`.
- **Gemini CLI deprecation cost angle:** after **June 18, 2026**, Gemini CLI / Gemini Code Assist IDE extensions stop serving AI Pro/Ultra and free users; Gemini CLI continues only for **paid Gemini Enterprise Agent Platform API keys**. Use Antigravity CLI instead.

## Sources
- https://blog.google/products-and-platforms/products/google-one/google-ai-subscriptions/ (official tiers)
- https://the-decoder.com/google-overhauls-its-ai-subscriptions-at-i-o-2026-with-three-tiers-starting-at-10-a-month/ (press, plan structure + prices)
- https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/ (feature-to-tier mapping)
