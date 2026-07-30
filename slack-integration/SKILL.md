---
name: slack-integration
description: >-
  Design and build Slack integrations — bots, apps, incoming webhooks, slash commands, Block Kit UI,
  Workflow Builder steps, and AI agents that live in Slack. Use this whenever work touches Slack's
  platform in any way — choosing between a webhook, a token script, a no-code workflow, a custom
  workflow step, a Socket Mode app, an HTTP app, or an agent; picking token types and OAuth scopes;
  designing modals, App Home, or message layouts; wiring events, interactivity, or slash commands;
  deciding hosting, local tunnels, secrets, or distribution; and debugging the classics like a bot
  that cannot see a channel, a three-second timeout, a 429, or a missing_scope error. Trigger it even
  when the request only says "Slack bot", "post to Slack", "Slack notification", "Slack app", or
  names a single Slack API method, and read it BEFORE writing Slack code so the integration shape is
  chosen deliberately instead of defaulted into.
---

# Slack integration

Slack has roughly eight distinct integration shapes, and most wasted effort in this domain comes from
picking the wrong one — usually by reflex, building a full event-driven app when a webhook would have
done, or writing a script when the person who actually needs to change the behavior later is not an
engineer. Choosing the shape well is the highest-leverage decision in the whole project, so do that
first and deliberately.

This skill has two jobs. **First**, pick the shape (below). **Second**, get the axis-specific details
right by reading the one reference file that covers the axis you are working on — the details are
where Slack is quietly full of traps, and they are versioned separately so this file stays short.

## The platform moves — verify before asserting

Slack's platform changes several times a year, and this skill will drift. Official docs live at
`https://docs.slack.dev` (the old `api.slack.com` paths redirect there). Before stating a limit, a
scope name, a date, or a method signature that the design depends on, fetch the relevant page. Treat
anything in this skill dated or numbered as a strong prior, not as the current truth.

Two specific things to always re-check because they moved recently and materially change designs:
rate limits on reading conversation history, and the deprecation timeline for classic apps.

## Step 1 — answer these seven questions first

Do not skip to code. The answers collapse the design space fast, and every one of them changes the
recommendation:

1. **What starts it?** A human clicking, a message appearing, a schedule, or an external system.
2. **Does Slack need a reply, and how fast?** Fire-and-forget notification, or an interactive
   exchange that must acknowledge within three seconds.
3. **Does it need to read existing conversation?** Reading history is the single most rate-limited
   and most policy-constrained thing on the platform.
4. **Who needs to change the behavior in six months?** An engineer, or the ops person who owns the
   process. This alone often decides code versus Workflow Builder.
5. **One workspace, or many?** Internal tooling and a distributed product have almost nothing in
   common in auth, hosting, and review.
6. **Does it need real UI?** A formatted message, a form, a modal, a home tab, or nothing visual.
7. **Who installs it, and can they?** Workspace policy can require admin approval, and some
   capabilities are gated by the workspace's paid plan.

## Step 2 — pick the shape

Ordered from least to most machinery. **Prefer the earliest shape that satisfies the requirement** —
every step down this list adds hosting, secrets, and an on-call surface.

| Shape | Use when | Cost |
|---|---|---|
| **Incoming webhook** | One-way notifications into a known channel. CI results, deploy status, alerts. | One URL. No token, no server, no scopes. |
| **Script with a token** | Scheduled or on-demand automation. Digests, backfills, exports, personal tooling. Runs from cron, CI, or a laptop. | A token to store. No inbound traffic, no hosting. |
| **Workflow Builder (no code)** | A human process — request, approval, intake form, onboarding checklist. Non-engineers must own it. | None. Built in Slack's UI. Paid plan. |
| **Custom step for Workflow Builder** | Your system's action needs to be composable by non-engineers inside their own workflows. | A small deployed function. Not available on Free. |
| **Slash command or shortcut** | A human explicitly invokes your system from anywhere in Slack. | A hosted endpoint, three-second ack. |
| **Event-driven app, Socket Mode** | Reacts to what happens in Slack. Internal, single workspace, behind a firewall, or in local development. | Long-running process holding a WebSocket. Cannot be listed in the Marketplace. |
| **Event-driven app, HTTP** | Same, but distributed to other workspaces, or you want serverless request/response. | Public HTTPS endpoint, request signature verification, OAuth install flow. |
| **AI agent or assistant** | Conversational, goal-oriented help with Slack's dedicated agent surfaces and streamed replies. | Everything an HTTP app needs, plus an inference budget and its own UX contract. |

Two shapes that are not "an app" and are easy to miss:

- **A webhook-triggered workflow** gives an external system a URL that starts a Slack-side workflow.
  You get forms, buttons, and branching with zero code hosted anywhere.
