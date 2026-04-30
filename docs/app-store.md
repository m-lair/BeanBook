# BeanBook — App Store Connect copy

Source of truth for App Store Connect listing fields. Voice rules in [`branding.md`](branding.md) override anything that drifts here.

Character limits are the App Store Connect hard caps. Counts after each draft are the *current* length — verify before pasting.

---

## App Information

| Field | Value |
|---|---|
| **App name** (30) | `BeanBook: Coffee Logbook` (24) |
| **Subtitle** (30) | `Quiet logbook for home coffee` (30) |
| **Bundle ID** | `duhmarcus.BeanBook` |
| **Primary category** | Food & Drink |
| **Secondary category** | Lifestyle |
| **Age rating** | 4+ |
| **Content rights** | Does not contain third-party content |

---

## Promotional Text (170)

Rotates without re-review. Use it for what's *new* this build, not evergreen marketing.

> Tap the timer to dial in any duration. Cleaner step headers, clearer actions. Same quiet logbook — now a little easier to live with.

(192) — **trim before paste:**

> Tap the timer to dial in any duration. Cleaner step headers, clearer actions. Still a quiet logbook for home coffee.

(135) ✓

---

## Description (4000)

```
A quiet logbook for the coffee you brew at home.

Log a bag. Log a shot. Repeat what worked. That's the product.

BeanBook is for the person who pulls one or two shots in the morning, mostly the same coffee for a week or two, and occasionally dials in something new. No followers. No feeds. No streaks nagging you to log. No score telling you whether your coffee was "good."

— THE LOGBOOK —

Every brew captures what actually matters: method, dose, yield, time, grind, and a one-to-five rating. A single notes field if you want to remember how it tasted. Nothing else.

Espresso, Pour Over, AeroPress, French Press, Moka Pot, Cold Brew. Each method comes with sensible defaults so you can start logging in seconds, not minutes.

— BAGS —

Track the bag you're working through: roaster, origin, roast level, roast date. Pin the bag you're dialing in this week and it'll lead the list. When the bag's gone, archive it — your brew history stays.

— RECIPES —

Save a brew you liked as a recipe and re-launch it any time. The new-brew sheet pre-fills with the recipe's values; if you tweak the dose or grind, a small "was 18 g" hint reminds you what you changed.

— THE TIMER —

Built for espresso. Tap the time to set any duration to the second. Plus / minus thirty for quick nudges. Counts down or counts up — your call. Auto-stops when the shot's done.

— OWNERSHIP —

Your data lives on your device. No account required. Export anytime.

— BEANBOOK PRO —

A one-time purchase. Pay once, yours forever. No subscription. Ever.

• Unlimited bags, brews, and saved recipes
• Two extra palettes — Ocean and Mocha
• Family Sharing supported
• Future Pro features included with the purchase you've already made

The free tier is real and generous. Pro lifts the quotas and unlocks themes; it doesn't paywall the logbook.

— WHAT BEANBOOK IS NOT —

Not a social app. Not a streak app. Not a scoring algorithm. Not a subscription. Not a journal-blog hybrid with rich text and tags. We say no to those on purpose.

Light mode only — the paper-like, editorial feel is half the point.
```

(~1,750 chars) ✓ well under 4,000

---

## Keywords (100, comma-separated, no spaces after commas)

```
espresso,coffee,logbook,brew,journal,beans,timer,recipe,pourover,aeropress,ratio,dose,yield,grind
```

(96) ✓

Notes:
- "coffee" is the highest-volume term that's still on-brand.
- "pourover" (no space) preserves the keyword while also matching "pour over" intent.
- Avoid: "tracker" (subscription-app vibe), "social" (we are not), "stats" (ship before we keyword it).

---

## What's New (4000) — current build

Lead with the most user-visible change. Brand voice: no exclamation marks, no "we're excited to," no version numbers in prose.

```
The new-brew sheet got quieter and quicker.

• Tap the timer numeral to set any duration to the second — no more dancing on the ±30s chips to land on 0:31.
• The step header now scrolls with the content, so the big numbers don't bleed into the title.
• "Start timer" reads as a tool, not a step advancer. "Next" moves you forward; the timer's start sits beside it without competing.

Small fixes throughout the brew flow.
```

---

## URLs

