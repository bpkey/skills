# Events, delivery, and interactivity

Everything Slack sends you — events, slash commands, button clicks, modal submissions, shortcuts —
arrives through one of two transports and obeys one hard rule: **acknowledge fast, work afterwards**.

## Contents

- [The two transports](#the-two-transports)
- [The three-second rule](#the-three-second-rule)
- [Request signature verification](#request-signature-verification)
- [Retries and idempotency](#retries-and-idempotency)
- [Events worth knowing](#events-worth-knowing)
- [Interactivity payloads](#interactivity-payloads)
- [Slash commands](#slash-commands)
- [Responding after the acknowledgement](#responding-after-the-acknowledgement)
- [Debugging delivery](#debugging-delivery)

## The two transports

**HTTP.** You register a public HTTPS request URL. Slack POSTs to it. You must verify the signature on
every request, respond within the ack budget, and be reachable from the internet.

**Socket Mode.** Your app opens an outbound WebSocket using an app-level token (`xapp-`) with the
connections scope, and Slack pushes over that connection. No public URL, no inbound firewall rule, and
no signature verification, because the connection itself is authenticated.

Choose Socket Mode for internal apps and for local development — it removes an entire class of setup
problems. Choose HTTP when you need serverless economics or when you intend to distribute the app,
because **Socket Mode apps are not eligible for Marketplace listing**.

Practical notes on Socket Mode: it needs a process that stays alive, so it does not fit a
request/response serverless model. Connections are re-established periodically by design, so handle
reconnects (the SDKs do). Running two instances of the same app both connected will each receive
events, which usually means duplicated side effects — coordinate or run one.

## The three-second rule

Slack expects an HTTP 200 within about three seconds for events, commands, and interactions. Miss it
and Slack treats delivery as failed, retries, and the user sees an error in the client.

So the shape of every handler is the same: validate, acknowledge, then do the work in the background.
In Bolt this is the difference between calling `ack()` immediately and doing work before it. In a
hand-rolled handler, return the response first and continue processing after, which on serverless means
either a background invocation or a queue — a function that returns *after* finishing the work will
eventually exceed the budget on the slowest path.

Cold starts are the trap here. A serverless function that needs two seconds to warm up has one second
of real budget. Either keep it warm, split ack from work, or use Socket Mode.

Sustained delivery failures have a consequence beyond the individual request: Slack will disable an
event subscription that keeps failing over a rolling window. A quietly broken endpoint eventually
becomes a silently unsubscribed app.

## Request signature verification

For HTTP apps this is mandatory, not optional. Slack sends a timestamp header and a signature header;
you compute an HMAC over the timestamp and the **raw** request body using your signing secret and
compare.

Three implementation details cause most failures:

- **You need the raw body.** Any middleware that parses JSON before you compute the hash breaks the
  comparison. Capture the raw bytes first.
- **Reject old timestamps.** A few minutes of tolerance, no more, so a captured request cannot be
  replayed later.
- **Compare in constant time.** Use the platform's timing-safe comparison, not `==`.

The official SDKs do all of this. Prefer them over a hand-rolled version, and if you must hand-roll,
test with a deliberately tampered body to confirm the check actually fails.

## Retries and idempotency

Slack retries failed event deliveries a small number of times with backoff, and sends a header telling
you the retry number and reason. That means **your handlers must be idempotent**. The realistic failure
is not a lost event; it is the same event processed twice, creating two tickets or sending two messages.

Deduplicate on the event's own identifier, or make the effect naturally idempotent (updating a record
rather than appending one). If you acknowledge before working, remember that a crash after the ack
means the event is gone — for work that must not be lost, put it on a durable queue before
acknowledging.

## Events worth knowing

You subscribe to specific event types; the payload arrives with the event and the workspace context.

- `app_mention` — someone @-mentioned your app. The usual entry point for a conversational bot.
- `message.channels`, `message.groups`, `message.im`, `message.mpim` — messages in public channels,
  private channels, DMs with your app, and group DMs. Each needs its own history scope. Subscribing to
  all messages in all channels is a large ask that admins notice; prefer mentions where possible.
- `app_home_opened` — a user opened your app's Home or Messages tab. Render the Home tab here.
- `reaction_added` — an emoji was added. A cheap, human-friendly trigger for automation.
- `member_joined_channel`, `channel_created` — onboarding and channel-lifecycle automation.
- `app_uninstalled`, `tokens_revoked` — clean up stored credentials. Handling these is the difference
  between a tidy multi-workspace app and one that hammers dead installations.

Two behaviors to design around: your app's own messages generate message events too, so filter out your
own bot identity or you will loop; and edits, deletes, and thread replies arrive as message events with
subtypes rather than as distinct types.

## Interactivity payloads

Button clicks, select changes, shortcuts, and modal submissions all arrive at the interactivity
endpoint (or over Socket Mode) as a payload identifying what was interacted with, by whom, and where.

- Give every interactive element a stable **action identifier**. Route on it. Encoding data in the
  identifier works for small values, but anything structured belongs in the element's value field or in
  the view's private metadata.
- The payload carries a **response URL** for messages, which lets you post or replace the message
  without needing the channel scope, for a limited window and a limited number of uses.
- A **trigger** value authorizes opening a modal, and it expires quickly. Open first, work later.
- Never trust the payload's user as authorization for a privileged action without checking that person
  against your own permission model. Anyone in the channel can click the button.

## Slash commands

A slash command posts a form-encoded request to your endpoint with the text the user typed, the channel,
and the user. The same three-second rule and signature verification apply.

Design notes: commands are workspace-global once installed, so name them distinctly enough to avoid
collisions with other apps. Argument parsing is entirely yours, so keep the grammar shallow — a
command with a rich flag syntax is a sign the interaction wanted a modal. Reply ephemerally by default
so a mistyped command does not clutter the channel.

## Responding after the acknowledgement

Three ways to say something after the ack, in rough order of preference:

1. **`chat.postMessage`** with a bot token. Full capability, needs channel membership.
2. **The response URL** from the interaction payload. Works without channel scope, can replace the
   original message, expires and is use-limited.
3. **An ephemeral message** for one person, useful for validation feedback and errors.

For long work, post an immediate "working on it" and then update that same message when done. It reads
better than silence and it gives you a place to report failure.

## Debugging delivery

- Check the app's event subscription status in app config first — a disabled subscription after repeated
  failures looks exactly like "events stopped arriving".
- Verify the request URL responds to Slack's initial verification challenge.
- For signature failures, log whether the failure is timestamp age or hash mismatch; they have different
  causes.
- In local development, use Socket Mode instead of a tunnel where possible. If you need a tunnel,
  remember the URL changes on restart and must be re-registered.
- When events arrive but nothing happens, confirm the bot is actually in the channel and that you are
  not filtering out your own messages too aggressively.
