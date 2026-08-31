# Swap (paper Instant / Limit / Trigger)

Not a broker. Public market ticks only. Fills post to the local paper ledger.

## Entry

Exchange tab opens Swap. No OTC / Booster / Dual Investment sheet. Savings / Credit is hidden; the savings book is always used.

## Order types

Quoted as **1 unit of receive (`to`) in pay (`from`)** (Limit shot: `0.06 EURx` per DOGE).

| Type | Place | Fill |
|---|---|---|
| Instant | Live quote required | Now, at current live conversion |
| Limit | Live quote; limit **better** than live (lower `from` per `to`) | When live `from`-per-`to` **≤** limit |
| Trigger | Live quote; TP and/or SL | **TP:** live ≤ take-profit (better). **SL:** live ≥ stop-loss (worse). First hit wins |

Limit / Trigger **hold** `from` on place (order `open`). `to` is credited at **fill-time** live rate. Cancel releases the hold.

Stale or disconnected: do not place, do not fill.

## Gates

Session, KYC `approved`, step-up, `requestId`. Submit re-checks **current** live freshness.

## Display-only (COMPLIANCE)

Fee `0.99 USD` and cashback `0.50%` are screenshot placeholders. They are not ledger credits.

## Out of scope

Real exchange routing, Credit wallet, OTC / Booster / Dual Investment.
