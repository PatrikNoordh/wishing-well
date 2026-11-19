# AI evaluation

How well does "photo → right product → shop with a real price" work, and what does it cost? This file holds the method and every run. It is the measured core of the project.

## The test set

`eval/cases.json`, at least 20 cases, each:

```json
{
  "id": "c01",
  "photo": "eval/photos/c01.jpg",
  "group": "brand-visible",
  "expected": { "name": "…", "brand": "…", "ean": "…" },
  "shops": ["https://www.example.se/produkt/…"]
}
```

Groups, so results can be read per kind of photo:

| Group | Example |
|---|---|
| `brand-visible` | A kettle with the brand name on it |
| `brand-hidden` | Branded, but the name is not in the photo |
| `barcode` | Packaging with the EAN visible |
| `no-brand` | A vase in a small shop |

Rules: products only, never people or private homes; at most 300 KB per photo; the developer's own photos.

## What is measured, per case

| Measure | Pass when |
|---|---|
| **Recognised** | `identify-product` returns the expected product (name and brand match; EAN when given) |
| **Page found** | `find-offers` returns at least one page that sells this product |
| **Price read** | The link reader reads a price from that page |
| **Cheapest right** | The first offer is the cheapest of those found with a price |
| **Time** | Seconds from photo to offers |
| **Cost** | Provider cost for the case, from token and search counts |

Each run records the provider, model, prompt version and date, so runs can be compared.

## Runs

*No runs yet. The first run is WISH-21.*

| Date | Provider / model | Prompt | Recognised | Page found | Price read | Cheapest right | Median time | Cost per 100 photos |
|---|---|---|---|---|---|---|---|---|

## Results per group

*Filled in per run.*

## Conclusions

*Written in WISH-25, with the decision in `docs/decisions/0008-default-ai-provider.md`.*
