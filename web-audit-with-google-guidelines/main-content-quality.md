# Main Content Quality

**When to load:** any audit — MC quality is the single biggest signal.

**Source:** SQRG §3.2 *Quality of the Main Content*, §5.2 *Low Quality MC*, §7.1 *High Quality MC*, §8.1 *Very High Quality MC*

## What Google rates

MC quality is judged on four axes:
- **Effort** — did a human actively work on this?
- **Originality** — is this unique, or just rearranged from other sites?
- **Talent / Skill** — does the creator know what they're doing?
- **Accuracy** — for informational / YMYL pages, does it match expert consensus?

"Typical" or "average" content is **Medium** quality. To be **High**, MC must demonstrate effort, originality, *or* talent that makes the page stand out.

## Code-review checks

### Effort
- [ ] Articles have substance (no 200-word "thin content" posts on topics that need depth)
- [ ] Templated pages (programmatic SEO) carry unique research, data, or insight per page — not just synonym-swapped boilerplate
- [ ] Custom assets exist where appropriate: original diagrams, photos, charts, code samples

### Originality
- [ ] No mass-imported affiliate product descriptions copied from manufacturers
- [ ] Reviews include first-hand evidence (photos of the product in use, test data) — not paraphrased Amazon reviews
- [ ] AI-generated content has documented human editorial pass (not raw model output published verbatim)

### Talent / skill
- [ ] Writing is edited (spell-check, grammar, consistent voice — not raw transcripts)
- [ ] Technical content is written by people who can demonstrate they know the subject (code that runs, recipes that work, instructions tested)

### Accuracy (especially for informational / YMYL)
- [ ] Facts cite primary sources, not other blogs
- [ ] Dates and stats are current (no "as of 2018" on a 2025-dated page)
- [ ] No factual errors that a domain expert would catch on a first read

### Title & MC alignment
- [ ] Page `<title>` and `<h1>` accurately describe the MC (not clickbait, not exaggerated)
- [ ] No bait-and-switch — the content delivers what the title promises
- [ ] No "filler" preamble pushing the real answer below the fold (looking at you, recipe sites)

## Red flags (HIGH severity)

- Article that reads like AI output with no editing (repetitive intros, generic phrasing, no concrete details, hallucinated stats)
- Page with `<h1>` like "Best X 2024" but published 2026 and unchanged
- "Listicle" or "best of" page where every item is paraphrased from a single source
- Recipe / how-to where the actual instructions are <10% of the word count
- Templated pages (e.g. `/cities/<city>/<service>`) where >80% of text is identical across pages

## Anchor quote

> "For most pages, the quality of the MC can be determined by the amount of effort, originality, and talent or skill that went into the creation of the content." (§3.2)
> "The criteria 'little to no effort' means little to no effort of any type." (§4.6.6)
> "The use of Generative AI tools alone does not determine the level of effort or Page Quality rating." (§4.6.6)
