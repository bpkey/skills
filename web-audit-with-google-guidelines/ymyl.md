# YMYL (Your Money or Your Life)

**When to load:** the site covers health, safety, finance, legal, civics/government, or anything that could meaningfully affect someone's wellbeing or money.

**Source:** SQRG §2.3 *Your Money or Your Life Topics*

## What Google rates

YMYL topics get a **much higher quality bar**. Low-quality YMYL pages can directly harm people, so raters scrutinize them more aggressively for E-E-A-T, accuracy, and trust signals.

The four YMYL categories:
- **Health or Safety** — physical, mental, emotional, online safety
- **Financial Security** — supporting self and family
- **Government, Civics & Society** — elections, voting, public institutions, civic info
- **Other** — anything else that hurts people or society if wrong

Test: *would a careful person consult an expert before acting on this content?* If yes → YMYL.

## Code-review checks (run only if site is YMYL)

- [ ] Every YMYL article carries an explicit byline tied to a credentialed author page (MD, JD, CFP, etc., visible)
- [ ] Pages display **last-updated** and **medically/financially reviewed** dates with the reviewer's name and credentials
- [ ] Disclaimers present where required: medical ("not medical advice"), financial ("not investment advice"), legal ("not legal advice")
- [ ] Sources cited inline with links to primary sources (peer-reviewed papers, government data, professional societies — not other blogs)
- [ ] Editorial policy page exists and is linked from every YMYL article
- [ ] Contact info is comprehensive: physical address, phone, real email (not just a contact form)
- [ ] If the site sells YMYL products (supplements, financial products, legal services), license/registration numbers are visible
- [ ] AI-generated YMYL content has a documented human-expert review step (not just an AI-author byline)

## Red flags (HIGH severity)

- YMYL article with no author, or author = "Editorial Team" / "Staff" with no human page
- YMYL article with no last-reviewed date
- Health/medical content with no MD or equivalent professional credential anywhere on the page
- Financial advice with no qualifications + monetized affiliate links to financial products
- AI-generated YMYL content with no disclosure or review process
- "About us" page that doesn't say who the people are or where the company is registered

## Auto-detection heuristics (for the audit step)

Grep the codebase for YMYL-leaning keywords to decide if YMYL applies:
- Health: `symptoms|treatment|diagnosis|medication|dosage|disease|cancer|diabetes|mental health|therapy|supplement`
- Finance: `invest|stock|crypto|mortgage|loan|insurance|retirement|tax|credit card|debt`
- Legal: `lawsuit|attorney|legal advice|rights|file a claim`
- Civics: `vote|election|register to vote|ballot|policy|government`

## Anchor quote

> "For pages about clear YMYL topics, we have very high Page Quality rating standards because low quality pages on such topics could potentially negatively impact a person's health, financial stability, or safety, or the welfare or well-being of society." (§2.3)
