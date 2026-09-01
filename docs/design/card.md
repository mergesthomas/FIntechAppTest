# Card (local emulator)

Frozen card is a first-class state. Active chrome is emulated (last4, Debit mode, freeze / reveal PIN). Borrow, repay, and Credit mode are out of scope.

## Balances

EURx may be negative. Domain uses `Money`. Restore does not invent a rail — it routes to `swap`.

Cashback earned is a **placeholder** for compliance review. It is not a ledger credit.

## Gates

Session required. Unfreeze only when the FIATx balance is eligible (not negative). Reveal PIN requires step-up. No full PAN/CVC, no invented processor.
