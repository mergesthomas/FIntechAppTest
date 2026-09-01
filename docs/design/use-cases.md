# Use Cases catalog

Status: **proposal — do not implement until a feature below is explicitly approved**  
Branch: `feature/use-cases`  
Source: local reference screenshots (`screenshots/`, gitignored). The shipped product drops Nexo branding, the NEXO token, and futures.

This is the product map. Features are grouped by product area. Each feature lists screens, flows, Domain Use Cases, and gates.

No Bloc, UI, or `lib/features/` code until you approve **one** feature by name.

Legal, fee, APY, cashback, LTV, and rail copy is **transcribed from screenshots** as placeholders. Human / compliance review before any user-facing string ships.

---

## Shared contracts (every money-moving feature)

These are not a feature. They apply wherever a submit moves money or changes credit.

| Rule | Contract |
|---|---|
| Money | Domain `Money` (decimal + currency). Never `double` for balances, prices, amounts, rates, fees. |
| Session | Use Case refuses if session is missing or expired. |
| Eligibility | Trade submits require KYC known + approved. Unknown or failed → do not open submit. |
| Step-up | Money-moving submits require PIN / biometric / re-auth when the product requires it. |
| Idempotency | Every submit carries client `requestId`, minted when the intent is formed (preview), not at tap time. Retries reuse the same id; the Cubit ignores a second confirm while in flight. |
| Settlement | After submit: `inFlight` → `confirmed` / `failed` / `unknown`. HTTP 200 is not settled. |
| Quotes | Trade quotes must be `live`. `stale` or `disconnected` → Use Case rejects submit. |
| Local-first | No backend. Emulate features on a local ledger. Fixture prices are not `live`. Trading waits for a remote price feed. |
| Logging | Breadcrumb `requestId` + settlement only. Never log balances, tokens, addresses, PANs, IBANs, PII. |

Shared Use Cases (implemented in `lib/core/` only after the first approved feature needs them):

- `RequireSession`
- `GetEligibility` — KYC + region + product flag → `unknown` / `approved` / `denied`
- `RequireLiveQuote`
- `RequireStepUp`

---

## App map (from screens)

```text
Unauthenticated
├── Onboarding carousel
├── Log in / Sign up          [screens missing]
└── Verify SMS → Create PIN → Confirm PIN → Enable FaceID

Authenticated shell (tabs)
├── Dashboard
├── Explore
├── Card
└── Exchange (Swap)

Profile / Products / Security & Settings / Inbox / News
  (reached from avatar, products grid, gift, bell)
```

---

## Feature index

| # | Feature | Area | Money-moving | Shots | Ready to approve? |
|---|---|---|---|---|---|
| 1 | `auth` | Access | no (except later KYC) | onboarding, verify_sms, PIN, FaceID | yes (login/signup screens missing) |
| 2 | `home` | Shell | no (read + navigate) | dashboard | yes |
| 3 | `profile` | Account | no | profile | yes |
| 4 | `products` | Catalog | no | products | yes |
| 5 | `security_settings` | Account | close-account is sensitive | security, settings, documents | yes |
| 6 | `inbox` | Activity | no | inbox | yes |
| 7 | `news` | Content | no | news | yes |
| 8 | `explore` | Markets | no | explore, explore_assets | yes |
| 9 | `funding` | Deposit / buy | — | — | **dropped** |
| 10 | `borrow` | Credit | — | — | **dropped** |
| 11 | `earn` | Savings | — | — | **dropped** |
| 12 | `card` | Spend | **yes** | nexo_card_product, card_frozen | frozen + marketing; active card missing |
| 13 | `swap` | Trade | **yes** | swap, swap_asset_picker | yes (preview/result missing — improvise) |
| 14 | `orders` | Trade history | no (read) | order_history | yes |
| 15 | `futures` | Trade | — | — | **dropped** |
| 16 | `wallet` | Portfolio | no | — | **blocked** (Wallet CTA on dashboard; no screens) |
| 17 | `order_book` | Markets | no (read + Limit draft) | none | **Use Cases approved** on `feature/order-book` — see [`order-book.md`](order-book.md) |

Approve **one** row. Approving one does not approve the others.

---

## 1. `auth`

