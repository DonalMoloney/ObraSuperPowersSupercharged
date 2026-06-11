---
name: agent-bazaar
description: Use as an alternative dispatch mode when a plan has 4+ parallelizable tasks — an auctioneer posts each task and competing subagents bid for the work with sealed approach-plus-cost estimates.
tier: v3
status: experimental
---

# agent-bazaar

A market instead of an assignment. When a plan contains 4 or more
parallelizable tasks:

1. **Post:** an auctioneer agent lists each task with an estimated price — a
   complexity budget in turns/tokens.
2. **Bid:** 3–5 bidder subagents each submit a sealed bid: a short approach
   sketch plus their own cost estimate. Bids are sealed — no bidder sees
   another's bid before submitting.
3. **Award:** the cheapest *credible* bid wins each task. Credibility is
   judged by the auctioneer against the approach sketch, not the price alone.
4. **Settle:** bidders who blow their estimate get a reputation penalty
   recorded in a ledger (described, not built) that handicaps their future
   bids; accurate estimators earn trust.

The losing bids are not waste: they are free plan review. Divergent approach
sketches for the same task are a signal the task is underspecified.

## Why this might be crazy enough to work

Forcing agents to commit to a cost estimate *before* working is a known
calibration trick — the bid itself is a cheap plan-quality signal, and you get
multi-perspective plan review for free from the losing bids.

## Known risks / absurdities

The economy may be theater — all bidders are the same model, so price
competition may just select for the most overconfident hallucinated estimate.
The reputation ledger is the proposed corrective; whether same-model agents can
develop genuinely distinct bidding track records is the open question.
