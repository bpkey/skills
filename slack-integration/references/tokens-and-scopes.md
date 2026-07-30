# Tokens, scopes, and secrets

Auth is where Slack integrations most often go wrong in ways that are hard to undo — a token type that
carries the wrong identity, or a scope set that forces every customer to reinstall. Get this right
early.

## Contents

- [Token types](#token-types)
- [Choosing between a bot token and a user token](#choosing-between-a-bot-token-and-a-user-token)
- [Scopes](#scopes)
- [The channel visibility rule](#the-channel-visibility-rule)
- [Install flows](#install-flows)
- [Secret handling](#secret-handling)
- [Rotation and revocation](#rotation-and-revocation)

## Token types

| Token | Prefix | Represents | Notes |
|---|---|---|---|
| Bot token | `xoxb-` | The app itself, per installation | The default choice. Survives people leaving. Granular scopes. |
| User token | `xoxp-` | A specific person who authorized the app | Actions appear to be performed *by that person*. Inherits their visibility. |
| App-level token | `xapp-` | The app across all installations | Used for Socket Mode connections and a few app-wide operations. Not for Web API calls. |
| Workflow token | `xwfp-` | One execution of a workflow step | Short-lived, expires with the step, cannot be refreshed. Can carry borrowed visibility from the person who started the workflow. |
| Configuration token | — | A developer, for editing app configuration | Only for the App Manifest APIs. Short-lived and refreshable. Not a runtime credential. |
| Service token | — | Long-lived CLI credential for Slack-hosted apps | Only relevant to the Deno/Slack-hosted path. |

Legacy tokens — legacy bot tokens, workspace tokens, custom integration tokens, and "test tokens" —
are deprecated and cannot be created. Any tutorial that tells you to generate a test token is stale.

## Choosing between a bot token and a user token

Default to a **bot token**. It is a stable identity that does not depend on an employee's continued
existence, and it is what admins expect to see.

Use a **user token** only when one of these is true:

- **The API requires it.** Searching messages is the common case; a bot token cannot search at all.
  Reading a person's own DMs, setting their status or presence, and a few profile operations are the
  same.
- **The action must genuinely be attributed to the person.** Posting as them, reacting as them.
- **The tool is personal.** A script only you run, acting only on what you can already see.

Understand the trade before choosing it. A user token inherits that person's *entire* visibility —
every private channel and DM they are in. It is a far larger blast radius than a bot token, it stops
working when they are deactivated, and in a shared codebase it is an audit problem. If you need one,
scope it tightly and store it like a password.

## Scopes

Slack uses **granular scopes**, expressed as `resource:action` — `chat:write`, `channels:history`,
`users:read`, `files:write`. Bot and user scopes are requested separately.

Three rules that save real pain:

1. **Trace every scope to a call.** If you cannot name the API method that needs it, remove it.
   Reviewers and admins both read the scope list as a statement of intent.
2. **Adding a scope later forces a reinstall** in every workspace that has the app. For a
   single-workspace internal app that is one click. For a distributed app it is a migration with
   customer communication. Enumerate before shipping.
3. **The scopes for reading and writing differ per surface.** Public channels, private channels, group
   DMs, and DMs each have their own history and read scopes (`channels:*`, `groups:*`, `mpim:*`,
   `im:*`). Forgetting the private-channel variant is the most common `missing_scope` cause.

Scope names change slowly but do change. Confirm against the method's own documentation page, which
lists required scopes — that is the authoritative pairing.

## The channel visibility rule

This deserves its own section because it breaks more integrations than any scope error.

**A bot can only see and act in conversations it has been added to.** `channels:read` and
`channels:history` do not grant ambient access to every channel — they grant the *ability* to read
where the bot is a member. A brand new app in a workspace can see nothing.

Consequences to design around:

- Someone must invite the bot to each channel, or the app must create the channel itself.
- Posting to a channel the bot is not in fails with `not_in_channel`. Handle it and say something
  useful rather than logging a stack trace.
- Private channels require both the private-channel scope *and* an invitation.
- For a distributed app, make the invitation step part of onboarding and state it in your setup docs,
  because customers will otherwise report the app as broken.

The one exception worth knowing is the workflow token's borrowed visibility inside a workflow step,
which can reach conversations the app is not a member of when the person who started the workflow has
access.

## Install flows

**Single workspace, internal.** Install from the app's own settings page. You get a bot token, and
optionally a user token, directly. No OAuth code to write. This is the right answer for internal
tooling and it is worth resisting the urge to build the full flow you do not need.

**Multiple workspaces.** Implement OAuth — redirect to Slack's authorize endpoint with your client ID
and scopes, receive a code on your redirect URL, exchange it for tokens, and store them **per
workspace**. The exchange returns the workspace identity along with the tokens; key your storage on
it. Bolt and the official SDKs implement this flow including state verification; using them is
strongly preferable to hand-rolling.

Two things people forget: the redirect URL must be registered in app config and must match exactly,
and you need an uninstall path — subscribe to the app-uninstalled and token-revoked events and delete
the stored tokens, or you will keep trying to call a dead installation.

## Secret handling

- Read credentials from the environment or a secret manager. Never commit them, never bake them into a
  client bundle, never log them, and never paste them into an issue.
- Distinguish the **signing secret** (used to verify inbound requests) from **tokens** (used to make
  outbound calls). Both are secrets; they are not interchangeable.
- On a developer machine, an OS keychain beats a dotfile. In CI, use the platform's secret store. In
  production, use the host's secret mechanism rather than an environment file on disk.
- If a token leaks, revoke it first and rotate second. Slack will also proactively revoke tokens it
  detects in public repositories, which is a rude but effective safety net.

## Rotation and revocation

Slack supports **token rotation**, where tokens expire and are exchanged using a refresh token. It is
opt-in per app and is expected for apps distributed publicly. If you enable it, the SDKs handle the
refresh; if you hand-roll, you must persist the refresh token and handle expiry mid-request.

Regardless of rotation, build these in:

- Handle an auth failure (`invalid_auth`, `token_revoked`, `account_inactive`) as a first-class state,
  not a crash. Installations do get uninstalled underneath you.
- Provide a way to re-authorize without redeploying.
- Keep a record of which installation a stored token belongs to, so revoking one does not require
  guessing.
