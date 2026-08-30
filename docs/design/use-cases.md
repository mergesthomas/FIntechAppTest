# Use Cases catalog

Status: **proposal — do not implement until a feature below is explicitly approved**  
Branch: `feature/use-cases`  
Source: local Nexo screenshots (`screenshots/`, gitignored)

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
| Eligibility | Earn / borrow / trade / funding submits require KYC known + approved. Unknown or failed → do not open submit. |
| Step-up | Money-moving submits require PIN / biometric / re-auth when the product requires it. |
| Idempotency | Every submit carries client `requestId`. Retries reuse the same id. |
| Settlement | After submit: `inFlight` → `confirmed` / `failed` / `unknown`. HTTP 200 is not settled. |
| Quotes | Trade / buy / borrow-size quotes must be `live`. `stale` or `disconnected` → Use Case rejects submit. |
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
├── Futures
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
| 9 | `funding` | Deposit / buy | **yes** | add_funds, bank, receive, buy | yes (preview/result missing — improvise) |
| 10 | `borrow` | Credit | **yes** | all_loans, credit_line, 0%, booster, collateral, settings | yes (detail/repay missing — improvise) |
| 11 | `earn` | Savings | **yes** | savings_hub | hub only (product flows missing) |
| 12 | `card` | Spend | **yes** | nexo_card_product, card_frozen | frozen + marketing; active card missing |
| 13 | `swap` | Trade | **yes** | swap, swap_asset_picker | yes (preview/result missing — improvise) |
| 14 | `orders` | Trade history | no (read) | order_history | yes |
| 15 | `futures` | Trade | **yes** | futures, position_details | yes (chart/TP-SL/close confirm missing — improvise) |
| 16 | `wallet` | Portfolio | no | — | **blocked** (Wallet CTA on dashboard; no screens) |

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
- Credit Hub: **$0.00** available to borrow
- Savings Hub: **$2,479.74** interest earned
- Banner: EURx below zero — Learn more / dismiss
- Promo: Zero-interest Credit
- Watchlist: BTC, DOGE, PEPE, BONK, NEXO — price + 24h + sparkline
- Promo cards + News teaser
- CTAs: **Send crypto** | **Add funds**
- Tabs: Dashboard, Explore, Futures, Card, Exchange

### Use Cases

- `GetDashboardOverview` — net worth as `Money`, period change, chart series + freshness
- `GetCreditHubTeaser` — available to borrow
- `GetSavingsHubTeaser` — interest earned
- `GetWatchlist` — assets + live/stale/disconnected prices
- `GetDashboardAlerts` — e.g. negative FIATx; dismiss is local + server ack
- `GetDashboardPromos` — server cards only
- `GetNewsPreview`

Navigation only (no Domain submit): Wallet, Send crypto, Add funds, Credit Hub, Savings Hub, tabs, avatar, gift, bell.

### Gates

Session required. Show last cached portfolio as **stale**, never as live.

---

## 3. `profile`

### Screens

| Screen | Folder | Have |
|---|---|---|
| Profile (scrolled) | `profile` | yes (2) |

Visible: greeting, Security & Settings, Loyalty **Platinum**, Nexo Private teaser, Rewards Hub, Refer a friend, product tiles (Credit / Savings / Futures / Card / Recurring Buy / More), Contact us, Help Center, How it works, Share feedback, app version **7.9.1**, Terms, About.

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

Groups: **Earn** (Savings Hub, Fixed-term, Wealth Vaults) · **Borrow & spend** (Credit Hub, Card, Zero-interest) · **Trade** (Swap, Limit Order, Futures, Booster, Dual Investment, Recurring Buy, Crypto Baskets) · **Information** (Explore, News).

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

**Settings:** Identity, Savings settings, Credit Line settings, Futures settings, Payment methods, Notifications; Display currency USD, Language English, Appearance System.

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
- `GetPaymentMethods` — shared with funding/buy
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

