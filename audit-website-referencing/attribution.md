# Attribution: Who Is Responsible

**When to load:** any audit — every site needs to clearly identify who's behind it.

**Source:** SQRG §2.5 *Understanding the Website* (homepage, who's responsible, About / Contact / Customer Service)

## What Google rates

Raters need to identify:
1. Who is responsible for the **website** (the legal entity).
2. Who created the **content on each page** (the author or org).
3. How to **contact** them.

A YMYL or transactional site with no clear attribution gets **Lowest**. Personal sites and forums can use aliases; YMYL and commercial sites cannot.

## Code-review checks

### Homepage discoverability
- [ ] Every page's logo / brand mark links back to `/`
- [ ] Stripping path from URL (`/article` → `/`) lands on a real homepage, not a 404

### Who runs the site
- [ ] `/about` page exists and is linked from header or footer of every page
- [ ] `/about` names the company / individual, location, when founded, what they do
- [ ] Footer shows company legal name, address (or country if remote), and registration number if applicable
- [ ] Privacy policy and terms of service are linked from the footer of every page

### Who wrote each page (content attribution)
- [ ] Every article/post has a byline linking to an author page (`/authors/<slug>` or similar)
- [ ] Author pages list credentials, bio, photo, social/contact links, list of other articles
- [ ] No "ghost" authors — every byline maps to a real, lookup-able person
- [ ] User-generated content (forums, reviews, comments) tags each post with a username and profile link

### How to contact
- [ ] `/contact` page exists and is linked from footer
- [ ] Contact page has at least: working email, contact form, and (for commerce) phone + physical address
- [ ] For e-commerce: payment / returns / shipping policy pages are linked from footer **and** from cart/checkout
- [ ] For YMYL: physical address visible (not just a PO box for medical/financial/legal)
- [ ] Live chat / support widget actually works (not a marketing-only deflection)

## Red flags (HIGH severity)

- No `/about` page, or `/about` is generic marketing fluff with no entity name
- E-commerce site with no physical address, no returns policy, or contact = form only
- Author bylines that link nowhere, or to a `/author/admin` style stub
- "Contact us" page that's just a single web form with no email or phone
- Mismatched entity names across pages (footer says one company, About says another)
- Site collecting payments or personal data with no privacy policy

## Anchor quote

> "Every page belongs to a website, and it should be clear: Who is responsible for the website. Who created the content on the page you are evaluating." (§2.5.2)
> "YMYL pages or websites that handle sensitive data with absolutely no information about the website or content creator should be rated Lowest." (§4.5.1)
