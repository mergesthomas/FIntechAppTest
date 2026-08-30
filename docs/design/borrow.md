# Borrow (local emulator)

Credit catalog + outstanding + collateral + optimization. No live LTV feed.

## Settlement

`SubmitBorrow` / `SubmitRepay` / `UpdateCreditLineOptimization` carry `requestId`. Statuses: `inFlight` | `unknown` | `confirmed` | `failed`.

## Gates

- Session + KYC `approved` on borrow/repay/optimization.
- Step-up on those submits.
- `GetBorrowQuote` fixture freshness is `stale`. `SubmitBorrow` rejects stale LTV (`StaleQuoteFailure`). No borrow is posted until a live quote exists.

## Optimization

Automatic collateral transfer is required for Fixed-term unlock and Low-interest borrowing. Turning auto-transfer off must refuse or clear those dependent flags.

Legal / LTV / rate copy is screenshot placeholder only.
