# Command Code

Tracks [Command Code](https://commandcode.ai) (multi-model inference plan) usage from local harness
logs: Usage Trend plus Today / Yesterday / Last 30 Days spend.

## Credentials

No login or key needed. Command Code's Provider API exposes chat/messages/models only — there is no
usage endpoint (checked 2026-09) — so the card is built from **pi's session logs**, which record
authoritative per-message costs for `commandcode` traffic. The enablement probe checks that pi has a
`commandcode` key in `~/.pi/agent/auth.json`.

If Command Code ships a usage endpoint later, quota meters (5-hour / weekly / monthly credits per
their plan docs) can join the card the same way Kimi's did.

## What it tracks

- **Usage Trend** — daily tokens over the last 30 days.
- **Today / Yesterday / Last 30 Days** — spend tiles, dollars and tokens from pi logs (estimated
  flag: pi's carried costs are authoritative where present).

## Errors

- **No data** — no pi sessions with `commandcode` traffic in the scan window.
