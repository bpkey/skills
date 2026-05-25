# Content Structure: MC, SC, Ads

**When to load:** any audit — every page has these three parts and raters evaluate the balance.

**Source:** SQRG §2.4 *Understanding Webpage Content*

## What Google rates

Every page splits into three buckets:
- **Main Content (MC)** — what the page *exists for*. Should be prominent, near the top, and the focus.
- **Supplementary Content (SC)** — navigation, related links, comments. Should help, not distract.
- **Ads / Monetization** — fine to have, but must not block or hide the MC.

The presence of ads is not itself a quality signal. The *interference* of ads with MC is.

## Code-review checks

- [ ] On every content template, the MC is **above the fold** (or trivially scrollable to it on mobile)
- [ ] Hero/lead images and unrelated decorative SC don't push MC below the second viewport
- [ ] No ad slots, newsletter modals, cookie banners, or paywalls obscure the MC after they're dismissed once
- [ ] Sticky elements (headers, ad bars, CTAs) don't occupy more than ~15% of mobile viewport
- [ ] Interstitial pages (app-install, newsletter, email-gate) are not blocking access to free content the user came for
- [ ] No "MC under the fold" anti-patterns: long preambles, story-before-recipe, multi-screen of "filler"
- [ ] Cookie consent / GDPR banners offer a clear "reject" with the same prominence as "accept"
- [ ] Text rendering: no white-on-white, no `display:none` MC, no MC inside images that screen readers can't see

## Red flags (HIGH severity)

- Pop-up or modal that auto-fires before MC is read, with no easy dismiss
- Sticky ad bar that follows scroll and cannot be closed
- Recipe / how-to / answer pages where the answer is below 800px of story / SEO preamble
- Ads styled to look like MC or navigation (deceptive design — see also `lowest-quality-traits.md`)
- Interstitial blocking content access on mobile that's absent on desktop

## Anchor quote

> "The presence or absence of Ads is not by itself a reason for a High or Low quality rating." (§2.4.3)
> "Pages with Ads, SC, or other features that significantly distract from or make it difficult for the user to efficiently access the information they want from the page should typically be given a Low rating." (§5.3)