| Field | URL |
|---|---|
| **Marketing URL** | `https://beanbook.app` *(verify before submit)* |
| **Support URL** | `https://beanbook.app/support` *(verify before submit)* |
| **Privacy Policy URL** | `https://beanbook.app/privacy` *(required — verify before submit)* |

---

## App Privacy

BeanBook does not collect personal data. The iOS target ships without any analytics or third-party SDKs at the time of writing. Cloud Functions exist in `functions/` but are not wired to the client.

Answer the App Privacy questionnaire as **"Data Not Collected"** unless / until that changes. If a future build adds analytics or sync, this section needs to be revised *before* submission, and the privacy policy must be updated first.

---

## In-App Purchases

| Display Name | Description (45) | Promotional |
|---|---|---|
| **BeanBook Pro** | `One-time unlock. Yours forever. No subscription.` (49 — **trim**) | Lead with "one-time," pair price with "once," mention Family Sharing. |

Trim suggestion: `One-time unlock. Yours forever.` (31) ✓

### Review notes for the IAP

Paste into the IAP's "Review Notes" field in App Store Connect. Reviewers use this to locate the paywall and verify the purchase flow — be specific.

```
BeanBook Pro is a single non-consumable in-app purchase. There is no subscription, no auto-renewal, and no trial. Paying once unlocks the Pro features for the buyer's Apple ID forever, and Family Sharing is enabled so up to five family members get access from the same purchase.

WHAT PRO UNLOCKS
- Removes the free-tier limits on the number of bags, brews, and saved recipes a user can store locally on device.
- Unlocks two additional theme palettes (Ocean, Mocha) in addition to the default Forest palette, which remains free.

Pro does NOT gate the core logbook flow. Free users can log brews, track bags, save recipes, browse the curated bean catalog, and use the timer. Pro only lifts quantity limits and adds two themes. The free tier is fully usable.

WHERE TO FIND THE PAYWALL
1. Launch the app and complete the brief two-step onboarding (no account required).
2. The paywall appears automatically when a free user crosses a quota — for example, after creating the free-tier limit of bags and tapping the "+" to add another.
3. The paywall is also reachable from Settings → "Unlock BeanBook Pro," which opens the same sheet on demand.

HOW TO TEST THE PURCHASE
- The product ID is BeanBook.Pro (non-consumable, $9.99 USD, Family Sharing on).
- Use a sandbox tester account. Tap "Unlock Pro · $9.99 once" on the paywall to trigger the StoreKit purchase flow.
- After a successful purchase the paywall dismisses and Pro features become available immediately.

RESTORE PURCHASES
- "Restore Purchases" is available in two places: at the bottom of the paywall sheet, and in Settings below the Pro row. Tapping it calls AppStore.sync() and re-validates entitlements via Transaction.currentEntitlements.

ACCOUNT / SIGN-IN
- BeanBook does not require an account to use any feature, free or Pro. Entitlement is tied to the Apple ID's StoreKit transaction history; there is no separate login.

DATA & PRIVACY
- All user data is stored locally via SwiftData. The app does not collect personal data and ships without analytics or third-party SDKs. App Privacy is answered as "Data Not Collected."
```

---

## Screenshot copy (overlay text)

Six 6.7" screens, sentence-case, serif headline + light body. Don't restate what's visible on screen.

1. **Today's shot.** — *List view, recent brews.*
2. **Pull the shot.** — *Step 2, timer running.*
3. **A logbook, not a feed.** — *Bag detail, hairline rules.*
4. **Save what worked.** — *Recipes list, single recipe pinned.*
5. **One-time purchase.** — *Pro sheet, Family Sharing line visible.*
6. **No streaks. No social. No scoring algorithm.** — *Empty-state hero shot.*

Per `branding.md`: no exclamation marks, no celebratory copy, no stat callouts.

---

## Submission checklist

- [ ] App name and subtitle under their character limits when pasted into ASC (it counts differently than your editor).
- [ ] Description has no smart quotes from copy/paste — ASC re-renders them oddly on some pages.
- [ ] Privacy policy URL resolves and matches the App Privacy answers.
- [ ] Keywords are comma-separated, **no spaces after commas**, under 100 chars.
- [ ] Screenshots are 6.7" iPhone (iPhone 16 Pro Max frame); 5.5" set is no longer required for new submissions, skip.
- [ ] What's New is build-specific, not evergreen.
- [ ] No mention of subscription, trial, or pricing pressure anywhere — the Pro line is "one-time, yours forever."
