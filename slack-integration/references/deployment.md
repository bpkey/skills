# Deployment and local development

Slack does not care how you host, with one exception: the transport you choose constrains the process
model. Everything else is ordinary application deployment.

## Contents

- [Process model follows transport](#process-model-follows-transport)
- [Hosting options](#hosting-options)
- [Local development](#local-development)
- [Configuration and secrets per environment](#configuration-and-secrets-per-environment)
- [Multiple environments](#multiple-environments)
- [Observability](#observability)
- [Slack-hosted apps](#slack-hosted-apps)
- [Frameworks and SDKs](#frameworks-and-sdks)

## Process model follows transport

| Shape | Process model | Fits |
|---|---|---|
| Incoming webhook only | None | Anything that can make an HTTP request |
| Script with a token | Short-lived, outbound only | Cron, CI, a laptop, a scheduled job |
| Socket Mode app | Long-lived process holding a WebSocket | A container, a VM, a small always-on host |
| HTTP app | Request/response | Serverless functions, containers, a traditional server |
| Custom workflow step | Request/response, invoked by Slack | Same as an HTTP app |

The one hard incompatibility is **Socket Mode on serverless**. A WebSocket needs a process that stays
alive; a function that sleeps between requests cannot hold one. Choosing Socket Mode is choosing a
long-lived host.

## Hosting options

Any of these work. The differences that matter for Slack specifically:

- **Serverless functions.** Cheapest for bursty traffic, and the natural fit for HTTP apps. The risk is
  cold starts against the three-second acknowledgement budget — split acknowledgement from work, or keep
  instances warm. Also make sure your framework's adapter gives you the raw request body for signature
  verification.
- **Containers or a small VM.** The only option for Socket Mode. Simplest mental model, and it lets you
  hold in-memory state, which serverless cannot.
- **A background worker plus a queue.** The right structure once work is slow or must not be lost. The
  Slack-facing endpoint only validates, enqueues, and acknowledges.
- **Your existing application.** Adding a Slack endpoint to a service you already run is often less work
  than standing up something new, and it inherits your logging, secrets, and deploy pipeline.

Scheduled scripts deserve a note: a script does not need hosting at all, but it does need something to
run it on a schedule with retries and visible failures. A CI scheduled job or a platform cron is
usually better than a personal machine, because a laptop that is asleep produces a silently missing
digest.

## Local development

Local development is where Socket Mode pays for itself, so use it if you can:

- **Socket Mode locally** — run the app on your machine, no tunnel, no public URL, no re-registering
  anything. Many teams develop in Socket Mode and deploy in HTTP mode; the handler code is identical
  and the transport is a configuration flag in the official frameworks.
- **A tunnel** — if you must test the HTTP path (or an interaction that only exists over HTTP), a tunnel
  gives you a public URL that forwards to localhost. Remember that free tunnel URLs change on every
  restart, and every change means editing the URL in app config, including the event subscription's
  verification step.
- **A separate development app.** Do not develop against the app your colleagues are using. Create a
  second app — ideally installed in a workspace of your own — so a bad deploy does not post nonsense in
  a real channel. A free personal workspace costs nothing and is the cleanest sandbox.

Test the parts that are easy to get wrong with real payloads rather than by clicking: signature
verification, retry handling, and modal submission parsing all have shapes you can capture once and
replay in tests.

## Configuration and secrets per environment

At minimum each environment needs: the bot token, the signing secret (HTTP apps), and the app-level
token (Socket Mode). Distributed apps also need the client ID and client secret, and somewhere to store
per-installation tokens.

- Keep these in the platform's secret store, injected as environment variables at runtime.
- Never commit them; never ship them to a browser.
- Per-installation tokens belong in a database, encrypted at rest, keyed by workspace. This is state,
  not configuration.
- If a token is rotated or an installation is revoked, the app should recover without a redeploy.

## Multiple environments

Slack has no concept of environments, so you create them by having **separate apps** — one per
environment, each with its own credentials and its own request URL. Trying to point one app at both
staging and production ends in cross-talk, because the request URL is a single field.

The corollary is that app configuration is duplicated per environment, which is exactly why manifests
matter: keep the manifest in version control and apply it to each app rather than hand-editing settings
in the browser twice. See `configuration.md`.

## Observability

Slack integrations fail silently more than most software, because nobody notices the absence of a
message. Build in:

- **Log every outbound API failure with the Slack error code.** The codes are specific and
  self-explanatory (`not_in_channel`, `missing_scope`, `channel_not_found`, `ratelimited`), which makes
  them excellent alert keys.
- **Alert on delivery failure rates**, not just on exceptions. Repeated event-delivery failures can get
  your subscription disabled.
- **Watch for 429s** as a capacity signal rather than an error to swallow.
- **Have a health check that exercises Slack**, such as a periodic call to the auth-test method. It
  catches a revoked token before a user does.

## Slack-hosted apps

Slack can host apps written with its Deno SDK on its own infrastructure, which removes hosting entirely
and gives you managed datastores and workflow functions. It is a real option and a narrow one — it means
adopting Deno and Slack's function model, and the tooling has been de-emphasized over time (the Slack
CLI no longer bundles Deno with its installer). Choose it only if the app is fully Slack-shaped and the
team is comfortable in that ecosystem. For most teams, self-hosting a Bolt app in a language they
already use is the lower-risk path.

## Frameworks and SDKs

Slack maintains SDKs for JavaScript/TypeScript, Python, and Java, plus the **Bolt** frameworks in those
same three languages. There is also the Deno SDK for the Slack-hosted path. Community libraries exist
for other languages, including Go.

Prefer Bolt where it exists. It handles the parts that are tedious and security-relevant — signature
verification, the acknowledgement dance, OAuth and installation storage, Socket Mode reconnection, and
routing by action identifier. Hand-rolling those is where subtle bugs live.

If your language has no official SDK, calling the Web API directly is entirely reasonable — it is plain
HTTP with a bearer token and JSON — but then you own signature verification, retry handling, and rate
limit backoff explicitly. Write those three as reusable helpers before writing features.
