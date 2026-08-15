---
id: PRO-006
title: Monetization
status: accepted
owner: process
tags: [monetization, business, ethics, cosmetics, pipeline]
updated: 2026-08-14
related: [PRO-005, DES-014, DES-016, DES-001]
---

# Monetization

## The model

> **DECIDED (ADR-026): premium purchase. Nothing else. No microtransactions of any kind, cosmetic or otherwise.**

You buy the game. You get the game. Everything in it is earned by playing it.

## Why this is the right call, not just the nice one

The obvious argument is ethical, and `PRO-005 §11` already makes it: a game about compulsion that monetizes with the mechanisms it critiques becomes an instance of the thing instead of a work about it.

But there are two design arguments that are stronger, and they're the reason this decision improves the game rather than merely costing money:

**1. Paid cosmetics would have broken the staves.** ADR-022 relies on the Threshold signalling **tenure** — how long someone has been feeding her. The moment camps can be bought, the space signals *spending* instead, and the entire mitigation that made a public tally acceptable collapses. Selling camp themes would have quietly undermined a system we deliberately designed to be safe.

**2. Everything in a camp becomes evidence.** With no purchasable dressing, every object on a plot is a **deed** (`DES-016`). A camp becomes unforgeable — a readable record of what that player has actually done and chosen. That's worth far more, socially and thematically, than a storefront.

## Consequences

- **Post-launch content is content**, not cosmetics: new classes (`DES-011` — already the planned Lineage track), biomes, expeditions. Sold as expansions if sold at all.
- **Revenue is the sale price**, so the game must be worth its price on day one. No back-loaded monetization to lean on.
- Everything in `DES-016` (Deeds & Trophies) is earned, permanent, and free.

## Standing prohibitions

Recorded so this cannot drift under commercial pressure later:

- No loot boxes, gacha, or randomized purchase
- No premium currency
- No battle pass or season pass
- No purchasable power, progression, Boon, Legacy slots, or stash space
- No purchasable cosmetics
- No FOMO, no expiring content, no rotating limited-time storefront
- Nothing that makes absence costly

## Pipeline notes (still worth doing)

Even with nothing for sale, camp dressing should be built the clean way — it costs nothing now and keeps expansions cheap:

1. Campsite props are **data-driven `.tres` resources** (`TEC-001`), never hardcoded scene geometry.
2. A camp's appearance is a **manifest** of prop/material references applied to fixed sockets on the plot.
3. Camp state replicates as **IDs, never content** — peers resolve visuals locally (`TEC-004`).

> **Note:** Q63, Q64 and Q65 are closed by ADR-026 — there is no DLC visibility question, no price point, and no earned-versus-paid pool split, because there is only one pool.
