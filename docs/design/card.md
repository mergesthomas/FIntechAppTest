# Card (local emulator)

Frozen card is a first-class state. Active chrome is emulated (last4, Debit mode, freeze / reveal PIN). Borrow, repay, Credit mode, and cashback earned are out of scope.

## Balances

EURx may be negative. Domain uses `Money`. Restore does not invent a rail — it routes to `swap`.

## Gates

Session required. Unfreeze only when the FIATx balance is eligible (not negative). Reveal PIN requires step-up. No full PAN/CVC, no invented processor.
