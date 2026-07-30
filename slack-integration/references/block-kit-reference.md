# Block Kit reference — the actual type inventory

`ui.md` covers how to *think* about Slack's UI. This file is the inventory: what exists, what kind of
thing each item is, and how to get the authoritative spec for one. Read it when you are assembling a
payload and need real names rather than a description.

**Two warnings before you use anything here.**

First, Block Kit has grown a lot, and a meaningful share of the newer entries are aimed at agents,
Salesforce surfaces, or canvases rather than at ordinary messages and modals. Availability differs by
surface and sometimes by product tier, and the index pages do not state it.

Second, **a documentation page slug is not the `type` value.** The button's page is
`button-element` but its type is `"button"`. Do not infer a type string from a slug.

So: for anything outside the well-established set below, fetch the element's own page before using it.
The URL pattern is predictable, which makes this cheap:

```
https://docs.slack.dev/reference/block-kit/blocks/<block-name>-block
https://docs.slack.dev/reference/block-kit/block-elements/<element-name>-element
```

Each page gives the exact `type`, the required and optional fields, which blocks may contain it, and a
copyable example. Fetch one page rather than guessing.

## Contents

- [Blocks](#blocks)
- [Interactive and input elements](#interactive-and-input-elements)
- [Display elements](#display-elements)
- [Rich text internals](#rich-text-internals)
- [Which container holds what](#which-container-holds-what)
- [Validating a payload](#validating-a-payload)

## Blocks

The current block list, as named in the reference index:

**The long-established set, safe to reach for:**

| Block | `type` | What it is |
|---|---|---|
| Section | `section` | Text, optionally with fields or one accessory element on the right. The workhorse. |
| Header | `header` | Large bold heading text. |
| Divider | `divider` | A horizontal rule. |
| Context | `context` | Small muted text and images, for metadata lines. |
| Actions | `actions` | A row of interactive elements. |
| Input | `input` | One labelled form control. Primarily a modal and Home tab construct. |
| Image | `image` | An image with alt text. |
| File | `file` | A reference to a remote file. |
| Video | `video` | An embedded video. |
| Rich text | `rich_text` | Formatted text built from structured sub-elements rather than markup. |

**Newer additions — confirm the type string, surface support, and any tier requirement on the page
before use:** Alert, Card, Carousel, Container, Context actions, Data table, Data visualization,
Markdown, Plan, Table, Task card.

Several of these exist for agent and Salesforce experiences. The Markdown block is the notable
general-purpose one, since it accepts standard Markdown instead of Slack's own markup — which, if
available on your surface, removes a whole category of formatting conversion work.

## Interactive and input elements

These are the controls. Types given are the established ones; treat anything marked *newer* as
needing a page check.

**Buttons**

| Element | `type` | Notes |
|---|---|---|
| Button | `button` | Lives in a `section` accessory or an `actions` block. Can carry a value, a URL, and a confirm dialog. |
| Workflow button | `workflow_button` | Starts a Workflow Builder workflow from a message. |
| Icon button | *newer* | Compact icon-only button. |
| Feedback buttons | *newer* | Thumbs up/down affordance, aimed at agent replies. |

**Choice controls**

| Element | `type` | Notes |
|---|---|---|
| Select menu | `static_select`, `external_select`, `users_select`, `conversations_select`, `channels_select` | One value. The variants differ only in where options come from — your list, your remote endpoint, or Slack's own directories. |
| Multi-select menu | the same names prefixed `multi_` | Several values. |
| Checkboxes | `checkboxes` | Multiple independent options. |
| Radio button group | `radio_buttons` | One of several. |
| Overflow menu | `overflow` | A compact "more actions" menu. |

**Text and value inputs**

| Element | `type` | Notes |
|---|---|---|
| Plain-text input | `plain_text_input` | Single or multi-line. |
| Rich-text input | `rich_text_input` | Preserves the user's formatting. |
| Number input | `number_input` | Numeric, with bounds. |
| Email input | *check page* | Email-constrained text. |
| URL input | *check page* | URL-constrained text. |
| File input | `file_input` | Collects an upload. |

**Date and time**

| Element | `type` |
|---|---|
| Date picker | `datepicker` |
| Time picker | `timepicker` |
| Date-time picker | `datetimepicker` |

The input elements are chiefly modal and Home tab constructs — they belong inside an `input` block.
Interactive elements in messages generally mean buttons, selects, and overflow menus. When something is
rejected on a surface, this distinction is the first thing to check.

## Display elements

Non-interactive pieces that appear inside blocks: image, file, text, tag, citation, color, URL source,
canvas, canvas message unfurl, list record, Salesforce data field, and work object mention.

Citation and feedback-oriented elements exist because agent replies need to show sources and collect a
verdict. If you are building an agent, look at these before inventing your own footnote convention.

## Rich text internals

The `rich_text` block is a tree, not a string, which is why it can round-trip formatting reliably.

Its container sub-elements are `rich_text_section`, `rich_text_list`, `rich_text_quote`, and
`rich_text_preformatted`. Inside those live inline pieces: text, link, emoji, and typed mentions for a
channel, user, usergroup, team, broadcast, date, message, attachment, workflow, and canvas user.

Two practical consequences. First, this is the reliable way to *read* what a user typed in a rich-text
input, so expect to walk this tree rather than parse a string. Second, mentions are structured nodes
carrying IDs — which is why interpolating a display name into text never produces a working mention.

## Which container holds what

The rule that resolves most `invalid_blocks` errors:

- A **`section`** holds text plus at most **one** accessory element.
- An **`actions`** block holds several interactive elements in a row.
- An **`input`** block holds exactly **one** element and gives it a label.
- **`context`** holds only small text and images.
- Everything nests one level deep. There is no arbitrary nesting, no grid, and no positioning.

If a layout cannot be expressed this way, it cannot be expressed in Block Kit. Restructure the
information rather than fighting the toolkit.

## Validating a payload

Slack's rejection messages rarely name the offending block, so do not debug by reading them:

1. Paste the payload into **Block Kit Builder** on `docs.slack.dev`. It validates precisely and renders
   live, and it is faster than any round-trip through your own code.
2. If a payload works in the Builder but fails from your app, the difference is usually the surface —
   an element valid in a modal is not necessarily valid in a message.
3. Bisect by removing blocks when the payload is generated dynamically and you cannot see it whole.
4. Always confirm the `text` fallback field is set alongside blocks, or the message arrives as an empty
   notification.
