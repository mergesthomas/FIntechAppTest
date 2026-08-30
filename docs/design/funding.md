# Funding (local emulator)

Local-only deposit / receive / buy. No processor, no live quotes.

## Settlement

Every create/buy submit carries a client `requestId`. Retries reuse it and must not double-apply.

Statuses: `inFlight` | `unknown` | `confirmed` | `failed`. Showing bank or on-chain details is not a credit.

## Gates

- Session required on every use case.
- KYC `approved` required to open a USD account or submit a buy.
- Step-up (PIN in UI) required on those submits.
- `SubmitBuyCrypto` requires a **live** quote. Fixture quotes are `stale` → submit is rejected. No buy is posted until a remote price feed exists.

## Rails

- Bank: FIATx pickers + SEPA/SWIFT details (screenshot fee placeholders). USDx open-account is a local job (`inFlight`).
- Receive crypto: fixture address + network. Never log the address.
- Buy: asset → amount → method → improvised preview → confirm. Result is rejection (`StaleQuoteFailure`) or later a settlement status.

Legal / fee copy is screenshot placeholder only.
