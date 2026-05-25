# Developer Tools & Cloud / Agent Platform — I/O 2026

Everything for building on Google AI: APIs, app builders, IDEs/agents, agent frameworks, cloud platform, Firebase. Status tags defined in `SKILL.md`.

The 2026 developer narrative: **from AI tools to agents**, anchored by **Antigravity 2.0** and **Gemini 3.5**. Several CLIs and surfaces were renamed/retired — note the deprecations.

## Contents
- [Antigravity 2.0](#antigravity-20) · [Antigravity CLI](#antigravity-cli-replaces-gemini-cli) · [Antigravity SDK](#antigravity-sdk)
- [Google AI Studio](#google-ai-studio)
- [Managed Agents](#managed-agents)
- [Agent Development Kit (ADK) 2.0](#agent-development-kit-adk-20) · [Agent2Agent (A2A)](#agent2agent-a2a-protocol) · [Skill Registry](#skill-registry) · [Agents CLI](#agents-cli)
- [Gemini Enterprise Agent Platform](#gemini-enterprise-agent-platform-formerly-vertex-ai) · [CodeMender](#codemender)
- [Android CLI](#android-cli) · [Android Studio AI](#android-studio-ai-features)
- [Firebase](#firebase-agent-native) · [WebMCP](#webmcp)
- [Deprecations & migrations](#deprecations--migrations)

---

## Antigravity 2.0
- **Category:** coding-agent (flagship)
- **What it is:** Google's agent-first development platform — **standalone desktop app + CLI + SDK** — that orchestrates multiple agents and dynamic subagents in parallel.
- **What it's for:** Turning ideas into production apps via agent orchestration, scheduled background tasks, and ecosystem integrations.
- **When to use it / vs alternatives:** Google's flagship agentic IDE; the successor surface to Gemini CLI and the full-IDE migration target for Firebase Studio users. Use it as the primary "build with agents" environment.
- **Status:** **GA** (desktop app + CLI). Enterprise availability via Gemini Enterprise "in coming months."
- **Source:** https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/ ; https://blog.google/innovation-and-ai/technology/developers-tools/google-io-2026-developer-highlights/
- **Announced:** May 19, 2026

## Antigravity CLI (replaces Gemini CLI)
- **Category:** coding-agent
- **What it is:** The terminal agent surface within Antigravity; carries over Agent Skills, Hooks, Subagents, and Extensions (now "Antigravity plugins").
- **What it's for:** Lightweight, high-velocity agent creation from the terminal.
- **When to use it / vs alternatives:** Use **instead of Gemini CLI** for new work. ⚠️ Gemini CLI and the Gemini Code Assist IDE extensions **stop serving AI Pro/Ultra and free users on June 18, 2026** (Gemini CLI persists only for paid Gemini Enterprise Agent Platform API keys).
- **Status:** **GA** — available to everyone May 19, 2026.
- **Source:** https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/
- **Announced:** May 19, 2026 (cutoff June 18, 2026)

## Antigravity SDK
- **Category:** coding-agent
- **What it is:** Programmatic control over the Antigravity agent harness, optimized for Gemini models.
- **What it's for:** Fully customizing the agent and deploying it on your own infrastructure.
- **When to use it / vs alternatives:** When you need code-level control / self-hosting beyond hosted Managed Agents.
- **Status:** **GA / launched.**
- **Source:** https://blog.google/innovation-and-ai/technology/developers-tools/google-io-2026-developer-highlights/
- **Announced:** May 19, 2026

## Google AI Studio
- **Category:** api/studio
- **What it is:** Google's AI app-building environment, now powered by the Antigravity coding agent.
- **What it's for:** Going from prompt to working full-stack / mobile prototype — including native **Android (Kotlin)** apps.
- **When to use it / vs alternatives:** The fastest prompt-to-app path; start here for prototypes. New capabilities: native Android/Kotlin generation, Google Workspace API integration, Google Play Console publishing, one-click Cloud Run deploy, Firebase support, export-to-Antigravity, and a mobile app (pre-registration). It's a migration target for Firebase Studio (alongside Antigravity).
- **Status:** **GA** for most; mobile app + some Kotlin/Firebase integrations "coming soon."
- **Source:** https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/ ; https://firebase.blog/posts/2026/05/google-io-2026-announcements/
- **Announced:** May 19, 2026

## Managed Agents
- **Category:** agent-framework (hosted)
- **What it is:** A single API call provisions a remote, isolated Linux sandbox where an agent reasons, plans, calls tools, and executes code — powered by the Antigravity agent harness on Gemini 3.5 Flash. Invoked via the **Interactions API**.
- **What it's for:** Building/running custom agents **without managing infrastructure** ("manage the mission, not the machine").
- **When to use it / vs alternatives:** Use when you want a **hosted** agent runtime. Contrast with **ADK** (code-first, self-built) and **Antigravity SDK** (self-hosted harness).
- **Status:** **GA (implied)** at launch on both the Gemini API (AI Studio) and the Gemini Enterprise Agent Platform; full A2A + governance integration "coming soon."
- **Source:** https://blog.google/innovation-and-ai/technology/ai/google-io-2026-all-our-announcements/ ; https://cloud.google.com/blog/topics/developers-practitioners/io26-news-for-agent-developers-on-google-cloud
- **Announced:** May 19, 2026

## Agent Development Kit (ADK) 2.0
- **Category:** agent-framework (code-first)
- **What it is:** Open-source, code-first, graph-based agent framework with a unified engine spanning dynamic model-led reasoning to deterministic workflows.
- **What it's for:** Engineers building custom agent meshes from the ground up.
- **When to use it / vs alternatives:** The **code-first / max-control** end of the spectrum vs hosted Managed Agents. Now adds **ADK Kotlin (Beta) — "ADK for Android"** alongside Python, Go, Java, so on-device agents coordinate with backend agents.
- **Status:** **GA**; **ADK Kotlin in Preview (Beta).**
- **Source:** https://cloud.google.com/blog/topics/developers-practitioners/io26-news-for-agent-developers-on-google-cloud
- **Announced:** May 19, 2026

## Agent2Agent (A2A) Protocol
- **Category:** agent-framework (interop)
- **What it is:** Open interoperability protocol so agents communicate regardless of model or framework — an agent on one layer can be called as a sub-agent on another.
- **What it's for:** Composable, cross-vendor agent architectures.
- **When to use it / vs alternatives:** The connective tissue under the whole Google agent stack. Google donated A2A to the Linux Foundation in early 2026.
- **Status:** **GA** (protocol predates I/O; reinforced May 19).
- **Source:** https://cloud.google.com/blog/topics/developers-practitioners/io26-news-for-agent-developers-on-google-cloud

## Skill Registry
- **Category:** agent-framework
- **What it is:** Centralized catalog to govern and reuse packaged domain logic ("Skills"), accessible via the Managed Agents API, Agent Platform SDK, and ADK (SkillToolset).
- **What it's for:** Sharing/governing reusable agent skills across an org.
- **When to use it / vs alternatives:** Standardizing domain logic across agents; folds into a broader Agent Registry over time.
- **Status:** **Preview** (public preview).
- **Source:** https://cloud.google.com/blog/topics/developers-practitioners/io26-news-for-agent-developers-on-google-cloud
- **Announced:** May 19, 2026

## Agents CLI
- **Category:** agent-framework
- **What it is:** A CLI packaging Google's expert skills for ADK build, eval, deploy, observability, and publishing — turns any coding agent into an agent-ops expert. (Distinct from the consumer **Antigravity CLI**.)
- **What it's for:** Building and operating ADK agents from the terminal.
- **When to use it / vs alternatives:** Works across Antigravity, Gemini CLI, Claude Code, and Cursor — use it for agent-ops regardless of your editor.
- **Status:** **GA / available.**
- **Source:** https://cloud.google.com/blog/topics/developers-practitioners/io26-news-for-agent-developers-on-google-cloud
- **Announced:** May 19, 2026

## Gemini Enterprise Agent Platform (formerly Vertex AI)
- **Category:** cloud/vertex
- **What it is:** The evolution/rebrand of **Vertex AI** into a platform to build, scale, govern, and optimize agents — session memory, centralized governance, eval suite, Agent Identity, Agent Gateway, Skill Registry. (Consolidates the former **Agentspace**.)
- **What it's for:** Enterprise agent development with governance, security, and compliance.
- **When to use it / vs alternatives:** The **enterprise** alternative to the consumer Gemini API / AI Studio path. Antigravity ties into it for enterprise security.
- **Status:** **GA** — the rename landed at **Cloud Next 2026** and was featured at I/O 2026. New **Starter Tier** (no billing required; first two app deployments free).
- **Source:** https://cloud.google.com/blog/topics/developers-practitioners/io26-news-for-agent-developers-on-google-cloud ; https://cloud.google.com/blog/products/ai-machine-learning/introducing-gemini-enterprise-agent-platform
- **Announced:** Rename per Cloud Next 2026; reinforced May 19, 2026
- **Note:** If a user still calls it "Vertex AI," that's the old name for this.

## CodeMender
- **Category:** cloud/vertex (security)
- **What it is:** An AI code-security agent in the Agent Platform that autonomously finds vulnerabilities, recommends/tests fixes, and (with approval) applies patches across dependent systems.
- **What it's for:** Autonomous code-security remediation in enterprise codebases.
- **When to use it / vs alternatives:** Automated vuln detection + patching at enterprise scale.
- **Status:** **Waitlist/Gated** — private preview, "testing with Gemini Enterprise customers, expanded availability coming soon."
- **Source:** https://cloud.google.com/blog/products/ai-machine-learning/innovations-from-google-io-26-on-google-cloud
- **Announced:** May 19, 2026

## Android CLI
- **Category:** coding-agent
- **What it is:** A command-line tool letting AI agents tap Android Studio — download the SDK, build, and run apps on devices/emulators.
- **What it's for:** Letting agents handle heavy Android dev tasks programmatically.
- **When to use it / vs alternatives:** Wiring agents into Android builds.
- **Status:** **GA / stable.**
- **Source:** https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/
- **Announced:** May 19, 2026

## Android Studio AI features
- **Category:** coding-agent
- **What it is:** **Migration Agent** (port React Native / web / iOS code to native Kotlin); **Agent Mode** with built-in Firebase Agent Skills; the open-sourced **Android Skills** library; and **Android Bench**, an LLM leaderboard for Android dev.
- **What it's for:** AI-assisted Android development and cross-platform porting.
- **When to use it / vs alternatives:** Migration Agent to port existing apps to Kotlin; Agent Mode for Firebase-aware in-IDE codegen.
- **Status:** Migration Agent **Preview**; Agent Mode **GA**; Android Skills **open-sourced**; Android Bench **active**.
- **Source:** https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/ ; https://firebase.blog/posts/2026/05/google-io-2026-announcements/
- **Announced:** May 19, 2026

## Firebase (agent-native)
- **Category:** firebase
- **What it is:** Firebase positioned as "agent-native": one-click Firebase setup inside Antigravity 2.0 (pre-installed Agent Skills + MCP servers); **Agent Skills for Firebase** expanded to Crashlytics & Remote Config across Android/iOS/Flutter/Web; **Firebase AI Logic** gains Gemini 3.x support, grounding with Google Maps, session resumption, and hybrid inference (iOS); Firebase available inside AI Studio (Cloud Run deploy, Workspace data via Sign in with Google).
- **What it's for:** Agent-driven app development with a Firebase backend.
- **When to use it / vs alternatives:** Use Agent Skills for lower-token, best-practice Firebase codegen inside Antigravity / Android Studio / AI Studio.
- **Status:** Most features **GA**; AI Logic auth-mode and Crashlytics-for-Web "coming soon."
- **Source:** https://firebase.blog/posts/2026/05/google-io-2026-announcements/
- **Announced:** May 19, 2026
- **Related deprecation:** the **Firebase Studio** cloud IDE is being **retired** (see below) — not the same thing as Firebase the backend, which is unaffected.

## WebMCP
- **Category:** agent-framework (web standard)
- **What it is:** A proposed open web standard to expose structured tools (JavaScript functions, HTML forms) to browser-based agents.
- **What it's for:** Letting browser agents execute complex tasks faster against web apps.
- **When to use it / vs alternatives:** Make a web app agent-actionable.
- **Status:** **Preview** — origin trial / experimental, starting **Chrome 149**.
- **Source:** https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/
- **Announced:** May 19, 2026

---

## Deprecations & migrations

These matter as much as the launches — don't recommend a path that's being shut off.

- **Gemini CLI → Antigravity CLI.** Gemini CLI + Gemini Code Assist IDE extensions stop serving **AI Pro/Ultra and free users on June 18, 2026**. Gemini CLI survives only for paid Gemini Enterprise Agent Platform API keys. Use Antigravity CLI for new work.
  - Source: https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/
- **Firebase Studio (cloud IDE) sunset** — announced **March 19, 2026** (before I/O, included for context). New workspace creation disabled **June 22, 2026**; full shutdown / data deletion **March 22, 2027**. Migrate to **Google AI Studio** (Firestore/Auth) or **Antigravity** (full IDE). Core Firebase backend services are unaffected.
  - Source: https://firebase.google.com/docs/studio/migrating-project
- **Vertex AI → Gemini Enterprise Agent Platform** — a rename, not a shutdown (see entry above).

## Unverified / commonly confused
- **Jules (async coding agent), "ADK 1.0", "Veo 3 in the API", "2M-token context":** these appear in secondary roundups but **could not be confirmed** as I/O 2026 announcements — Jules launched at **I/O 2025** (Gemini 2.5 Pro), and official 2026 sources say **ADK 2.0** and **Gemini Omni** (not Veo 3). Don't attribute these to I/O 2026 without re-checking. See `context-and-disambiguation.md`.
- **Gemini Code Assist:** no I/O 2026 *feature* launch found — only the deprecation above.
- **Stitch (UI generation):** not found in official I/O 2026 sources.
