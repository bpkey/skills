# Examples — tiny GOOD/BAD pairs

Worked pairs an agent can pattern-match against. Each is intentionally short. Examples use
TypeScript / Next.js (the dominant stack) but the principle in each is language-agnostic — read the
**principle line**, not the syntax.

---

## 1. Boundary violation → flat, greppable, one-way import
*Principle: dependency direction + greppable naming (P3, P10).*

```tsx
// BAD — reaches into a sibling feature's internals; deep relative climb; "utils" is grep noise
import { hashPassword } from "../../settings/utils";
import { db } from "../../../db";
```

```tsx
// GOOD — shared concern lives in lib; flat alias import; one obvious place
import { hashPassword } from "@/lib/auth";
import { getUser } from "@/lib/db/users";
// Check: an agent searching "where is password hashing" finds @/lib/auth by name alone.
```

---

## 2. Speculative layering → concrete by default
*Principle: YAGNI + minimize indirection + reject the cargo cult (P8, P12, P16).*

```
// BAD — 3 files, 1 caller, no second implementation anywhere
src/services/UserServiceImpl.ts  implements IUserService
src/services/IUserService.ts
src/services/UserServiceFactory.ts
```

```ts
// GOOD — plain functions; introduce an interface only when a real second implementation appears
// src/lib/users.ts
export async function getUser(id: UserId): Promise<User | null> { ... }
export async function createUser(input: NewUser): Promise<User> { ... }
```

---

## 3. Runtime-resolved dispatch → static, traceable dispatch
*Principle: explicit over magic + static traceability (P4, P13).*

```ts
// BAD — handler chosen by string lookup at runtime; an agent can't follow it by reading,
// and grep for the handler name finds nothing
const handlers: Record<string, Handler> = { ...registeredElsewhere };
return handlers[req.type](req);
```

```ts
// GOOD — explicit switch; exhaustiveness enforced; every branch reachable by reading
switch (req.type) {
  case "create": return handleCreate(req);
  case "cancel": return handleCancel(req);
  default: return assertNever(req.type); // compile error if a new type is unhandled
}
```

---

## 4. Comment noise → invariant in a header
*Principle: comment the why/invariant, not the what (P-divergence: comment density).*

```ts
// BAD — narrates the code; rots out of sync; zero signal
// loop over the items and add up the totals
let total = 0;
for (const item of items) total += item.price;
```

```ts
/**
 * GOOD — the surprise is stated where it matters.
 * Invariant: prices are minor-unit integers (cents); never sum pre-rounded floats here.
 */
const total = items.reduce((sum, item) => sum + item.priceCents, 0);
```

---

## 5. Type-checker silencing → fix the contract
*Principle: types as compressed specs; no casts to quiet the compiler (P5).*

```ts
// BAD — cast hides a real shape mismatch; everything downstream now lies about its type
const user = (await res.json()) as User;
```

```ts
// GOOD — validate the external input at the boundary; the type past it is earned, not asserted
const user = UserSchema.parse(await res.json()); // throws on shape mismatch; User is now real
```

---

## 6. Layer-folders → vertical slice
*Principle: organize by feature/concern; co-locate co-change (P2).*

```
// BAD — one feature smeared across four trees; deleting "consent" touches all of them
controllers/consentController.ts
services/consentService.ts
models/consent.ts
tests/consentService.test.ts
```

```
// GOOD — the feature is one subtree; delete it by deleting the folder + its registration
lib/consent/
  index.ts        // public entrypoint
  resolve.ts      // logic
  types.ts        // contracts
  resolve.test.ts // co-located test
```
