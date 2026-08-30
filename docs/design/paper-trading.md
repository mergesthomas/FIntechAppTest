# Paper trading (live public prices + local ledger)

Not a broker. No real money leaves the device. Public market data only.

## Market data

- Remote: Binance public REST snapshot + WebSocket tickers (flavor URLs).
- Ticks are parsed as **strings** → `Money` / `Decimal`. Never `double`.
- Freshness: `live` while ticks arrive; `stale` after 15s silence; `disconnected` on socket/HTTP failure.
- Fixture / test feed stays `stale` so CI never depends on the network.
- `dev` `main.dart` overrides the feed with the remote client.
- EURx uses EURUSDT as a stand-in. USD/USDT/USDx peg at 1 for paper. COMPLIANCE: not a NAV or redemption rate.

## Submit gates (unchanged)

Session + KYC `approved` + step-up + `requestId`. Quote-sized submit still requires **current** `live` freshness (re-checked at submit, not only the stored flag).

## Ledger

Shared in-memory `PaperLedger`. Seed matches emulator fixtures (NEXO 120, BTC 0.15, EURx −1.16, USD 10,000, futures USDT 186.25).

Submit: check balances → hold → `inFlight` breadcrumb (`requestId` + status only) → settler applies debit/credit → `confirmed` (or `failed`). Retries reuse `requestId`.

## Orders

Each confirmed (or open) paper fill is appended to `PaperOrderStore`. The `orders` feature maps them onto Trigger / Limit / **Market** tabs. Cancel stays idempotent `inFlight`.

## Out of scope

Real exchange routing, wallet/send UI, inventing LTV, logging balances or PII.
