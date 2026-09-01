# Order book (display + ticket draft)

Not a matching engine. Not a new submit path. Public depth (or a stale fixture) on the existing market page. A tap builds a **Limit** draft for the existing swap ticket. `SubmitSwap` gates stay unchanged.

Branch: `feature/order-book`  
Status: **Phases 0–3.** UI on `feature/order-book`. Live depth + reconnect on `feature/market-live-feed`. Fixture / in-memory feeds stay `stale`.

## Why

Interview-style trading apps almost always ask for a live book (bids/asks, tap to populate price). We already have last-price ticks, candlesticks, and a gated swap ticket. This feature fills the missing microstructure view without a one-tap place.

## Screens and flow

No new route. Book sits on `MarketPage` (`/market/:code`) under the chart.

```text
Market detail
  → GetOrderBook (snapshot) + WatchOrderBook (updates)
  → bids / asks + freshness chip
  → tap a level → SelectOrderBookLevel
  → navigate to existing Swap as Limit (to = asset, limitPrice from level)
  → GetSwapQuote → preview → step-up → SubmitSwap
       (existing gates; book tap never submits)
```

Exchange stays **navigation only**. Buy and Add funds are dropped.

## Domain

### Entities

- `OrderBookSide` — `bid` | `ask`
- `OrderBookLevel` — side, `price` (`Money` in quote, paper = USDT), `size` (`Money` in the base asset)
- `OrderBook` — base `currency`, `quote`, bids (high→low), asks (low→high), `freshness`, `updatedAt`
- `BookTicketDraft` — base, quote, side, `limitPrice`, `size`, book `freshness`  
  Enough to open Swap as **Limit**. Not a `quoteId`. Not a ledger write.

Never `double` for price or size. Remote depth (later) is parsed as strings → `Decimal` / `Money`.

### Use Cases

| Use Case | Gates | Result |
|---|---|---|
| `GetOrderBook` | Session. Depth 1–20 (default 10). | Snapshot. Unknown / unsupported pair → `ValidationFailure`. Fixture books are **`stale`**. Last cache on failure is `stale` or `disconnected`, never invented levels. |
| `WatchOrderBook` | Session (re-checked on each emit). | Stream of `OrderBook`. Same freshness as ticks: `live` while depth updates arrive; `stale` after silence; `disconnected` on socket/HTTP failure. |
| `SelectOrderBookLevel` | Session. Level must exist on the current book. | `BookTicketDraft`. **`disconnected` → `StaleQuoteFailure`** (do not populate from a dead book). **`stale` → draft + stale flag** (preview/submit still blocked until a **current** live quote). Does **not** require KYC or step-up. Does **not** call the ledger or `GetSwapQuote`. |

### Not Use Cases

| Work | Layer | Why |
|---|---|---|
| WebSocket reconnect + backoff | `BinanceMarketFeed` (Data) | Domain already observes `disconnected` → `stale` → `live`. |
| CI | Ship | No Domain `call()`. |
| `SubmitOrderFromBook` / click-to-place | **Forbidden** | Violates order-placement rules. First tap must not execute. |
| Pause / resume stream | Later, optional | Only if we add an explicit user pause (`PauseOrderBook` / `ResumeOrderBook`; last book becomes `stale`). |

### Shared contracts (unchanged)

Session on every book Use Case. Money as `Money`. Submit still needs KYC `approved` + step-up + **current** `QuoteFreshness.live` + `requestId`. Fixture / cached books are never `live`. Breadcrumbs stay `requestId` + settlement only — never log the book or a draft.

## Implementation flow

Do these in order. Do not skip to UI or a live depth socket.

### Phase 0 — this slice (approved Use Cases)

1. Catalog + this design doc.
2. Domain entities + `MarketRepository` port (`getOrderBook`, `watchOrderBook`).
3. Use Cases + unit tests (no session, disconnected select, stale draft, unknown level, unknown pair).
4. Local fixture books on `MarketLocalDataSource` — always `stale`. Repository maps fixture → entity. Tests assert fixture freshness is not `live`.
5. **Stop.** No Cubit, no widget, no Binance depth, no router query.

### Phase 1 — Cubit + UI (**approved**)

1. Short note in `trading-ux.md`: book is display-only; isolated widget; `BlocSelector` so a depth tick does not rebuild the chart.
2. `MarketCubit` loads `GetOrderBook` with the asset, subscribes to `WatchOrderBook`, keeps `OrderBook` on `MarketSuccess`.
3. Book widget: bids left or stacked, asks, spread is derived in the widget from the two best `Money` prices (display only). Freshness chip already exists.
4. Tap: Cubit calls `SelectOrderBookLevel`. On success, `go_router` to existing Swap with Limit extras (`to`, `limitPrice`, quote). On `StaleQuoteFailure` / validation, show a non-technical reason; `onPressed` stays null while disconnected.
5. Swap: accept optional Limit seed from the route. Still `GetSwapQuote` → preview → step-up → `SubmitSwap`. Do not treat the draft as a quote.
6. Tests: Cubit (load / tick / select / disconnected); widget/flow: tap level → swap Limit field; tap does not submit; disconnected tap does not navigate.

### Phase 2 — live public depth (Data only, **done**)

1. Extend `MarketFeed` with snapshot + stream of books. In-memory / test feed stays `stale`.
2. Binance: REST depth snapshot, then depth WebSocket (or `@depth` diff applied locally). Payload **strings** → `Money`. Flavor URLs only.
3. Freshness: `live` while depth events arrive; `stale` after the same watchdog as tickers (15s); failed socket → last cache `disconnected` or `stale`.
4. Repository prefers the feed; falls back to last cache; fixture only when the feed has never seen that pair.
5. Tests: parser (strings, reject junk), freshness decay, no `double`.

### Phase 3 — reconnect (Data only, shared with tickers, **done**)

1. On `onDone` / `onError`, do **not** leave the app hung on `disconnected` forever.
2. Backoff reconnect of the **existing** ticker (and depth) sockets. Last quotes/books stay `stale` until a new event. Never mark reconnect-as-success `live` without a payload.
3. Tests: disconnect → stale cache → reconnect → live. No Domain Use Case.

## Out of scope

Wallet, send crypto, real exchange routing, custody, L2 aggregation beyond top N, click-to-place, inventing spread fees, pause control (unless product asks).

## Tests (mandatory per phase)

| Phase | Minimum |
|---|---|
| 0 | Use Cases + repository (fixture stale) + entity normalize/find |
| 1 | Cubit + widget/flow (tap → draft → swap; no submit) |
| 2–3 | Feed parser + freshness + reconnect |

Money-moving still belongs to `swap`. This feature must not add a second place path.
