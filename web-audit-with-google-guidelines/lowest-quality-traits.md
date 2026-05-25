# Lowest-Quality Traits (Untrustworthy / Deceptive)

**When to load:** full audit, or when something feels off about the site.

**Source:** SQRG §4.5 *Untrustworthy Webpages or Websites*

## What Google rates

Pages get the **Lowest** rating (the worst possible) when they're deceptive, obstructive, or appear malicious. Even *suspicion* of these patterns is enough — raters don't need proof.

The Lowest traits split into:
1. Inadequate info about who runs the site (esp. for YMYL / commerce)
2. Lowest E-E-A-T or reputation
3. Deceptive purpose / info / design
4. Deliberately obscured MC
5. Suspected malicious behavior (scams, phishing, malware)

## Code-review checks

### Inadequate information (§4.5.1)
- [ ] Any payment / signup / data-collection flow has visible owner identity within one click
- [ ] YMYL pages link to author + about + contact + privacy from the article itself
- [ ] No "ghost site" pages — every published route ties back to a real entity

### Deceptive design (§4.5.3)
- [ ] No ad units styled to look like search results, navigation, or article content
- [ ] No buttons / X close-buttons that actually open downloads or redirect
- [ ] No `<title>` / `<h1>` / OG metadata that misrepresents the content
- [ ] No fake brand impersonation (logos, names, URLs that mimic another company)
- [ ] No AI-generated author profiles passed off as humans
- [ ] No fake "personal experience" framings for content written by agencies / AI
- [ ] No false claims of testing / certification / awards
- [ ] No fake-physical-store claims (real address required if claimed)

### Obstructed MC (§4.5.4)
- [ ] No ads that follow scroll and cannot be closed
- [ ] No pop-ups requiring an action (email signup, app install) before MC is accessible
- [ ] No interstitials forcing app downloads or notifications
- [ ] No `display: none` MC, no white-on-white text, no MC pushed below 5+ screens of ads
- [ ] Paywalls and logins are clearly labeled (not deceptive) — these are fine

### Suspected malicious behavior (§4.5.5)
- [ ] No forms collecting unnecessary PII (SSN, government ID, full bank details) without a clear legitimate reason
- [ ] No password-collection patterns that look like phishing (re-asking for Gmail / Facebook creds in iframes)
- [ ] No downloads served from third-party CDNs without integrity check
- [ ] HTTPS everywhere; no mixed content; valid cert; no malware-flagged third-party scripts
- [ ] CSP / SRI configured; no unbounded eval / inline scripts on sensitive pages

## Red flags (HIGH severity, often skill-flagged but human-reviewed)

- Modal that traps focus and cannot be dismissed without converting
- Ads inside the article body styled identically to article links
- "Login with Google" / "Login with Facebook" buttons that open the credential form *on your site* instead of the OAuth provider
- Email-gate that requires signup to read the rest of an article that was indexable on Google
- Pages with `noindex` for Googlebot detection while serving full content to crawlers (cloaking — see also `spam-patterns.md`)

## Auto-fix policy

The skill will **flag but not auto-fix** business decisions:
- Ad density and placement (business call)
- Paywall presence (business call)
- Newsletter modal frequency (business call)

The skill will **propose fixes** for:
- Missing close button on modals
- Ads styled to look like navigation (CSS fix)
- White-on-white text
- Misleading button labels

## Anchor quote

> "Highly untrustworthy pages should be given the Lowest rating even if you are unable to 'prove' the webpage or site is harmful." (§4.5)
> "Pages are untrustworthy if the MC is deliberately obstructed or obscured due to Ads, SC, interstitial pages, download links or other content that is beneficial to the website owner but not necessarily the website visitor." (§4.5.4)
