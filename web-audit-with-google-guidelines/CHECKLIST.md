# Full-Audit Checklist

**When to load:** scope = "full audit". Walks every topic in order.

Run each section by reading the linked topic file and applying its checks. After all sections, aggregate findings into `google-guidelines-audit.md` (see `SKILL.md` Step 4).

## 1. Page Purpose

→ Load `page-purpose.md`. Apply checks. Record findings.

Critical question: *can you state in one sentence what each page is for?*

## 2. YMYL detection

→ Load `ymyl.md`. Run the keyword grep. Decide YMYL yes/no/partial.

If YMYL, every downstream check applies a higher standard.

## 3. Content structure

→ Load `content-structure.md`. Apply checks.

Critical question: *is the MC the first thing the user sees, or is it buried under SC and ads?*

## 4. Attribution

→ Load `attribution.md`. Apply checks.

Critical question: *if a user wanted to know who runs this site and how to contact them, could they find out in under 30 seconds?*

## 5. Main Content quality

→ Load `main-content-quality.md`. Apply checks.

Sample 5-10 representative pieces of content (recent articles, top products, top landing pages). Evaluate each on the four axes: effort, originality, talent, accuracy.

## 6. E-E-A-T

→ Load `eeat.md`. Apply checks.

Critical question: *if Google needed to verify the author was a real, credentialed person, could it?*

## 7. Lowest-quality traits

→ Load `lowest-quality-traits.md`. Apply checks.

Pay special attention to: ad styling, modal/popup behavior, button labels, hidden content, malicious patterns.

## 8. Spam patterns

→ Load `spam-patterns.md`. Apply checks.

Pay special attention to: programmatic SEO, AI-generated content, affiliate links, syndicated/embedded content.

## 9. High/Highest quality signals (aspirational)

→ Load `quality-signals.md`. Use as a positive checklist.

What's the site's claim to being a go-to source? Can it be defended?

## 10. Compose the report

Aggregate every finding by topic and severity. Write to `google-guidelines-audit.md`. Surface counts to the user.

## 11. Walk fixes

For each HIGH-severity finding, propose a fix one at a time per the SKILL.md fix-proposal flow.
