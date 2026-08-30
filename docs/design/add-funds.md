# Add funds — design + Use Cases

Status: **domain generated** on `feature/use-cases`  
Type: money-moving (funding)

Domain Use Cases live under `lib/features/add_funds/domain/`. No Bloc or UI in this slice.

Legal, fee, APY, cashback, and rail copy below is **transcribed from screenshots** as placeholders. Human / compliance review required before any user-facing string ships.

---

## What the screens show

Three entry methods from **Add funds**:

1. **Bank transfers** — fund FIATx (USDx / EURx / GBPx) via ACH, SEPA, or SWIFT.
2. **Add crypto** — receive on-chain to a custodial address (QR + address + network).
3. **Buy crypto** — buy with card / Apple Pay / linked card, optional schedule, cashback teaser.

Observed screens (local, gitignored):

| Screen | Folder | Have |
|---|---|---|
| Add funds hub | `screenshots/add_funds` | yes |
| Select FIATx | `screenshots/select_asset_fiatx` | yes |
| Select bank rail (ACH / SWIFT) | `screenshots/select_bank_method` | yes |
| Open personal USD account | `screenshots/open_usd_account` | yes |
| Receive FIATx (SEPA / SWIFT) | `screenshots/receive_fiat` | yes |
| Select asset to receive | `screenshots/select_asset_receive` | yes |
| Receive crypto | `screenshots/receive_crypto` | yes |
| Select asset to buy | `screenshots/select_asset_buy` | yes |
| Buy amount + keypad | `screenshots/buy_crypto` | yes |
| Payment methods sheet | `screenshots/payment_methods` | yes |
| Buy preview / review | `screenshots/buy_preview` | **missing** |
| Buy success / failure / unknown | `screenshots/buy_result` | **missing** |
| Link card | `screenshots/link_card` | **missing** |
| Purchase frequency picker | `screenshots/purchase_frequency` | **missing** |
| Restore FIATx balance | `screenshots/restore_balance` | **missing** |
| ACH deposit instructions | `screenshots/ach_instructions` | **missing** |

---

## Flows

```text
Add funds
├── Bank transfers
│   ├── Select FIATx (USDx | EURx | GBPx)
│   ├── USDx + no account → Open personal USD account (terms) → Create account
│   ├── USDx + account? → Select method (ACH | SWIFT) → [ACH instructions missing]
│   └── EURx / GBPx → Receive details (SEPA | SWIFT) + fee schedule + share/copy
├── Add crypto
│   ├── Select asset
│   └── Receive: address, QR, network, copy, share, important notes
└── Buy crypto
    ├── Select asset (live price + 24h change)
    ├── Amount (fiat, keypad, quick chips, frequency, payment method)
    ├── Payment methods (card | link card | Apple Pay | empty balances)
    ├── [Preview missing]
    └── [Result missing: confirmed | failed | unknown]
```

---

## Settlement

Never treat HTTP 200 as settled. Every funding attempt has:

| Path | After submit | Terminal |
|---|---|---|
| Buy (card / Apple Pay) | `inFlight` | `confirmed` / `failed` / `unknown` |
| Bank inbound (SEPA / SWIFT / ACH) | details shown ≠ credited; inbound stays `inFlight` until ledger posts | `confirmed` / `failed` / `unknown` |
| On-chain receive | address issued ≠ received; deposit `inFlight` until confirmations | `confirmed` / `failed` / `unknown` |
| Create USD account | `inFlight` | `confirmed` / `failed` / `unknown` |

`unknown` is a first-class UI state (do not retry blindly; poll / refresh by `requestId`).

---

## Idempotency

Every submit carries a client `requestId`. Retries reuse the same id.

- `CreatePersonalUsdAccount`
- `SubmitBuyCrypto`
- `StartLinkCard` (if it creates a processor session)

Buy also binds a server `quoteId`. Re-submit with a new quote only after the user re-quotes.

---

## Eligibility

All surfaces require a session. Use Cases refuse if session is missing or expired.

