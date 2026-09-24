# vesting-wallet

A linear vesting wallet with a cliff, in ~60 lines of Solidity and no dependencies
outside forge-std for tests.

A vesting wallet answers one question: *how much of this escrow has unlocked by
now?* Token teams use it for team and investor allocations so the schedule is
enforced by code instead of by a spreadsheet and good intentions.

## Behaviour

- `vestedAmount(t)` is linear between `start` and `start + duration`, but stays at
  zero until `start + cliff`.
- `releasable()` is the amount the beneficiary can withdraw right now.
- `release()` pays out everything unlocked so far; the beneficiary can call it
  repeatedly and each call sends only the newly unlocked part.

## Usage

```solidity
VestingWallet wallet = new VestingWallet(
    beneficiary,
    uint64(block.timestamp),   // start
    30 days,                   // cliff
    365 days                   // duration
);
```

Fund it with a plain transfer, then the beneficiary calls `release()`.

## What it deliberately does not do

- **No ERC-20 support.** Only native value moves. A token variant needs its own
  `IERC20` transfer path and a token address in the constructor.
- **No revocation.** There is no owner escape hatch; add one if you need
  clawback, and be aware it changes the trust story completely.
- **No per-release accounting.** `release()` recomputes from the current balance,
  so anything sent to the contract mid-schedule is released on the same curve.
  Use a bookkeeping variable if that matters to you.

## Development

```bash
forge install foundry-rs/forge-std
forge test -vvv
```

## License

MIT
