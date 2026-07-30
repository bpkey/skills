# AI agents and assistants in Slack

Slack has first-class surfaces for AI apps, so an agent does not have to be a bot that posts messages in
a channel. This file covers what those surfaces give you and the two MCP directions, which are easy to
confuse.

## Contents

- [Three different things people mean](#three-different-things-people-mean)
- [The agent surfaces](#the-agent-surfaces)
- [Scopes, events, and methods](#scopes-events-and-methods)
- [Streaming replies](#streaming-replies)
- [MCP in both directions](#mcp-in-both-directions)
- [Design guidance for agents in a shared space](#design-guidance-for-agents-in-a-shared-space)
- [Cost and latency](#cost-and-latency)

## Three different things people mean

Separate these before designing, because they have almost nothing in common:

1. **"Let an AI use our system from Slack."** Expose tools; let Slack's own assistant call them. You
   write an MCP server, not a Slack app.
2. **"Our product should be present in Slack as a colleague."** Build an agent app with Slack's
   assistant surfaces, streaming, and thread context.
3. **"Automate something with an LLM in the middle."** This is an ordinary integration that happens to
   call a model. Pick the shape from `choosing.md`; nothing here applies.

The second is the most work by a wide margin. Do not choose it because the word "agent" was used.

## The agent surfaces

An agent app gets UI that a normal bot does not:

- **A dedicated thread container**, opened alongside the conversation the person is looking at, so the
  agent has its own space instead of interrupting a channel.
- **Context awareness** — the app is told which channel or thread the user is viewing, so "summarize
  this" has a referent.
- **Suggested prompts** — up to four preset prompts shown at the top of the conversation, which is the
  cheapest way to teach people what your agent can do.
- **A status indicator** while the agent is thinking, so latency reads as progress rather than as
  breakage.
- **A settable thread title**, which turns a history of conversations into something navigable.
- **Streamed text**, so answers appear progressively.

Enable the agent feature in app configuration; doing so adds the assistant scope automatically. The
Messages tab of App Home becomes the agent's home, so App Home settings matter here — see `ui.md`.

## Scopes, events, and methods

**Scope.** The assistant scope (`assistant:write`) is what unlocks suggested prompts, status, and
titles. It is added when you enable the feature.

**Events.** The current agent experience is driven by the app-home-opened event (the user opened the
agent's DM), an app-context-changed event (what the user is looking at changed), and message events in
the DM with your app. An earlier assistant-thread model used dedicated thread-started and
context-changed events; you will see both in documentation and in older code, so check which one your
SDK version implements rather than mixing them.

**Methods.** Beyond ordinary posting, agents use methods to set a thread's status, set its title, and
set its suggested prompts, plus the streaming trio below. Reading a thread's own history uses the normal
conversation-replies method — which means the history rate limits in `limits-and-pitfalls.md` apply, and
they are the constraint most likely to bite an agent that wants broad context.

Verify method names and shapes against current documentation before writing code; this is the
fastest-moving area of the platform.

## Streaming replies

Streaming is three calls: start a stream, append to it repeatedly as tokens arrive, and stop it. The
user sees text materialize instead of waiting for a complete answer.

Practical notes:

- **Append in chunks, not per token.** Every append is an API call and therefore subject to rate limits;
  batching a sentence or a short buffer reads as smooth without hammering the API.
- **Always stop the stream**, including on failure. An abandoned stream leaves the UI mid-thought.
- **Set status before the first token.** The gap between question and first output is where users decide
  the thing is broken.
- **Have a non-streaming fallback.** If streaming fails, post the complete answer rather than nothing.

## MCP in both directions

These are genuinely two different products and conflating them causes wasted work:

**Slack as MCP client.** Slack connects to *your* remote MCP server, discovers your tools, and invokes
them from conversation. You implement an MCP server exposing your system's capabilities; Slack handles
the conversational surface, and there is no Slack app UI to build. This is the shortest path from "our
internal system" to "usable by AI from Slack".

**Slack as MCP server.** Slack publishes an MCP server so an outside MCP client — a coding agent, a
desktop assistant — can search channels, post messages, manage canvases, and act in Slack. Use this when
the agent lives outside Slack and Slack is one of the systems it manipulates. You write no Slack app at
all.

Both are newer than the rest of the platform. Confirm availability, authentication model, and any plan
requirement in current documentation before promising either, and expect the details to have moved.

## Design guidance for agents in a shared space

An agent in a workplace tool has failure modes a chatbot on a website does not:

- **Bystanders read everything.** Confident wrong answers in a channel become organizational truth.
  Prefer the agent's own thread for uncertain work, and cite sources where you have them.
- **Say what you did, not just what you concluded.** "Searched 4 channels, found 2 relevant threads"
  lets a reader calibrate.
- **Never take a consequential action silently.** Anything that writes to another system belongs behind
  a button the human presses, with the action described in plain terms first.
- **Respect visibility as a hard boundary.** An agent must never surface content from a private channel
  into a public one. If your retrieval uses a user token, it inherits that person's visibility, and
  answering in a channel can leak. Design retrieval so the answer's audience is never wider than the
  source's.
- **Be interruptible.** Long autonomous runs with no way to stop them are unwelcome in a shared space.
- **Handle "I don't know" well.** In a workplace, an honest miss costs far less than a fabricated
  answer, and the whole team sees which one you chose.

## Cost and latency

Every message is potentially an inference call, and Slack conversations are chatty. Two consequences:

- **Put a budget on it.** Rate-limit per user and per workspace, and decide what happens when the budget
  is exhausted before it happens in production.
- **Latency is the whole experience.** Status indicators and streaming exist because people abandon a
  silent agent within seconds. Cheap acknowledgement plus progressive output beats a faster model with
  no feedback.