| Action | Gate |
|---|---|
| Open Add funds | session |
| Bank rails + create USD account | session + KYC approved + region allows rail |
| Show receive address | session + asset/network allowed for user |
| Continue / submit buy | session + KYC approved + payment method eligible + **live** quote + step-up |
| Apple Pay row | session + platform entitlement; hide if unavailable |

If KYC is unknown or failed: do not open Create account, Continue buy, or Link card.

Step-up (PIN / biometric / re-auth) is required on **SubmitBuyCrypto** and **CreatePersonalUsdAccount**.

Quotes: if freshness is `stale` or `disconnected`, **SubmitBuyCrypto** rejects. Do not buy on a cached price.

---

## Money

Domain uses `Money` (decimal + currency). Fiat and crypto have explicit precision.

Do not use `double` for amounts, prices, fees, cashback, or rates.

---

## Feature: `add_funds`

### Shared

- `RequireFundingSession` — fail if no valid session.
- `GetFundingEligibility` — KYC + region + product flags (`unknown` / `approved` / `denied`).

### Hub

- `GetAddFundsMethods` — bank / add crypto / buy crypto rows the user is allowed to see.

### Bank transfers

- `GetFiatxAssets` — USDx / EURx / GBPx plus server fee teasers (do not hard-code).
- `GetBankRails` — rails for asset + user region (ACH, SEPA, SWIFT).
- `GetFiatAccountStatus` — none / inFlight / confirmed / failed / unknown.
- `AcceptFiatAccountTerms` — records consent; does not create the account.
- `CreatePersonalUsdAccount` — `requestId` + step-up + KYC; returns settlement.
- `GetFiatReceiveDetails` — beneficiary fields for `asset` + `rail`. Copy/share is presentation; Use Case only loads details.
- `GetBankTransferFeeSchedule` — server fees for rail + asset. Screenshot placeholders only:
  - SEPA EURx: free above €100; €5.00 below €100
  - SWIFT EURx: €25.00
  - USDx teaser: free SWIFT above $5,000
  - GBPx teaser: free transfers above £100

### Add crypto

- `GetReceivableAssets` — searchable list.
- `SearchReceivableAssets`
- `GetReceiveAddress` — address + URI for QR + network. Never log the address.
- `GetAssetFundingTeasers` — earn / borrow badges from server. Screenshot placeholders: “Earn up to 3% p.a.”, “Borrow from 1.9% per year”.

### Buy crypto

- `GetPurchasableAssets` — list + price + 24h change + freshness (`live` / `stale` / `disconnected`).
- `SearchPurchasableAssets`
- `GetBuyQuote` — `Money` fiat in, crypto out, cashback teaser, `quoteId`, freshness. Reject if market data not live when submitting.
- `GetPaymentMethods` — verified cards, Apple Pay if available, link-card affordance, empty FIATx/stable balances.
- `GetPurchaseFrequencies` — one-time vs scheduled (schedule UI missing).
- `StartLinkCard` — KYC; returns processor session, not a raw PAN.
- `GetEmptyBalances` — FIATx / stables shown as empty; “Restore balance” is a separate missing flow.
- `SubmitBuyCrypto` — `requestId` + `quoteId` + payment method + `Money` + frequency + step-up. Refuses stale quote, missing session, or ineligible KYC. Returns settlement, not HTTP success.

---

## Out of scope until screens exist

Do not invent these Use Cases’ success UI:

- Buy preview / confirm
- Buy result (`confirmed` / `failed` / `unknown`)
- Link-card form / 3DS
- Recurring schedule editor
- Restore EURx / FIATx balance
- ACH instructions after USD account is confirmed
- Multi-network picker (only “Dogecoin Network” is shown)
- Important-notes body copy

---

## Logging

Breadcrumb submits by `requestId` and settlement only. Never log balances, tokens, PANs, IBANs, wallet addresses, or names.

---

## Next

UI (including improvised buy preview / result) is a separate approval. Data layer is not generated yet.