Visible: For-you promo, Top gainers / losers, Top earning assets (APY teasers), Opportunity cards (Fixed Term, Earn in NEXO), Trending perpetuals (up to 100x), Quick wins, product tile row, All assets / News tabs, filters (All / Top gainers / losers / New), search.

Prices and APY from server. Freshness on every tick.

### Use Cases

- `GetExploreFeed` — sections from server (do not hard-code gainers)
- `GetMarketAssets` — filter + sort; price + 24h + sparkline + freshness
- `SearchExploreAssets`
- `GetTopEarningAssets` — APY from server
- `GetTrendingPerpetuals`
- `GetExploreOpportunities`

No trade submit on this feature. Tapping a pair opens `futures` or asset detail (**missing**).

---

## 9. `funding`

Dashboard **Add funds** hub. Three rails. Not the only product — one money-moving slice.

### Screens

| Screen | Folder | Have |
|---|---|---|
| Add funds hub | `add_funds` | yes |
| Select FIATx | `select_asset_fiatx` | yes |
| Select bank method | `select_bank_method` | yes |
| Open personal USD account | `open_usd_account` | yes |
| Receive FIATx SEPA / SWIFT | `receive_fiat` | yes |
| Select asset to receive | `select_asset_receive` | yes |
| Receive crypto | `receive_crypto` | yes |
| Select asset to buy | `select_asset_buy` | yes |
| Buy amount + keypad | `buy_crypto` | yes |
| Payment methods sheet | `payment_methods` | yes |
| Buy preview / result | `buy_preview`, `buy_result` | **missing — improvise** |
| Link card, frequency, restore, ACH | those folders | **missing — improvise later** |

Hub rows: Bank transfers (USDx / EURx / GBPx) · Add crypto · Buy crypto (Instant / Apple Pay / Visa / Mastercard).

```text
Add funds
├── Bank transfers → FIATx → (USDx: open USD account | ACH/SWIFT) | (EURx/GBPx: SEPA/SWIFT details)
├── Add crypto → select asset → address + QR + network
└── Buy crypto → select asset → amount → payment method → [preview] → [result]
```

### Use Cases

**Hub**

- `GetFundingMethods` — rows the user is allowed to see

**Bank**

- `GetFiatxAssets` — fee teasers from server
- `GetBankRails` — ACH / SEPA / SWIFT by asset + region
- `GetFiatAccountStatus` — none / inFlight / confirmed / failed / unknown
- `AcceptFiatAccountTerms` — consent only; does not create
- `CreatePersonalUsdAccount` — `requestId` + step-up + KYC; settlement
- `GetFiatReceiveDetails` — beneficiary fields; copy/share is presentation
- `GetBankTransferFeeSchedule` — server fees (screenshot placeholders: SEPA free above €100 else €5; SWIFT EURx €25; USDx free SWIFT above $5,000; GBPx free above £100)

**Receive crypto**

- `GetReceivableAssets` / `SearchReceivableAssets`
- `GetReceiveAddress` — address + QR URI + network. Never log address
- `GetAssetFundingTeasers` — earn / borrow badges from server

**Buy**

- `GetPurchasableAssets` / `SearchPurchasableAssets` — price + 24h + freshness
- `GetBuyQuote` — `Money` in, crypto out, cashback teaser, `quoteId`, freshness
- `GetPaymentMethods` — cards, Apple Pay if entitled, link-card, empty FIATx/stables
- `GetPurchaseFrequencies`
- `StartLinkCard` — KYC; processor session, not PAN
- `GetEmptyBalances` — Restore EURx is a separate path
- `SubmitBuyCrypto` — `requestId` + `quoteId` + method + `Money` + frequency + step-up. Refuse stale quote. Return settlement

Inbound bank and on-chain: showing details ≠ credited. Deposit stays `inFlight` until ledger posts.

---

## 10. `borrow`

Credit catalog + outstanding + product marketing + collateral + optimization.

### Screens

