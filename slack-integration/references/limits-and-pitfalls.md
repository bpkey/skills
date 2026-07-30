# Limits, quotas, and pitfalls

Slack's API is pleasant until volume arrives. This file collects the constraints that change designs and
the failure modes that waste the most time.

## Contents

- [Rate limits](#rate-limits)
- [Reading conversation history](#reading-conversation-history)
- [Posting limits](#posting-limits)
- [Pagination](#pagination)
- [Files](#files)
- [Message formatting gotchas](#message-formatting-gotchas)
- [Error codes worth handling by name](#error-codes-worth-handling-by-name)
- [Deprecations and stale advice](#deprecations-and-stale-advice)
- [Slack Connect and shared channels](#slack-connect-and-shared-channels)

## Rate limits

Web API methods sit in tiers, applied **per method, per workspace**, in one-minute windows. The tiers
are roughly: about one request per minute at the most restricted tier, about twenty at the next, about
fifty, and about one hundred at the most generous. Short bursts above the nominal rate are tolerated;
sustained excess is not.

When limited you get HTTP 429 with a `Retry-After` header in seconds. Respect it. The correct handling
is: sleep for the stated duration, then retry that method; do not treat it as a hard failure, and do not
retry immediately with backoff you invented. Being rate-limited on one method does not limit others.

Design implications:

- **Batch and cache directory data.** User and channel lookups are the classic source of accidental
  limit pressure. Fetch once, cache with a sane lifetime, and refresh lazily.
- **Concurrency multiplies risk.** Ten workers all calling the same method against the same workspace
  share one budget.
- **Backfills need pacing built in from the start**, not added after the first 429.

## Reading conversation history

This is the most consequential limit on the platform and it changed recently, so verify current policy
before designing around it.

The shape of it: apps that are **distributed commercially outside the Marketplace** face a severe
restriction on `conversations.history` and `conversations.replies` — on the order of one request per
minute returning roughly fifteen messages. Marketplace-listed apps are unaffected, and apps built by a
workspace's own team for internal use are treated differently. New installations were affected first,
with existing installations of unlisted distributed apps following on a later date in 2026.

What to take from this:

- If your feature depends on bulk-reading messages, establish which category your app falls into
  **before** building.
- Prefer event subscriptions over reading history. Events are pushed, unmetered by these limits, and
  express intent more precisely.
- If you need durable access to conversation content, store what arrives via events rather than
  re-reading it later.
- Slack's stated rationale is preventing bulk exfiltration of conversation data by unvetted apps, which
  tells you how a reviewer will read a design that reads a lot of history.

## Posting limits

Roughly **one message per second per channel**, with short bursts allowed. This is per channel, so
fanning out to fifty channels is not fifty times slower — but hammering one channel is.

Related practical limits: profile updates are capped per minute; bulk operations on users and channels
have their own tiers; and a design that posts a message per row of a large result set should be a single
message, a thread, or a file instead.

## Pagination

Collection methods return a cursor. Follow it until it is empty, and pass a sensible page size rather
than the default.

Two mistakes to avoid: assuming the first page is the whole result (a workspace with 20,000 users will
quietly break logic that reads one page), and re-paginating an entire collection on every run when you
only needed to detect changes.

## Files

`files.upload` is **retired**. Uploading is now a two-step flow: ask Slack for an upload URL, PUT the
bytes to it, then tell Slack the upload is complete and where to share it. The official SDKs wrap this
in a single convenience call, which is the sane path.

Old code and old model memory both reach for `files.upload` first — if you see it, it is wrong. Also note
that sharing a file into a channel is a separate concern from uploading it, and that files have their own
scopes distinct from message scopes.

## Message formatting gotchas

- Slack uses its own markup, not Markdown. Bold is single asterisks, italics single underscores, and
  links use an angle-bracket form with a pipe for the label. Pasting Markdown produces visible
  asterisks.
- Mentioning a user requires their ID in the mention syntax, not their display name. Names do not
  resolve.
- Escape the ampersand, less-than, and greater-than characters in text you interpolate, or a stray angle
  bracket will be parsed as markup.
- Emoji are shortcodes; a custom emoji that exists in one workspace will render as literal text in
  another.
- Always set fallback text alongside blocks, because notifications and unsupported surfaces show only
  that. A blank push notification is a real user-visible bug.
- Legacy attachments still work but are superseded by blocks. Do not mix paradigms in one message
  without a reason.
- Timestamps rendered with Slack's date syntax localize per reader, which is better than formatting a
  date server-side.

## Error codes worth handling by name

Slack's errors are specific strings, which makes them good branch conditions and good alert keys:

| Error | Means | Do |
|---|---|---|
| `not_in_channel` | The bot is not a member | Ask to be invited; surface a useful message |
| `channel_not_found` | Wrong ID, or no visibility | Check the ID and membership before blaming the API |
| `missing_scope` | The token lacks a scope | The response names the needed scope; add it and reinstall |
| `invalid_auth`, `token_revoked`, `account_inactive` | The installation is gone or the token is dead | Stop retrying; trigger re-authorization |
| `ratelimited` | Over the limit | Honor `Retry-After` |
| `invalid_blocks` | Malformed Block Kit | Validate the payload in Block Kit Builder |
| `message_not_found` | Wrong timestamp or channel | Timestamps are per-channel; you cannot update a message from the wrong channel |
| `cannot_dm_bot`, `is_bot` | Attempting an operation on a bot user | Filter bots out of user lists |

## Deprecations and stale advice

Patterns that appear in old tutorials and in model memory but are no longer valid:

- **Legacy test tokens** and legacy custom-integration tokens — cannot be created.
- **`files.upload`** — retired, see above.
- **Classic apps** — cannot be created, and are on a deprecation path whose date has been pushed back
  more than once. If you inherit one, plan migration to a modern app and check the changelog for the
  current date rather than trusting any date written down here.
- **Legacy Workflow Builder steps from apps** — superseded by custom steps in the current builder.
- **Non-granular bot scopes** — the old all-or-nothing bot scope model is gone; scopes are granular.
- **RTM (the real-time messaging websocket)** — superseded by the Events API and Socket Mode for
  essentially all new work.

Whenever an approach feels oddly clunky, check whether you are following a pattern that was replaced.

## Slack Connect and shared channels

Channels shared with another organization behave differently. Your app's presence and permissions in a
shared channel are constrained by both organizations' policies, event delivery for external members
differs, and an app installed on your side is not installed on theirs. Do not assume an integration that
works in an internal channel behaves identically in a Slack Connect channel — test it specifically, and
be deliberate about what your app posts where external parties can read it.
