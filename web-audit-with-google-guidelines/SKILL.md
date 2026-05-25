---
name: web-audit-with-google-guidelines
description: Audit a website codebase against Google's Search Quality Rater Guidelines (E-E-A-T, YMYL, page purpose, content structure, attribution, spam patterns, trust signals). Use whenever the user invokes /web-audit-with-google-guidelines, asks to "review the site for Google quality", "check E-E-A-T", "audit for SEO quality signals", "see how Google would rate this site", or wants to know how their site would score against Google's rater rubric. Writes a findings report to google-guidelines-audit.md at the codebase root, then offers to implement fixes for high-severity issues one at a time with user approval.
---

# /web-audit-with-google-guidelines

You are auditing a website codebase against Google's *Search Quality Rater Guidelines* (SQRG, doc version September 11, 2025).

This is **not** a technical SEO audit (no Lighthouse, no Core Web Vitals, no schema.org). It is a *content quality and trust* audit, mapping Google's rater criteria onto code-level checks.

## Step 1 — Establish scope

Ask the user (one combined `AskUserQuestion` call):

1. **Codebase root** — default to `pwd`. Confirm.
2. **Site type** — blog/news, e-commerce, SaaS marketing, docs, community/forum, mixed/other. Affects which reference files to load.
3. **YMYL?** — does the site cover health, finance, legal, civics, or safety? You can pre-scan by grepping the codebase for the keywords listed in `ymyl.md` and pre-fill a guess.
4. **Scope** — full audit (load `CHECKLIST.md` and walk every topic), or spot-check (pick one topic).

## Step 2 — Load only the relevant topic files

Use this routing table. Load on-demand with the `Read` tool — do NOT preload all topic files.

| Site type | Always load | Load if YMYL |
|-----------|-------------|--------------|
| Blog / news | `page-purpose.md`, `attribution.md`, `eeat.md`, `main-content-quality.md` | `ymyl.md` |
| E-commerce | `page-purpose.md`, `attribution.md`, `content-structure.md`, `lowest-quality-traits.md` | `ymyl.md` (always — products are YMYL territory) |
| SaaS marketing | `page-purpose.md`, `attribution.md`, `eeat.md`, `content-structure.md` | — |
| Docs / reference | `page-purpose.md`, `attribution.md`, `main-content-quality.md`, `quality-signals.md` | — |
| Community / forum | `page-purpose.md`, `attribution.md`, `lowest-quality-traits.md`, `spam-patterns.md` | — |
| Full audit (any type) | `CHECKLIST.md` (links to everything) | — |

Also load `spam-patterns.md` whenever the codebase has signs of programmatic SEO, AI-generated content, or affiliate monetization (grep for `/cities/`, `/[slug]/`, `aff=`, `ref=`, `As an AI`, `tag=`).

## Step 3 — Run the checks

For each loaded topic file:

1. Read the file. Each lists **code-review checks** (checkboxes) and **red flags** (HIGH severity).
2. Use `Grep`, `Glob`, and `Read` to evaluate each check against the actual codebase. Look for the relevant components, routes, templates, layouts, and content samples.
3. Record findings as `{topic, check, severity, file:line, evidence, fix-proposal}` tuples in memory.

Severity rules:
- **HIGH** — anything labeled "red flag" in the topic file; anything that maps to a Google "Lowest" trait; missing entity attribution on YMYL/commerce; deceptive design
- **MEDIUM** — anything that maps to "Low" quality (poor E-E-A-T, thin content, missing context)
- **LOW** — improvement opportunities; aspirational items from `quality-signals.md`

## Step 4 — Write the audit report

Write findings to `<codebase-root>/google-guidelines-audit.md`, overwriting any prior version. Use this structure:

```markdown
# Google Guidelines Audit

_Run: <ISO date>. Codebase: <root>. Site type: <type>. YMYL: yes/no._

## Summary

- **High:** <count>
- **Medium:** <count>
- **Low:** <count>

## High-severity findings

### <topic name>

- **<check>** — `<file>:<line>`
  - Evidence: <one-line quote or observation>
  - Proposed fix: <one-line description>

## Medium-severity findings

(same format)

## Low-severity / aspirational

(same format)

## What was not audited

- <e.g. live-site behavior, Lighthouse scores, schema.org markup — those need different tools>
```

Each finding should cite a real `file:line` so the user can jump to it.

## Step 5 — Offer to fix high-severity issues

After writing the report, surface the high count and walk one at a time:

> "Found N high-severity issues. Want me to fix #1: <one-line description>? (yes / skip / explain more)"

For each `yes`, propose a concrete diff before implementing, get approval, implement it, move on.

### What to auto-fix

- Missing components: scaffold `AuthorBio.tsx` / `EditorialPolicy.tsx` / `Disclaimer.tsx` and wire to routes
- Missing pages: scaffold `/about`, `/contact`, `/editorial-policy`, `/privacy` with stub content the user fills
- Missing metadata: add `<title>`, `<meta description>`, `<meta author>`, byline structured data
- CSS fixes: remove white-on-white text, fix ad styling that mimics navigation, add visible close buttons to modals
- Link attributes: add `rel="sponsored"` / `rel="nofollow"` to affiliate links
- Content gates: remove `noindex` for cloaking patterns, fix paywall logic that lies to Googlebot

### What to flag but NOT auto-fix

These are business decisions — leave them for the user:
- Ad density and placement
- Paywall presence
- Newsletter modal frequency / timing
- Removing existing content (even if low quality)
- Changing editorial voice or strategy
- Investing in original photography / data / research

## Reference files

- `page-purpose.md` — §2.2 beneficial purpose
- `ymyl.md` — §2.3 YMYL topic detection and standards
- `content-structure.md` — §2.4 MC vs SC vs Ads balance
- `attribution.md` — §2.5 who runs the site, who wrote it, how to contact
- `main-content-quality.md` — §3.2, §5.2, §7.1, §8.1 MC quality across tiers
- `eeat.md` — §3.3, §3.4 Experience, Expertise, Authoritativeness, Trust
- `lowest-quality-traits.md` — §4.5 deception, obstruction, malicious patterns
- `spam-patterns.md` — §4.6 scaled content, parasite SEO, expired domain, copied content
- `quality-signals.md` — §7, §8 what HIGH and HIGHEST quality look like
- `CHECKLIST.md` — full-audit composite walkthrough

The topic files above are the distilled, actionable artifacts — they are self-contained and the skill never reads the original PDF at runtime.

## Updating the skill when Google publishes a new SQRG version

The topic files were distilled from Part 1 (Page Quality Rating Guideline, §§1–11) of Google's *Search Quality Rater Guidelines*. When Google publishes a new version:

1. Download the latest PDF from the public Google URL:
   `https://static.googleusercontent.com/media/guidelines.raterhub.com/en//searchqualityevaluatorguidelines.pdf`
2. Extract the Part 1 page range to text (find where "Part 2:" begins — Part 1 ends just before; in the 2025-09 doc that was pages 9–93). A `pypdf` loop over `reader.pages[i].extract_text()` works.
3. Diff the new extract against your notes from the previous version.
4. Update affected topic files to match the new guidance.
5. Commit and push.
