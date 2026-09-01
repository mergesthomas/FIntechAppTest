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

Exchange on market detail **routes** to swap with `to` set to that coin. The CTA is pinned to the bottom of the screen (navigation only). Dashboard has no Exchange CTA; the shell tab is the other entry. Session, KYC, PIN, and live-quote gates stay in swap. Buy and Add funds are dropped.

Open Limit / Trigger orders for that coin show as cards under the price header (`GetOpenOrdersForAsset`), above the chart and order book. Edit reopens the existing Swap ticket as a seed. Cancel uses `CancelOrder` (session, KYC, step-up, `requestId`).

## Order book

Display-only L2 on `MarketPage`, isolated via `BlocSelector`. Specified in [`order-book.md`](order-book.md). Running app uses Binance partial depth (`live` while events arrive). Fixture / in-memory feeds stay `stale`. Tap seeds existing Swap Limit (`to` + `limitPrice`); it does not submit. Disconnected levels have `onTap: null`.

## Out of scope

Wallet, send crypto, real exchange routing. Asset page is a **market** view, not a wallet.