- **MCP in both directions.** Slack can act as an MCP client so Slackbot invokes tools on your remote
  MCP server, and Slack publishes an MCP server so an outside agent can act in Slack. When the goal
  is "let an AI use our system from Slack", check these before building a bespoke agent.

Read `references/choosing.md` for the decision trees behind this table, worked use cases, and the
anti-patterns — including the three shapes people most often over-build.

## Step 3 — read the axis you are working on

Load only what the current task needs. Each file is self-contained.

| Axis | File | Read it when |
|---|---|---|
| Auth, tokens, scopes, secrets | `references/tokens-and-scopes.md` | Choosing a token type, picking scopes, handling install/OAuth, storing credentials |
| UI and surfaces | `references/ui.md` | Designing messages, modals, App Home, forms, canvases; anything a human looks at |
| Block Kit type inventory | `references/block-kit-reference.md` | Assembling an actual payload and needing exact block and element `type` names |
| Events, delivery, interactivity | `references/events-and-delivery.md` | Receiving anything from Slack — events, commands, button clicks, view submissions |
| Deployment and local dev | `references/deployment.md` | Deciding hosting, running locally, tunnels, CI, process model, secret storage |
| App configuration and distribution | `references/configuration.md` | Manifests, app settings, install policy, one workspace versus many, Enterprise Grid |
| Limits, quotas, and pitfalls | `references/limits-and-pitfalls.md` | Anything touching volume, pagination, files, retries, or a mysterious failure |
| AI agents in Slack | `references/ai-agents.md` | Building an assistant, streaming replies, MCP wiring |

## The traps worth knowing before you design anything

These are cheap to design around and expensive to discover late. Each is expanded in the referenced
file.

- **A bot only sees channels it has been invited to.** No scope grants ambient visibility. Design the
  invitation step into onboarding, or the app silently does nothing. (`tokens-and-scopes.md`)
- **Reading conversation history is the constrained path.** Apps distributed outside the Marketplace
  face a severe limit on `conversations.history` and `conversations.replies` — roughly one request per
  minute returning a handful of messages. Internal apps built by the workspace's own team are treated
  differently. If your design depends on bulk-reading messages, verify your app's category against
  current policy before committing. (`limits-and-pitfalls.md`)
- **Search requires a user token.** A bot token cannot search. If the feature is "find where this was
  discussed", the shape changes to a user-authorized token, with everything that implies.
  (`tokens-and-scopes.md`)
- **You have three seconds to acknowledge.** Slash commands, interactions, and events all demand a
  fast ack, then do the work asynchronously. Serverless cold starts eat this budget.
  (`events-and-delivery.md`)
- **Socket Mode apps cannot be listed in the Marketplace.** Choosing Socket Mode is choosing internal
  distribution. Retrofitting HTTP later is a real migration. (`deployment.md`)
- **Adding a scope requires reinstalling the app.** Every workspace has to re-authorize. Enumerate
  scopes early rather than discovering them one at a time. (`tokens-and-scopes.md`)
- **`files.upload` is retired.** Uploads are a two-step flow now. Old snippets and old LLM memory
  both get this wrong. (`limits-and-pitfalls.md`)
- **Posting is limited per channel, not per app.** Roughly one message per second per channel, bursts
  tolerated. Fan-out designs must pace themselves. (`limits-and-pitfalls.md`)
- **Plan gates are real.** Workflow Builder and custom steps need a paid plan; some admin APIs and
  audit surfaces are Enterprise-only. No permission grant substitutes for a plan.
  (`configuration.md`)
- **Verify every inbound request.** Slack signs requests; an unverified endpoint is an open door.
  (`events-and-delivery.md`)

## Design review checklist

Run this before writing implementation code, and again before shipping. It catches the failures that
are structural rather than syntactic.

- The shape is the earliest one in the table that satisfies the requirement, and the reason for
  skipping the simpler shapes is written down.
- Every scope requested is traced to a specific call the app makes. Unused scopes are removed.
- The token type matches the identity the action should carry — the app's own identity, or a person's.
- There is a plan for how the bot gets into the channels it needs.
- Inbound requests are signature-verified, and secrets are read from the environment or a secret
  manager, never committed.
- Anything slower than three seconds happens after the acknowledgement.
- Rate limits and pagination are handled for every list-or-read call, with `Retry-After` respected.
- Failure is visible. A silently dead integration is the normal failure mode, so log delivery
  failures somewhere a human sees.
- The app config is captured as a manifest so it is reproducible and reviewable.
- Someone other than the author can change the parts that will need changing.

## When the user just wants the thing built

Not every request needs the full treatment. If someone asks for a deploy notification, the answer is
an incoming webhook and a `curl` — say so, do it, and skip the ceremony. Match the depth of process
to the stakes: internal one-off scripts and a product installed by other companies deserve very
different amounts of rigor, and applying product rigor to a personal script is its own failure mode.
