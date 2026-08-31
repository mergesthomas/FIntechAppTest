# Trading UX (charts + action buttons)

Display-only market charts and navigation into existing paper flows. No new money-moving submit path.

## Dashboard / overview charts

Unchanged. Line/area `PriceChart` from `MarketFeed.seriesFor` / `refreshSeries` (close prices only).

## Coin detail candlesticks

Interactive OHLCV candlesticks render **only** on `MarketPage` (`/market/:code`). They are not used on the dashboard or explore.

- Domain: `OhlcvCandle` / `CandleSeries` with `Decimal` OHLC + volume. No `double` in Domain.
- Intervals: 1m, 5m, 15m, 1h, 4h, 1D, 1W via `GetCandleChart`. Changing interval refetches and redraws.
- In-memory / tests: synthetic candles (including doji / hammer / inverted hammer / shooting star). Freshness stays `stale` unless a test injects `live`.
- Running app: Binance public klines (strings → `Decimal`). Failed fetch keeps last cache as `stale` / `disconnected`.
- Live ticks: `WatchMarketTicks` updates the forming candle and last-price line. New interval bucket opens a new candle.
- UI: TradingView-style `candlesticks` chart on the calm theme (`ColorScheme` bull/bear). Isolated widget; dashboard stays on `PriceChart`.
- Never submit from a chart. Submit still requires a current `live` quote in the existing use cases.

## Actions

Buy / Exchange / Futures / Add funds only **route** to funding, swap, and futures. Session, KYC, PIN, and live-quote gates stay in those features.

## Out of scope

Wallet, send crypto, real exchange routing. Asset page is a **market** view, not a wallet.
