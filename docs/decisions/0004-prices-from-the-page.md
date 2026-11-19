# 0004 — Prices are read from the shop's page, never taken from the AI

- **Status:** accepted
- **Date:** 2026-11-15

## Context

"Cheapest first" is only worth something if the prices are right. A language model with web search can return a plausible price that is old, belongs to another variant, or is made up.

## Decision

The AI only suggests candidate pages. An Edge Function fetches each page itself (with the protections in security rule 10) and reads the price from the page's own structured data: schema.org `Product`/`Offer` first, then Open Graph. A candidate without a readable price is shown without a price. Offers are sorted by the read prices, and each shows when it was read.

## Alternatives

| Option | Why not |
|---|---|
| Trust the AI's price | Not verifiable; one wrong "cheapest" breaks trust |
| A price comparison service (Prisjakt) | The best source for Sweden, but needs partner access; kept as a later second source |
| Scraping search engine results | Against the search engines' terms |

## Consequences

- The same link reader serves "paste a link" (WISH-18) and the offers (WISH-23).
- Shops without structured data show no price; the evaluation measures how often (`docs/ai-eval.md`, "price read").
