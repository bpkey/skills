# Choosing the integration shape

The shape determines the cost of the project far more than the language or the framework does. This
file exists so that choice is made from requirements rather than from habit.

## Contents

- [The two questions that split the space](#the-two-questions-that-split-the-space)
- [Decision trees](#decision-trees)
- [Worked use cases](#worked-use-cases)
- [Anti-patterns](#anti-patterns)
- [When to combine shapes](#when-to-combine-shapes)
- [Migration costs between shapes](#migration-costs-between-shapes)

## The two questions that split the space

**Does Slack need to send you anything?** If information only flows *into* Slack, you never need a
server, an event subscription, or a public URL. A webhook or a token-holding script covers it. This
single question eliminates most of the machinery people build.

**Who owns the behavior after launch?** If the process will be tweaked by the team that runs it —
adding an approver, changing a form field, routing to a different channel — putting it in code means
every tweak becomes an engineering ticket. Workflow Builder exists for exactly this, and handing
ownership to the process owner is usually worth accepting its limits.

## Decision trees

### Information flows into Slack only

```
Is the trigger an external system (CI, monitor, cron, another app)?
├── Yes → Does a non-engineer need to change what happens after it arrives?
│         ├── Yes → Webhook-triggered Workflow Builder workflow
│         └── No  → Incoming webhook (simplest), or a script with a bot token
│                   if you need threading, updating, uploads, or lookups
└── No → The trigger is a human in Slack → see "A human starts it"
```

Choose a script over an incoming webhook as soon as you need any of: posting to a channel chosen at
runtime, updating or deleting a message you posted, threading replies, uploading a file, or looking
anything up. A webhook can only post, and only where it was bound.

### A human starts it

```
Do they need a form or multi-step flow?
├── Yes → Can it be built from Slack's own steps (form, message, branch, approval)?
│         ├── Yes → Workflow Builder
│         └── No  → Does only one action need custom code?
│                   ├── Yes → Custom step, composed inside their workflow
│                   └── No  → App with a modal
└── No  → Where do they invoke it from?
          ├── Typing a command anywhere → Slash command
          ├── A specific message → Message shortcut
          └── A dedicated place in Slack → App Home
```

### Slack events drive it

```
Will other organizations install this?
├── Yes → HTTP app with OAuth install flow, multi-workspace token storage,
│         and Marketplace review if you want to be listed
└── No  → Do you have somewhere to run a long-lived process?
          ├── Yes → Socket Mode (no public URL, no signature verification burden,
          │         far easier local development)
          └── No  → HTTP app on serverless, minding cold starts against the
                    three-second acknowledgement budget
```

### An AI needs to act

```
Is the goal "let an AI use our system from Slack"?
├── Yes → Expose an MCP server and let Slack's MCP client call it.
│         You write tools, not a Slack app.
└── No  → Is the goal "our product should feel like a colleague in Slack"?
          ├── Yes → Agent app with the assistant surfaces and streamed replies
          └── No  → It is probably a normal app that happens to call a model
```

## Worked use cases

**"Tell us in Slack when the build breaks."** Incoming webhook. One URL in CI config. Resist adding
an app.

**"Post a daily summary of open pull requests, and keep it as one message that updates."** Script with
a bot token, run on a schedule. Post once, store the message timestamp, then update that message on
each run. No server.

**"Let anyone request access to a system, with manager approval."** Workflow Builder. A form, a
message with approve and reject buttons, and a branch. If the grant itself must be automated, add one
custom step that performs the grant and leave the rest in the workflow, so ops owns the process and
engineering owns only the privileged action.

**"Answer questions about our internal docs when someone mentions us."** Event-driven app on the
`app_mention` event. Socket Mode if internal. Note the constraint early — if answering requires
reading channel history rather than your own document store, check history rate limits before
promising it.

**"Search everything I've ever discussed in Slack from my terminal."** Script with a *user* token,
because search is user-token-only. Personal tooling, not a shared app.

**"Our SaaS product should notify customer workspaces and let them act inline."** HTTP app,
distributed, OAuth install per workspace, per-workspace token storage, signature verification, and
Marketplace review if listed. This is a product, not an integration; budget accordingly.

**"Let people file a ticket from any message."** Message shortcut opening a modal, then create the
ticket on view submission. Acknowledge the submission immediately and do the creation after.

## Anti-patterns

**Building an event-driven app for one-way notifications.** The tell is an app whose only Slack call
is `chat.postMessage` and which subscribes to no events. It should be a webhook or a script.

**Writing code for a process that a form and a button would cover.** The tell is a codebase whose
logic is "collect four fields, ask someone to approve, post the result". Workflow Builder does that,
and the process owner can then change it without you.

**Polling for messages.** Slack pushes events. Polling `conversations.history` on a timer is the
design most likely to hit rate limits and most likely to be treated as data harvesting. If you find
yourself polling, you probably wanted an event subscription.

**Requesting broad scopes "so we don't have to reinstall later".** It inflates review scrutiny,
alarms admins, and makes the app harder to get approved. Enumerate precisely, accept the reinstall.

**Using a user token because it was easier than getting the bot invited.** A user token acts as that
person, breaks when they leave, and gives the app their entire visibility. It is occasionally correct
and frequently a shortcut that becomes a security finding.

**Choosing Socket Mode without checking distribution plans.** It cannot be listed in the Marketplace.
If there is any chance the app ships to other organizations, start with HTTP.

## When to combine shapes

Real integrations often use two shapes deliberately:

- A **custom step plus Workflow Builder** — engineering owns one privileged action, ops owns the
  process around it. This is the highest-leverage combination on the platform.
- A **webhook for alerts plus an app for interaction** — noisy one-way traffic stays cheap while the
  interactive part carries the machinery.
- An **MCP server plus a thin app** — the tools live in MCP where any client can use them, and the
  Slack app only handles Slack-specific surfaces.

## Migration costs between shapes

Knowing what is cheap to change later reduces the pressure on the initial choice:

- **Webhook to script** — cheap. Same destination, more capability.
- **Script to app** — moderate. New hosting and event handling, but the API calls carry over.
- **Socket Mode to HTTP** — moderate and unavoidable if you want distribution. Same handlers, new
  transport, plus signature verification and an install flow.
- **Single-workspace to multi-workspace** — expensive. Token storage, install flow, per-workspace
  state, and review all arrive at once. Decide this one up front.
- **Code to Workflow Builder** — usually a rewrite, because the logic has to become steps.
