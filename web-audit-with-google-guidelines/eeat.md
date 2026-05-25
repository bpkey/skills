# E-E-A-T (Experience, Expertise, Authoritativeness, Trust)

**When to load:** any content site, blog, news, product review site, anywhere authorship matters. Especially required for YMYL.

**Source:** SQRG §3.3 *Reputation*, §3.4 *E-E-A-T*

## What Google rates

E-E-A-T is the central trust framework:
- **Experience** — has the creator personally done this? (product review by an owner, travel guide by someone who went)
- **Expertise** — does the creator know the field? (skilled electrician for wiring, MD for medical)
- **Authoritativeness** — is this the go-to source on the topic? (government page for passports)
- **Trust** — is it accurate, honest, safe? *Trust is the most important.* An untrustworthy page is low E-E-A-T no matter how expert.

E-E-A-T is informed by (a) what the site says about itself, (b) what independent sources say, and (c) what's visible on the page.

## Code-review checks

### Author surface (Experience + Expertise)
- [ ] Every article has a visible byline
- [ ] Byline links to a real author page (`/authors/<slug>`)
- [ ] Author page shows: real name, photo, bio, credentials relevant to the topic, contact or social link, list of other articles
- [ ] For YMYL topics: credentials match the topic (MD for medical, CFP for finance, JD for legal)
- [ ] For product reviews: evidence of first-hand use (photos, video, test data) — not just rephrased manufacturer copy
- [ ] Co-author / editor / reviewer credit shown when content has had a review pass

### Site-level reputation signals (Trust)
- [ ] Site has a real `/about` page with the team, history, mission, location (see `attribution.md`)
- [ ] Site has a published editorial / ethics policy explaining how content is researched, written, reviewed, corrected
- [ ] Corrections policy exists — and corrections are visible on past articles when they happen
- [ ] External press / awards / citations linked from `/about` or `/press`
- [ ] Site is HTTPS, valid cert, no mixed content warnings
- [ ] For e-commerce / financial: SSL, recognizable payment processors, visible refund and dispute policies

### Independent-source coverage
- [ ] Site is registered / claimed on relevant directories (Google Business, industry directories)
- [ ] Wikipedia entry exists if the site is large enough; if not, at least independent press / podcast / interview coverage
- [ ] Author profiles link out to ORCID, LinkedIn, or professional society pages where appropriate

### Conflict of interest disclosure
- [ ] Affiliate-link disclosure clearly visible on pages with affiliate links (not buried in footer)
- [ ] Sponsored content labeled "Sponsored" / "Advertisement" prominently, not as small grey text
- [ ] Author financial relationships disclosed where they matter (paid by manufacturer, equity in company, etc.)

## Red flags (HIGH severity)

- Bylines that don't link, or link to a generic `/author/admin` stub
- "Editorial Team" or "Staff Writer" as the only attribution on every article
- AI-generated content with fake AI-author profiles (photo + bio + credentials, but the person doesn't exist)
- Author profile claims credentials with no verification path (no link to license number, ORCID, LinkedIn)
- Product reviews with no evidence the reviewer used the product (no original photos, no test data, no purchase receipt)
- "Reviewed by Dr. X" badge with no actual review trail or revision history
- Affiliate-monetized site with no disclosure, or disclosure hidden in footer fine print

## Anchor quote

> "Trust is the most important member of the E-E-A-T family because untrustworthy pages have low E-E-A-T no matter how Experienced, Expert, or Authoritative they may seem." (§3.4)
> "The amount of expertise needed depends on the topic of the page." (§3.4)
> "The website or content creator may not be a trustworthy source if there is a clear conflict of interest." (§3.4)
