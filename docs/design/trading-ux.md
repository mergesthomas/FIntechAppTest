# Trading UX (charts + action buttons)

Display-only market charts and navigation into existing paper flows. No new money-moving submit path.

## Charts

- Series come from `MarketFeed` (`seriesFor` / `refreshSeries`).
- In-memory / tests: deterministic synthetic closes from the last tick. Freshness stays `stale` unless a test injects `live`.
- Running app: Binance public klines (strings → `Decimal`). Cache locally. Failed fetch keeps last cache as `stale` / `disconnected`.
- Never submit from a chart. Submit still requires a current `live` quote in the existing use cases.

## Actions

Buy / Exchange / Futures / Add funds only **route** to funding, swap, and futures. Session, KYC, PIN, and live-quote gates stay in those features.

## Out of scope

Wallet, send crypto, real exchange routing. Asset page is a **market** view, not a wallet.