Status: **implemented** on `feature/auth` (local emulator). Login/signup are phone-only. SMS code `123456` (dev flavor).

### Screens

| Screen | Folder | Have |
|---|---|---|
| Onboarding carousel (5 slides) | `onboarding` | yes |
| Verify with SMS | `verify_sms` | yes |
| Create PIN | `create_pin` | yes |
| Confirm PIN | `confirm_pin` | yes |
| Enable FaceID sheet | `enable_faceid` | yes |
| Log in | `login` | **missing** |
| Sign up | `sign_up` | **missing** |
| KYC | `kyc` | **missing** |

Onboarding slides (copy is marketing placeholder):

1. Grow and preserve your wealth — Log in / Sign up
2. Reach goals with compound interest — up to 15% p.a., $5,000 minimum (placeholder)
3. Exchange over 100 digital assets
4. Open a Credit Line, from 1.9% p.a. — BTC/ETH 50% LTV, NEXO 15% (placeholder)
5. Spend with the Nexo Card — Credit vs Debit mode

SMS: 6-digit code, resend timer, Cancel / Paste, “Unable to verify?”  
PIN: 4 digits, confirm, Reset on confirm screen  
FaceID: Enable / Skip after PIN confirm

### Flow

```text
Onboarding → Log in | Sign up
  → Verify SMS
  → Create PIN → Confirm PIN
  → Enable FaceID | Skip
  → Dashboard
```

### Use Cases

- `GetOnboardingSlides` — server/config copy + pagination; do not hard-code rates
- `GetPreferredLocale` / `SetPreferredLocale` — globe on onboarding
- `StartLogin` / `StartSignUp` — blocked until screens exist; do not invent fields
- `VerifySmsCode` — 6 digits; resend cooldown
- `CreatePin` — 4 digits; never persist PIN in prefs or logs
- `ConfirmPin` — must match; Reset restarts create
- `EnableBiometric` / `SkipBiometric`
- `RequireSession` — after success

### Gates

Session tokens in secure storage only. PIN and biometric secrets never in widgets or logs.

---

## 2. `home`

Status: **implemented** (local fixtures, freshness `stale`).

Dashboard is the authenticated landing tab. Not a money submit.

### Screens

| Screen | Folder | Have |
|---|---|---|
| Dashboard (portfolio + hubs) | `dashboard` | yes (2) |

Visible data:

- Header: avatar initials, logo, gift, bell
- Portfolio: total **$35,862.41**, **−4.92% / 1W**, line chart, **Wallet >**
- Banner: EURx below zero — Learn more / dismiss
- Watchlist: BTC, DOGE, PEPE, BONK, ETH — price + 24h + sparkline
- Promo cards + News teaser
- Tabs: Dashboard, Explore, Card, Exchange

### Use Cases

- `GetDashboardOverview` — net worth as `Money`, period change, chart series + freshness
- `GetWatchlist` — assets + live/stale/disconnected prices
- `GetDashboardAlerts` — e.g. negative FIATx; dismiss is local + server ack
- `GetDashboardPromos` — server cards only
- `GetNewsPreview`

Navigation only (no Domain submit): Wallet, Send crypto, tabs, avatar, gift, bell.

### Gates

Session required. Show last cached portfolio as **stale**, never as live.

---

## 3. `profile`

### Screens

| Screen | Folder | Have |
|---|---|---|
| Profile (scrolled) | `profile` | yes (2) |

Visible: greeting, Security & Settings, Loyalty **Platinum**, Private teaser, Rewards Hub, Refer a friend, product tiles (Card / Swap / Recurring Buy / More), Contact us, Help Center, How it works, Share feedback, app version **7.9.1**, Terms, About.

### Use Cases

- `GetProfileOverview` — display name, loyalty tier, private flag
- `GetRewardsTeasers`
- `GetProfileProductShortcuts`
- `GetAppVersionInfo`
- `GetLegalLinks` — Terms / About URLs from config

---

## 4. `products`

Catalog of product entry points (not a submit).

### Screens

| Screen | Folder | Have |
|---|---|---|
| Products grid | `products` | yes |

Groups: **Spend** (Card) · **Trade** (Swap) · **Information** (Explore, News).

