# App configuration and distribution

Configuration is the part of a Slack app that lives in Slack rather than in your repository, which makes
it the part most likely to drift, be undocumented, and differ between environments. Manifests fix that.

## Contents

- [What lives in app configuration](#what-lives-in-app-configuration)
- [Manifests](#manifests)
- [Creating and configuring apps programmatically](#creating-and-configuring-apps-programmatically)
- [Who can install, and admin approval](#who-can-install-and-admin-approval)
- [Internal versus distributed](#internal-versus-distributed)
- [Enterprise Grid and org-level apps](#enterprise-grid-and-org-level-apps)
- [Plan gates](#plan-gates)
- [Workspace policy you cannot see](#workspace-policy-you-cannot-see)

## What lives in app configuration

Everything Slack needs to know about your app that is not code:

- Display information — name, description, icon, background color, and the bot's display name
- Requested bot scopes and user scopes
- Event subscriptions and the request URL that receives them
- The interactivity request URL, slash commands, shortcuts, and unfurl domains
- App Home settings — whether the Messages tab exists and whether users can send it messages
- Socket Mode on or off, and app-level tokens
- OAuth redirect URLs
- Workflow steps your app exposes
- Distribution settings and, for agents, the agent/assistant feature toggle

Because this state is remote, two apps that look identical in code can behave completely differently.
When debugging something inexplicable, compare configuration before comparing code.

## Manifests

An **app manifest** is the whole configuration as one YAML or JSON document. It is the single most
useful hygiene practice in this domain:

- **Commit it.** The manifest belongs in the repository next to the code it configures. Configuration
  changes then show up in review like everything else.
- **Create apps from it.** A new environment or a new contributor's development app is one paste rather
  than twenty form fields.
- **Diff it.** When production works and staging does not, diffing two manifests finds it in seconds.

Keep the caveats in mind: the manifest contains no secrets, so tokens and signing secrets still come
from your secret store; URLs differ per environment, so either template them or keep one manifest per
environment; and the schema evolves, so a manifest exported a year ago may need updating before it
applies cleanly.

## Creating and configuring apps programmatically

Slack exposes manifest APIs for creating an app, reading its manifest, updating it, and rotating the
credentials used to do so. These use a **configuration token** rather than a bot token — a
developer-scoped, short-lived credential generated from the app management page, distinct from any
runtime token.

This is worth wiring up when you manage several apps or several environments, because it turns app
setup into a reproducible script. It is overkill for a single internal app you will configure once.

## Who can install, and admin approval

A workspace decides who may install apps, and whether installs require admin approval. Three outcomes
you should design for:

- **Open** — members install apps themselves. The consent screen shows an Allow button.
- **Approval required** — the member requests, an owner or admin approves. Your setup instructions need
  to say this, because the customer will otherwise think the install is broken.
- **Restricted** — only admins install. Same, but with more waiting.

Policy can also differ between Marketplace apps and apps built in-house, so an internal app may face
approval that a listed app does not. If you are advising someone on whether they can install, the
authoritative answer is the workspace's app-management settings, which only owners can see — but the
practical test is what the install button says: "Add to Slack" or "Install" means you can, a request
prompt means you cannot.

Approval requirements can also be scoped to particular sensitive permissions, so an app that installs
fine with a modest scope set may hit approval when you add a broader one.

## Internal versus distributed

**Internal** — one workspace, installed from the app's own settings page, no OAuth code, no review.
This is most integrations, and it should stay this simple.

**Distributed, unlisted** — other organizations install it via your own OAuth link. You need the full
install flow, per-installation token storage, and an uninstall path. Note the policy dimension here:
apps distributed outside the Marketplace face materially tighter limits on reading conversation
history, which can invalidate a design. Check current policy if your product reads messages.

**Marketplace listed** — the same plus Slack's review process, which examines scope justification,
security practices, privacy policy, and support commitments. Budget for review iterations. Two
consequences to plan for early: Socket Mode apps cannot be listed, and reviewers will push back on
scopes you cannot justify.

## Enterprise Grid and org-level apps

Grid is Slack's multi-workspace enterprise tier and it changes the model:

- An app can be installed to a single workspace or **org-wide**, and org-wide installation is generally
  an org-admin decision.
- Approval may exist at both org and workspace level.
- The administrative APIs — bulk user, channel, and workspace management — are Grid features and are not
  available on smaller plans regardless of permissions.
- Identifiers differ: an org has its own identity alongside per-workspace ones, and code that assumes
  one workspace per installation will mis-key its token storage.

If you are building for enterprise customers, decide early whether you support org-wide installation,
because retrofitting it touches token storage, event routing, and every place you assumed a single
workspace.

## Plan gates

Capabilities gated by the customer's subscription, not by permissions:

- **Workflow Builder** requires a paid plan. **Custom workflow steps** cannot be developed on the free
  plan.
- **Administrative APIs** for managing users, channels, and workspaces are Grid-tier.
- **Audit logs and the Discovery API** are top-tier enterprise features.
- Free workspaces cap the number of installed integrations and limit history retention, which affects
  anything that reads back in time.

Check the plan before promising a feature. No amount of admin cooperation adds a capability the
subscription does not include, and discovering this after building is the most avoidable form of rework
in this domain.

## Workspace policy you cannot see

As a non-admin developer you cannot read most of the policy that governs your app. When something is
blocked and you cannot see why, the questions to put to an owner are: is app approval required and am I
permitted to install; are self-built apps restricted separately from Marketplace apps; can members add
apps to channels, including private ones; and are there scope-level restrictions in force. Those four
answers explain nearly every unexplained install or runtime failure.