| Screen | Folder | Have |
|---|---|---|
| All loans (available / outstanding) | `all_loans` | yes (3) |
| Collateral assets | `collateral_assets` | yes |
| Credit Line optimization | `credit_line_optimization` | yes (2) |
| Classic Credit Line | `credit_line` | yes (3) |
| Zero-interest Credit | `zero_interest_credit` | yes (2) |
| Booster | `booster` | yes |
| Nexo Card product (borrow teaser) | `nexo_card_product` | yes |
| Loan detail / borrow review / repay | those folders | **missing — improvise** |

All loans tabs: Available (max **0.00 xUSD**) · Outstanding (total **14,694.96 xUSD**).  
Products: Classic, Card, Zero-interest (Active), Booster (Available).  
Overflow: Check LTV → collateral · Credit line settings → optimization.

Classic ticket: available 0.00, outstanding 14,625.44 GOOD, min borrow USDC 50, collateral BTC 50% LTV.  
0% ticket: USDC amount, collateral chips BTC/ETH/SOL/XRP, 50% LTV.  
Card product: spend in EUR, collateral BTC 50% LTV, outstanding 69.52 GOOD.  
Booster: 100+ collateral, from 1.9%, up to 3x; Boost / Open Booster Credit Line.

Optimization: per Classic | Card. Flags: automatic collateral transfer; Fixed-term unlock and Low-interest borrowing **require** automatic transfer.

### Use Cases

- `GetBorrowEligibility`
- `GetAllLoansOverview` — available vs outstanding, `Money` in xUSD
- `GetLoanProducts` — catalog metadata from server
- `GetCreditLineOverview` — available, outstanding, health badge
- `GetBorrowQuote` — live LTV + `Money` + `quoteId` + freshness
- `SubmitBorrow` — `requestId` + `quoteId` + product + `Money` + step-up
- `SubmitRepay` — `requestId` + loan id + `Money` + step-up
- `GetCollateralAssets` / `GetCollateralFilter` / `GetAssetLtvSchedule`
- `GetCreditLineOptimization` / `UpdateCreditLineOptimization` — `requestId` + step-up; turning off auto-transfer must clear or refuse dependent flags
- `GetLoanMarketingContent` — benefits / FAQ keys; do not invent body copy

Empty available **0.00** still lists products. Do not hide the catalog.

---

## 11. `earn`

### Screens

| Screen | Folder | Have |
|---|---|---|
| Savings Hub | `savings_hub` | yes (2) |

Interest earned **$2,477.10**. Advanced: Dual Investment (up to 117.05% placeholder). Passive: Fixed-term, Wealth Vaults, Recurring buys. Optimize: Earn in NEXO Enabled (+2% placeholder), Stop earning.

Product flows (subscribe, lock, vault, recurring editor) have no screens.

### Use Cases

- `GetSavingsHubOverview` — interest earned as `Money`
- `GetEarnProducts` — dual / fixed-term / vaults / recurring teasers from server
- `GetEarnInNexoPreference` / `SetEarnInNexo` — eligibility + step-up if it changes payout asset
- `StopEarning` — `requestId` + step-up + confirmation (improvise confirm)
- `SubscribeFixedTerm` / `OpenWealthVault` / `CreateRecurringBuy` / `OpenDualInvestment` — **do not implement** until those screens exist

---

## 12. `card`

### Screens

| Screen | Folder | Have |
|---|---|---|
| Card product (marketing + spend calc) | `nexo_card_product` | yes |
| Card frozen (negative EURx) | `card_frozen` | yes (2) |
| Card active / transactions | `card_active`, `card_transactions` | **missing** |

Frozen: EURx **−1.16** (≈ **$−1.35**). Copy: add funds, transfer, or swap. CTA **Restore balance**. Overflow: Swap, OTC Swap, Booster, Dual Investment.

### Use Cases

- `GetCardStatus` — active / frozen / none
- `GetCardBalances` — FIATx as `Money` (negative is valid)
- `GetCardSpendQuote` — EUR spend vs collateral + LTV + freshness
- `RestoreCardBalance` — routes to funding/swap; does not invent a rail
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

