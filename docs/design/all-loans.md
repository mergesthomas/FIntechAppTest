# All loans — design + Use Cases

Status: **domain generated** on `feature/use-cases`  
Type: money-moving (borrow / credit)

Domain Use Cases live under `lib/features/all_loans/domain/`. No Bloc or UI in this slice.

Rate, LTV, product, and risk copy below is **transcribed from screenshots** as placeholders. Human / compliance review required before any user-facing string ships.

---

## What the screens show

**All loans** is the catalog + debt hub. Two tabs:

1. **Available to borrow** — capacity per product (screenshot shows **0.00 xUSD** max).
2. **Outstanding loan** — total debt + per-product outstanding (screenshot total **14,694.96 xUSD**).

Overflow (⋮) opens:

- Check the LTV of your assets → **Collateral assets**
- Credit line settings → **Credit Line optimization**

Observed screens (local, gitignored):

| Screen | Folder | Have |
|---|---|---|
| All loans (available + outstanding) | `screenshots/all_loans` | yes |
| Collateral assets + LTV | `screenshots/collateral_assets` | yes |
| Credit Line optimization + product picker | `screenshots/credit_line_optimization` | yes |
| Credit Line / 0% / Booster / Card marketing | `screenshots/credit_line` etc. | yes (earlier dump) |
| Loan product detail | `screenshots/loan_detail` | **missing** |
| Dedicated LTV explainer (if not collateral list) | `screenshots/check_ltv` | **missing** |
| Borrow amount / review / confirm | `screenshots/borrow_review`, `borrow_confirm` | **missing** |
| Repay | `screenshots/repay` | **missing** |

Products on the hub:

| Product | Tagline (screenshot) | Terms (screenshot) | Role |
|---|---|---|---|
| Classic | Best for flexible borrowing | From 9.9% • Flexible • 100+ collateral assets | Active |
| Card | Best for everyday spending | From 9.9% • Flexible • 2 modes | Active |
| Zero-interest Credit | Best for fixed credit | 0% • Fixed repayment • 2 collateral assets | Active |
| Booster | (partial) | (not fully visible) | Available |

---

## Flows

```text
All loans
├── Tab: Available to borrow
│   ├── Maximum borrowing amount (xUSD)
│   └── Product cards → [loan detail missing] or existing credit_line / booster / card screens
├── Tab: Outstanding loan
│   ├── Total outstanding (xUSD)
│   └── Product outstanding rows → [loan detail missing]
├── Overflow
│   ├── Check the LTV of your assets → Collateral assets
│   │     ├── Filter: Credit Line (type) | Loan-to-value %
│   │     └── Borrow CTA → [borrow review missing]
│   └── Credit line settings → Credit Line optimization
│         ├── Select Credit Line (Classic | Card)
│         ├── Automatic collateral transfer
│         ├── Fixed-term Savings unlock (requires auto transfer)
│         └── Low-interest borrowing (requires auto transfer)
```

---

## Settlement

Toggling optimization flags can move collateral or change how debt is serviced. Treat updates as submits.

| Path | After submit | Terminal |
|---|---|---|
| Update credit-line optimization | `inFlight` | `confirmed` / `failed` / `unknown` |
| Borrow (screens missing) | `inFlight` | `confirmed` / `failed` / `unknown` |
| Repay (screen missing) | `inFlight` | `confirmed` / `failed` / `unknown` |

Never treat HTTP 200 as settled. `unknown` is a first-class UI state; refresh by `requestId`, do not double-submit.

Read-only loads (overview, collateral list, settings snapshot) are not settlements.

---

## Idempotency

Every submit carries a client `requestId`. Retries reuse the same id.

- `UpdateCreditLineOptimization`
- `SubmitBorrow` (when screens exist)
- `SubmitRepay` (when screens exist)

---

## Eligibility

Session required on all surfaces. Use Cases refuse if session is missing or expired.

| Action | Gate |
|---|---|
| Open All loans | session |
| See capacity / outstanding | session + eligibility known (show empty/denied, do not invent capacity) |
| Open Borrow CTA | session + KYC approved + product eligible |
| Update optimization toggles | session + KYC approved + step-up |
| Submit borrow / repay | session + KYC approved + step-up + live collateral/LTV where required |

If KYC is unknown or failed: do not open Borrow or settings submits.

Market / LTV used to size a borrow must be `live`. Stale or disconnected → reject submit.

---

## Money

Domain uses `Money` (decimal + currency). Outstanding, available, LTV inputs, and rates are not `double`.

xUSD is an explicit currency (or ledger unit) in `Money`, not a formatted string.

---

## Feature: `all_loans`

### Shared

- `RequireBorrowSession` — fail if no valid session.
- `GetBorrowEligibility` — KYC + region + product flags (`unknown` / `approved` / `denied`).

### Hub

- `GetAllLoansOverview` — tabs: available vs outstanding. Returns:
  - maximum borrowing amount (`Money`, xUSD)
  - total outstanding (`Money`, xUSD)
  - product cards (id, kind, available, outstanding)
- `GetLoanProducts` — catalog metadata (tagline, term chips). Copy from server, not hard-coded.

Product kinds: `classic` | `card` | `zeroInterest` | `booster`.

### Collateral / LTV

- `GetCollateralAssets` — per credit-line type: asset, balance as `Money`, LTV percent as decimal ratio (not `double` math on prices).
- `GetCollateralFilter` — Credit Line type + sort/filter by LTV.
- `GetAssetLtvSchedule` — LTV percents from server (screenshot placeholders: DOGE 30%, NEXO 15%, BTC 50%, USDT/USDC 90%).

Zero balance rows stay visible (PEPE, BTC, … at `$ 0.00`).

### Credit Line optimization

- `GetCreditLineOptimization` — for product `classic` | `card`.
- `UpdateCreditLineOptimization` — `requestId` + step-up + flags:
  - `automaticCollateralTransfer`
  - `fixedTermSavingsUnlock` (allowed only if automatic transfer is on)
  - `lowInterestBorrowing` (allowed only if automatic transfer is on)

If automatic transfer is turned off, the Use Case must clear or refuse the two dependent flags. Do not leave an illegal combination in Domain.

Help `(?)` copy is **not** on screenshots — do not invent it. Use a placeholder key until compliance provides text.

### Borrow / repay (blocked on missing screens)

Propose but do not implement UI:

- `GetBorrowQuote` — live LTV + `Money` + `quoteId` + freshness.
- `SubmitBorrow` — `requestId` + `quoteId` + product + `Money` + step-up. Refuse stale quote.
- `SubmitRepay` — `requestId` + loan id + `Money` + step-up.

---

## Domain rules visible on screens

- Outstanding tab total equals the sum of product outstandings only if the backend says so. Do not assume `14,694.96 = 14,625.44 + 69.52 + 0.00` in the client (it matches here; still sum in Domain only via a Use Case / entity invariant if product requires it).
- Available tab can show **0.00** capacity while products remain listed (empty capacity ≠ hide catalog).
- Booster is under **Available**, not Active, in these shots.
- Optimization is per credit line (Classic vs Card), not global.

---

## Out of scope until screens exist

- Loan product detail after tapping a card
- Borrow review / confirm / result
- Repay flow
- Tooltip / legal body for the three optimization flags
- LTV explainer if it is not the collateral list
- Changing “Loan-to-value %” filter UI beyond a sort key

---

## Logging

Breadcrumb submits by `requestId`, product kind, and settlement only. Never log balances, LTV portfolios, tokens, or PII.

---

## Next

UI (including improvised borrow / repay review) is a separate approval. Data layer is not generated yet.