### Use Cases

- `GetProductCatalog` — grouped tiles + eligibility badges; hide or disable by `GetEligibility`

---

## 5. `security_settings`

Three tabs on one surface.

### Screens

| Screen | Folder | Have |
|---|---|---|
| Security | `security` | yes |
| Settings | `settings` | yes |
| Documents | `documents` | yes |

**Security:** Login information, Passkeys (Recommended), PIN, Address book (Whitelisting off), 2FA Enabled, Anti-phishing Enabled, Biometric toggle ON, Last logins, Close account, Log out.

**Settings:** Identity, Payment methods, Notifications; Display currency USD, Language English, Appearance System.

**Documents:** Tax report with Koinly; generate Account confirmation, Card confirmation, Account balance, Loan statement, Savings statement.

### Use Cases

- `GetSecuritySettings`
- `SetBiometricEnabled`
- `GetAddressBookPolicy` / `SetAddressWhitelisting`
- `GetTwoFactorStatus`
- `GetAntiPhishingStatus`
- `GetLastLogins`
- `Logout`
- `StartCloseAccount` — step-up; settlement
- `GetAppPreferences` / `SetDisplayCurrency` / `SetLanguage` / `SetAppearance`
- `GetPaymentMethods` — **dropped** with `funding`
- `RequestAccountDocument` — kind + `requestId`; document job `inFlight` → ready / failed / unknown
- `GetTaxReportLink`

Close account and document generation are sensitive. Step-up on close. Never log document contents.

---

## 6. `inbox`

### Screens

| Screen | Folder | Have |
|---|---|---|
| Inbox (interest earned) | `inbox` | yes |

Grouped by date. Rows: Interest Earned, amount as `Money` (NEXO + USD). Chevron → transaction detail (**missing**).

### Use Cases

- `GetInboxItems` — paged, typed events
- `GetInboxItemDetail` — blocked until `transaction_detail` exists

---

## 7. `news`

### Screens

| Screen | Folder | Have |
|---|---|---|
| News list | `news` | yes |

Source, headline, age, category, thumbnail. Header: avatar, logo, gift, bell. Tab bar present.

### Use Cases

- `GetNewsFeed` — paged
- `GetNewsArticle` — open article (web or in-app; screen not in dump)

---

## 8. `explore`

### Screens

| Screen | Folder | Have |
|---|---|---|
| Explore discovery | `explore` | yes (3) |
| Explore assets + products | `explore_assets` | yes |

Visible: For-you promo, Top gainers / losers, product tile row, All assets / News tabs, filters (All / Top gainers / losers / New), search.

Prices and APY from server. Freshness on every tick.

### Use Cases

- `GetExploreFeed` — sections from server (do not hard-code gainers)
- `GetMarketAssets` — filter + sort; price + 24h + sparkline + freshness
- `SearchExploreAssets`

No trade submit on this feature. Tapping an asset opens market detail.

---

## 9. `funding`

Status: **dropped**. Deposit / buy / add-funds are out of product scope. Do not implement.

---

## 10. `borrow`

Status: **dropped**. Credit / loans are out of product scope. Do not implement.

---

## 11. `earn`

Status: **dropped**. Savings / earn-in-token are out of product scope. Do not implement.

---

## 12. `card`

### Screens

| Screen | Folder | Have |
|---|---|---|
| Card product (marketing + spend calc) | `nexo_card_product` | yes |
| Card frozen (negative EURx) | `card_frozen` | yes (2) |
| Card active / transactions | `card_active`, `card_transactions` | **missing** |

Frozen: EURx **−1.16** (≈ **$−1.35**). Copy: swap to restore. CTA **Restore balance** → `swap`.

### Use Cases

- `GetCardStatus` — active / frozen / none
- `GetCardBalances` — FIATx as `Money` (negative is valid)
- `GetCardSpendQuote` — EUR spend vs collateral + LTV + freshness
- `RestoreCardBalance` — routes to `swap`; does not invent a rail
- `GetCard` — blocked until active-card screens exist
- `FreezeCard` / `UnfreezeCard` — unfreeze only if balance eligible

Frozen is a first-class state. Do not treat it as a generic error.

---

## 13. `swap`