Ticket: Savings | Credit wallet · Instant order · From NEXO (balance shown) → To EURx · Preview order.  
Picker: Pay with | Receive · search · supported assets with balances.

Send crypto is a dashboard CTA with **no** screens (`send_crypto` empty). Out of scope here.

### Use Cases

- `GetSwapWallets` — Savings vs Credit
- `GetSwapQuote` — from/to `Money`, `quoteId`, freshness, order type
- `SearchSwapAssets`
- `SubmitSwap` — `requestId` + `quoteId` + wallet + step-up. Refuse stale quote. Settlement
- `GetSwapOrderTypes` — Instant (Limit is a different product on Products grid)

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

### Screens

| Screen | Folder | Have |
|---|---|---|
| Futures ticket + open position | `futures` | yes |
| Position details | `position_details` | yes (3) |
| Chart / preview / TP-SL / close confirm | those folders | **missing — improvise** |

Ticket: BTCUSDT bid/ask, 100x, Long/Short, Market, size BTC↔USDT, % slider, TP/SL checkbox, bonus 21%, available margin **186.25 USDT** (+ add), required margin, margin risk **27.78%**, Preview position. Open: 1000PEPEUSDT LONG 100x.

Details: size, leverage, P/L, entry / mark / liq, locked collateral, maintenance margin, funding + countdown, order id, Set TP/SL, Close position.

### Use Cases

- `GetFuturesInstrument` — pair, bid/ask, leverage options, freshness
- `GetFuturesAccount` — available margin, required, risk, bonus progress
- `GetOpenPositions`
- `GetPositionDetails`
- `GetFuturesQuote` — side + size + leverage + `quoteId` + freshness
- `PreviewFuturesPosition` — same quote, no submit
- `SubmitFuturesOrder` — `requestId` + `quoteId` + step-up. Refuse stale. Settlement
- `SetTakeProfitStopLoss` — `requestId` + live mark
- `ClosePosition` — `requestId` + settlement
- `GetLastTrades`

Do not submit on stale mark/bid-ask. Size and P/L are `Money`, not `double`.

---

## 16. `wallet`

Dashboard **Wallet >** has no screens (`wallet`, `asset_detail`, `transaction_detail` empty).

Do not invent a portfolio feature. When shots arrive: balances, asset detail, transaction detail.

---

## Cross-feature navigation (not extra features)

| From | To |
|---|---|
| Dashboard Add funds / Send | `funding` / send (blocked) |
| Dashboard Credit Hub / All loans | `borrow` |
| Dashboard Savings Hub | `earn` |
| Dashboard Wallet | `wallet` (blocked) |
| Card Restore balance | `funding` or `swap` |
| Frozen card overflow | `swap`, `borrow` (booster), `earn` (dual) |
| Receive crypto Earn / Borrow pills | `earn` / `borrow` |
| Explore perpetuals | `futures` |
| Products tiles | matching feature |
| Profile Security & Settings | `security_settings` |
| Settings → Credit Line settings | `borrow` optimization |
| Settings → Payment methods | `funding` methods |
| Settings → Savings / Futures settings | `earn` / `futures` prefs (screens missing) |

---

## Out of scope until screens exist

Do not invent success UI or fields for: login/signup form, KYC wizard, wallet/asset/transaction detail, send crypto, buy/swap preview+result (structure may be improvised as review → confirm → confirmed/failed/unknown), link-card form / 3DS, recurring schedule editor, ACH instructions, restore-balance dedicated flow, loan detail, repay, futures chart / close confirm / pair picker, notification center, empty/error gallery, active card + transactions.

Improvise only the **standard money-moving chrome** (review → confirm → confirmed / failed / unknown). Do not invent fees, APY, LTV tables, or legal body.

---

## Approval

Reply with **one**:

- `Approve <feature> Use Cases` — Domain + tests only, on `feature/<feature>`
- `Approve <feature> including UI` — after Domain
- `Revise` — what to change in this catalog

I will not write Bloc or pages until you approve a single feature from the index.
