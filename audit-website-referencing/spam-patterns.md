# Spam Patterns

**When to load:** full audit, or when the site relies on programmatic content, has affiliates, or scaled with AI.

**Source:** SQRG §4.6 *Spammy Webpages*

## What Google rates

Spam patterns get the **Lowest** rating. Google's six spam categories:

1. **No MC / unusable MC** — gibberish, empty templates, or content so bad the page has no purpose
2. **Hacked / defaced / spammed** — unauthorized content injected into legit pages
3. **Expired domain abuse** — buying an aged domain to ride its reputation for unrelated content
4. **Site reputation abuse** — host site lets third parties publish on it to capture host's ranking ("parasite SEO")
5. **Scaled content abuse** — mass-generated low-value pages (AI or otherwise) that don't help users
6. **Copied / paraphrased / no-added-value MC** — scraped or AI-paraphrased without effort or originality

## Code-review checks

### Scaled content (§4.6.5)
- [ ] No template pages where the only difference is a swapped city / product / keyword
- [ ] Programmatic SEO pages each have **unique research, data, or first-hand insight** — not just synonym swaps
- [ ] If the site uses AI to generate content at scale, every published piece has a human edit log
- [ ] No pages with content that "makes little or no sense to a reader but contains search keywords" (keyword stuffing)
- [ ] No auto-translated content republished without human review

### Copied / paraphrased (§4.6.6, §4.6.7)
- [ ] No mass-imported manufacturer descriptions on product pages without added review / test / context
- [ ] No AI-paraphrased summaries of Wikipedia / authoritative sources passed off as original
- [ ] No "best of" lists assembled from existing reviews with no first-hand testing
- [ ] Embedded content (YouTube embeds, social media, etc.) is supplemented with significant original commentary
- [ ] Syndicated content (Reuters, AP) is clearly labeled as syndicated — not passed off as original reporting
- [ ] No raw model output published verbatim (telltale signs: "As an AI language model", "I cannot", "Sure, here is...", "I hope this helps!", over-use of "delve / leverage / robust")

### Site reputation abuse (§4.6.4) — "parasite SEO"
- [ ] Newspaper / education / government site doesn't host third-party content on unrelated commercial topics (e.g. coupons, casino reviews, payday loans) just to rank
- [ ] If hosting third-party content (sponsored, white-label, freelance), the purpose is to serve readers — not to capture ranking
- [ ] Subdomain or subdirectory leasing arrangements are flagged for review
- [ ] User-generated content sections are moderated for spam/SEO-only posts

### Expired domain (§4.6.3)
- [ ] Domain history check: does the current content match the historical use of the domain? Run through Wayback Machine.
- [ ] If using an aged domain bought specifically for SEO, the current content should be on-topic for the original use, or the prior reputation is unrelated and not being leveraged

### Hacked / defaced (§4.6.2)
- [ ] Comments / forums have spam moderation (rel=ugc, automated filters, manual review)
- [ ] No injected `<script>` tags, hidden links, or off-topic SEO text in templates
- [ ] Dependencies and CMS are patched (look at composer.lock / package-lock.json / WordPress version)
- [ ] Random pages (`/cheap-viagra`, `/payday-loans-uk`) don't appear in the sitemap or search index

## Red flags (HIGH severity)

- AI-generated content with no human edit, no fact-check, no original insight
- Programmatic pages where Levenshtein distance between adjacent pages is <10% of total content
- Third-party "guest post" sections that have nothing to do with the host site's topic
- Site-wide "Coupons" / "Best Casinos" / "Best CBD" subdirectory on an unrelated reputable site
- Sitemap contains pages that 404 or redirect to spam (post-hack residue)
- `rel="sponsored"` or `rel="nofollow"` missing on monetized links

## Auto-detection heuristics

For the audit step, the skill can detect:
- Programmatic pages: look for routes with shape `/x/[slug]` and sample 10 — diff them
- AI-text giveaways: grep generated content for phrases like `As an AI`, `I cannot`, `I apologize`, `In conclusion,`, `Furthermore,`
- Missing `rel="sponsored"` / `rel="nofollow"`: grep affiliate link patterns (`?ref=`, `?tag=`, known affiliate hosts) for `rel=` attribute
- Hacked-page residue: check sitemap for keyword spam URLs

## Anchor quote

> "Pages and websites made up of content created at scale with no original content or added value for users, should be rated Lowest, no matter how they are created." (§4.6.5)
> "Likewise, the use of Generative AI tools alone does not determine the level of effort or Page Quality rating. Generative AI tools may be used for high quality and low quality content creation." (§4.6.6)
