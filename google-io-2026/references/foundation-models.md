# Foundation Models & Generative Media — I/O 2026

Models, model families, and generative-media systems. For where to *use* these (APIs, app, etc.) see the other reference files. Status tags defined in `SKILL.md`.

## Contents
- [Gemini 3.5 Flash](#gemini-35-flash)
- [Gemini 3.5 Pro](#gemini-35-pro)
- [Gemini Omni / Omni Flash](#gemini-omni--omni-flash)
- [Gemma 4](#gemma-4)
- [Nano Banana](#nano-banana)
- [DeepMind science research stack](#deepmind-science-research-stack)
- [Genie 3](#genie-3)
- [Context window & SynthID notes](#context-window--synthid-notes)

---

## Gemini 3.5 Flash
- **Category:** foundation model
- **What it is:** First model in the new Gemini 3.5 series — a fast frontier model fusing high intelligence with agentic/coding strength.
- **What it's for:** High-speed agentic, coding, and long-horizon tasks at lower cost than the flagship tier.
- **When to use it / vs alternatives:** The **default** for nearly everything. Google says it outperforms the prior Gemini 3.1 Pro on coding/agentic benchmarks while running ~4× faster in output tokens/sec and at less than half the cost of comparable frontier models. Step up to 3.5 Pro only for the hardest reasoning.
- **Status:** **GA** — "available today" (May 19) across the Gemini app, AI Mode in Search, Antigravity, the Gemini API (AI Studio), Android Studio, and Gemini Enterprise.
- **Source:** https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-3-5/ ; https://deepmind.google/models/gemini/
- **Announced:** May 19, 2026

## Gemini 3.5 Pro
- **Category:** foundation model
- **What it is:** The higher-capability sibling to 3.5 Flash (in internal use at announcement).
- **What it's for:** The hardest reasoning, science, and engineering tasks in the 3.5 generation.
- **When to use it / vs alternatives:** Choose Pro over Flash for maximum reasoning depth; Flash for speed/cost. Most users won't need it day to day.
- **Status:** **Announced-only** — "rolling out next month" (~June 2026). Re-check availability before telling a user they can use it.
- **Source:** https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-3-5/
- **Announced:** May 19, 2026 (availability later)

## Gemini Omni / Omni Flash
- **Category:** generative media / multimodal foundation model
- **What it is:** A new "any-input-to-any-output" generative family from Google DeepMind that fuses Gemini's reasoning with generative media — starting with **video output (with synchronized audio)**, expanding to image and text over time. Outputs carry **SynthID** watermarks.
- **What it's for:** Conversational video creation and editing — generate/edit video from text, images, audio, or sketches; style transfer, character swaps, scene-coherent edits, virtual try-ons.
- **When to use it / vs alternatives:** Use Omni when you want to generate or iteratively edit **video** through natural-language conversation, rather than a fixed text-to-video prompt or a text/code model like Gemini 3.5.
- **Status:** **GA (consumer) / Announced (API).** Omni Flash "available today" in the Gemini app, Google Flow, and YouTube Shorts for paid AI Plus/Pro/Ultra tiers (varies by region). **Gemini Omni Flash via the API / Agent Platform** was "rolling out in coming weeks" — i.e. announced-only for developers at I/O.
- **Source:** https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-omni/ ; https://deepmind.google/models/gemini-omni/
- **Announced:** May 19, 2026
- **Note:** Some press called Omni a "world model." DeepMind's own materials do **not** use that label for Omni — it reserves "world model" for Genie. Treat "world model" as press shorthand.

## Gemma 4
- **Category:** foundation model (open weights)
- **What it is:** The new generation of Google's **open-weight** Gemma models.
- **What it's for:** Open / on-prem / customizable deployments where you can't or don't want to depend on the API-only Gemini line.
- **When to use it / vs alternatives:** Choose Gemma when you need **open weights / self-hosting**. Choose Gemini (3.5, Omni) when you want Google's frontier capability via API.
- **Status:** **GA-ish / available** — referenced in the developer keynote recap and added to the Android Bench leaderboard the week of I/O. Exact variant sizes/availability were not fully detailed in verified sources (see caveat).
- **Source:** https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/
- **Announced:** ~May 19–20, 2026
- **Caveat:** Variant list and sizes unconfirmed in the official sources checked — verify specifics on ai.google.dev before quoting numbers.

## Nano Banana
- **Category:** generative media (image)
- **What it is:** Google's image-generation model (the name predates I/O 2026). The I/O 2026 news is its deeper **integration** into products, not its debut.
- **What it's for:** Generating custom imagery/assets — e.g. the AI Studio "Build" agent uses it to auto-generate UI imagery; **Google Pics** (Workspace) uses the latest Nano Banana for image creation/editing.
- **When to use it / vs alternatives:** For still images inside Google's surfaces (AI Studio prototypes, Workspace docs). For video, use Gemini Omni.
- **Status:** **GA / embedded** — available within AI Studio; Google Pics rollout summer 2026 (see `workspace-android-xr.md`).
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/
- **Announced:** Integration highlighted May 19, 2026 (model itself is older)

## DeepMind science research stack
- **Category:** research/agent
- **What it is:** A bundle of DeepMind research tools surfaced via **Google Labs**: **Co-Scientist** (hypothesis generation), **AlphaEvolve + ERA** (Empirical Research Assistance — generates/scores thousands of code variations in parallel for computational discovery), plus a **"Science Skills"** bundle integrating 30+ life-science databases. Also referenced: **"Literature Insights"** within Gemini for Science.
- **What it's for:** Accelerating scientific discovery — hypothesis generation, bioinformatics/genomics, evolutionary code search.
- **When to use it / vs alternatives:** Research/science workflows, not general chat. Exposed through Google Labs, not a general build target.
- **Status:** **Research / experimental**, via Google Labs. These are largely pre-existing DeepMind projects highlighted at I/O, not net-new debuts.
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/
- **Announced:** Highlighted May 19, 2026

## Genie 3
- **Category:** research/agent (world model)
- **What it is:** DeepMind's general-purpose **world model** that generates photorealistic, real-time-explorable 3D environments from text.
- **What it's for:** Interactive simulated environments for agent training / embodied-AI research. (As a *consumer* feature, "Project Genie" is offered as an exclusive on the $200 AI Ultra tier — see pricing.)
- **When to use it / vs alternatives:** Research use; not a production media tool. For generated video, use Gemini Omni instead.
- **Status:** **Research** — experimental prototype via Project Genie at Google Labs.
- **Source:** https://deepmind.google/models/genie/
- **Announced:** ⚠️ Genie 3 appears to **predate** I/O 2026; it was not clearly a fresh I/O 2026 reveal. The consumer "Project Genie" Ultra perk is the I/O 2026-relevant angle. There is no verified "Genie 4."

---

## Context window & SynthID notes

- **Context window:** Gemini 3.5 retains a large context window — DeepMind reports long-context benchmark results at **128k and 1M tokens** for 3.5 Flash. No new headline maximum-context figure was announced. (Treat any "2M token" claim as unverified — it traces to secondary roundups, not official I/O 2026 sources.)
- **SynthID / C2PA (cross-cutting):** AI-content verification via SynthID expanded to the Gemini app and Search (May 19) and Chrome (coming weeks), with **C2PA Content Credentials** checks in the Gemini app from May 19. Partners include OpenAI, Kakao, ElevenLabs. All Omni outputs are SynthID-watermarked.
  - Source: https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/

## What is NOT a new I/O 2026 model
Veo, Imagen, Lyria, and Flow were **I/O 2025** launches and were referenced at I/O 2026 only as *existing* tools — no new versions were headlined. The 2026 generative-media story is **Gemini Omni**. See `context-and-disambiguation.md`.