Exchange tab.

### Screens

| Screen | Folder | Have |
|---|---|---|
| Swap ticket | `swap` | yes |
| Swap asset picker | `swap_asset_picker` | yes |
| Preview / result | `swap_preview`, `swap_result` | **missing — improvise** |

Ticket: Instant / Limit / Trigger · From USDC → To DOGE · live rate · Preview order.  
Savings / Credit hidden (savings book). Limit price and Trigger TP/SL as `Money`.  
Picker: Pay with | Receive · supported assets with balances.

Send crypto is a dashboard CTA with **no** screens (`send_crypto` empty). Out of scope here.

### Use Cases

- `SearchSwapAssets`
- `GetSwapOrderTypes` — Instant, Limit, Trigger
- `WatchSwapRate` — live `from`/`to` rate + freshness
- `GetSwapQuote` — from/to `Money`, order type, optional limit / TP / SL, `quoteId`, freshness
- `SubmitSwap` — `requestId` + `quoteId` + step-up. Refuse stale. Instant fills; Limit/Trigger hold `from` until live price hits
- `CancelOrder` — existing; releases a resting hold

---

## 14. `orders`

### Screens

| Screen | Folder | Have |
|---|---|---|
| Order History | `order_history` | yes |

Tabs: Trigger Orders | Limit Orders. Past orders: pair, SELL, CANCELED, amount, Credit Wallet, TP / SL, realized P/L dash.

### Use Cases

- `GetOrderHistory` — tab + wallet filter
- `GetOrderDetail`
- `CancelOrder` — `requestId` + settlement if a live order can be canceled (no live-order screen yet)

---

## 15. `futures`

**Dropped.** Perpetuals and the futures ticket are out of scope.

---

## 16. `wallet`

Dashboard **Wallet >** has no screens (`wallet`, `asset_detail`, `transaction_detail` empty).

Do not invent a portfolio feature. When shots arrive: balances, asset detail, transaction detail.

---

## 17. `order_book`

Lives in `features/market` (same `MarketPage`). Design: [`order-book.md`](order-book.md).

Display-only depth + a Limit **draft** for existing Swap. Not money-moving. No new submit.

### Screens

| Screen | Folder | Have |
|---|---|---|
| Market detail + book | `market` | charts + book (Phase 1 UI) |

### Flow

```text
Market detail
  → GetOrderBook + WatchOrderBook
  → tap level → SelectOrderBookLevel
  → Swap Limit (existing GetSwapQuote → preview → step-up → SubmitSwap)
```

### Use Cases

- `GetOrderBook` — session; depth 1–20; last cache `stale` / `disconnected`; fixture is never `live`
- `WatchOrderBook` — session on each emit; same freshness contract as ticks
- `SelectOrderBookLevel` — session; level must be on the book; `disconnected` refuses; `stale` returns a draft with the stale flag. No KYC, step-up, ledger, or `quoteId`

Reconnect / live Binance depth are Data (Phases 2–3). `SubmitOrderFromBook` is forbidden.

---

## Cross-feature navigation (not extra features)

| From | To |
|---|---|
| Shell Exchange tab / Send | `swap` / send (blocked) |
| Dashboard Wallet | `wallet` (blocked) |
| Card Restore balance | `swap` |
| Frozen card overflow | `swap` |
| Products tiles | matching feature |
| Profile Security & Settings | `security_settings` |

---

## Out of scope until screens exist

Do not invent success UI or fields for: login/signup form, KYC wizard, wallet/asset/transaction detail, send crypto, buy/swap preview+result (structure may be improvised as review → confirm → confirmed/failed/unknown), link-card form / 3DS, recurring schedule editor, ACH instructions, restore-balance dedicated flow, loan detail, repay, notification center, empty/error gallery, active card + transactions.

Improvise only the **standard money-moving chrome** (review → confirm → confirmed / failed / unknown). Do not invent fees, APY, LTV tables, or legal body.

---

## Approval

Reply with **one**:

- `Approve <feature> Use Cases` — Domain + tests only, on `feature/<feature>`
- `Approve <feature> including UI` — after Domain
- `Revise` — what to change in this catalog

I will not write Bloc or pages until you approve a single feature from the index.
