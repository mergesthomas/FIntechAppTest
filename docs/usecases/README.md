# Domain Use Cases

Branch: `feature/use-cases`  
Scope: Domain only. No Bloc, pages, or data sources in this slice.

Use Cases are grouped by feature, then by category. Each has one `call()` and returns `Either<Failure, T>`.

Legal, fee, APY, cashback, and LTV **copy** is a server key / placeholder. Do not invent user-facing strings.

---

## Core (shared)

| Type | Path |
|---|---|
| `Money` / `Currency` | `lib/core/money/` |
| `Failure` | `lib/core/error/failure.dart` |
| `AuthPort` + `AccessGuards` | `lib/core/auth/` |
| `QuoteFreshness` | `lib/core/market/quote_freshness.dart` |
| `SettlementStatus` | `lib/core/settlement/settlement_status.dart` |

Gates: session, KYC (`unknown` / `approved` / `denied`), step-up, live quote. Submits use `requestId` and return `inFlight` / `unknown` / `confirmed` / `failed`.

---

## `add_funds`

Design: `docs/design/add-funds.md`

### Shared
- `RequireFundingSession`
- `GetFundingEligibility`

### Hub
- `GetAddFundsMethods` — bank / add crypto / buy crypto

### Bank
- `GetFiatxAssets`
- `GetBankRails`
- `GetFiatAccountStatus`
- `GetFiatReceiveDetails`
- `GetBankTransferFeeSchedule`
- `AcceptFiatAccountTerms`
- `CreatePersonalUsdAccount`

### Receive crypto
- `GetReceivableAssets`
- `SearchReceivableAssets`
- `GetReceiveAddress`
- `GetAssetFundingTeasers`

### Buy crypto
- `GetPurchasableAssets`
- `SearchPurchasableAssets`
- `GetBuyQuote`
- `GetPaymentMethods`
- `GetPurchaseFrequencies`
- `GetEmptyBalances`
- `StartLinkCard`
- `SubmitBuyCrypto` — live quote + step-up + KYC; settlement, not HTTP 200

---

## `all_loans`

Design: `docs/design/all-loans.md`

### Shared
- `RequireBorrowSession`
- `GetBorrowEligibility`

### Hub
- `GetAllLoansOverview`
- `GetLoanProducts`

### Collateral
- `GetCollateralAssets`
- `GetCollateralFilter`
- `GetAssetLtvSchedule`

### Settings
- `GetCreditLineOptimization`
- `UpdateCreditLineOptimization` — dependent flags require automatic collateral transfer

### Borrow / repay
- `GetBorrowQuote`
- `SubmitBorrow`
- `SubmitRepay`

---

## Later features (catalog only — not generated yet)

| Feature | Planned Use Cases |
|---|---|
| `auth` | `SignUp`, `LogIn`, `VerifySms`, `CreatePin`, `ConfirmPin`, `EnableBiometric`, `LockSession` |
| `kyc` | `GetKycStatus`, `StartKyc`, `SubmitKyc` |
| `dashboard` | `GetPortfolioSummary`, `GetWatchlist`, `GetInboxPreview` |
| `savings` | `GetSavingsHub`, `GetEarnProducts` |
| `swap` | `GetSwapQuote`, `SubmitSwap` |
| `futures` | `GetFuturesTicket`, `SubmitFuturesOrder`, `GetPositions`, `ClosePosition` |
| `card` | `GetCardStatus`, `UnfreezeCard`, `GetCardTransactions` |
| `wallet` | `GetAssetDetail`, `SendCrypto` |
| `explore` | `GetMarkets`, `GetNews` |
| `profile` | `GetProfile`, `GetSecuritySettings`, `GetDocuments` |

---

## Tests

- `test/core/money_test.dart`
- `test/features/add_funds/submit_buy_crypto_test.dart`
- `test/features/add_funds/create_usd_account_test.dart`
- `test/features/all_loans/credit_line_optimization_test.dart`
- `test/features/all_loans/submit_borrow_test.dart`
