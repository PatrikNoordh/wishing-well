---
name: wish-ai-eval
description: "Run the Wishing Well AI evaluation: every case in eval/cases.json through identify-product and find-offers for one or more providers, score the results and append the run to docs/ai-eval.md. Use when asked to evaluate the AI, compare providers or models, check a prompt change, or before choosing the default provider (WISH-21, WISH-25)."
argument-hint: "Provider(s) and an optional note, e.g. 'claude openai' or 'claude prompt v3'"
---

# AI evaluation — Wishing Well

Measures how well "photo → right product → shop with a real price" works, the same way every time, so runs can be compared across providers, models and prompt versions. The method is in `docs/ai-eval.md`. The numbers are shown in the README and the docs, so they must be honest and reproducible.

The argument is: `$ARGUMENTS`

---

## Step 1 — Preconditions

- `eval/cases.json` exists and every photo it names is in `eval/photos/`. If not, stop: the set is built in WISH-21.
- Every photo shows a product only: no people, no faces, nothing from inside a private home that identifies it. Look at each new photo before the first run that uses it. A photo that breaks the rule is a 🔴 finding: stop and tell the developer.
- The runner exists: `npm run eval -- --provider <name> [--model <id>] [--note <text>]`. It calls the same `identifyProduct` and `findOffers` code as the Edge Functions, with provider keys from the developer's shell, never from the repo.
- **Claude never sets or reads the provider keys.** If the runner needs a key that is not set, print what the developer must export and stop.

---

## Step 2 — Run

For each provider in `$ARGUMENTS`:

```bash
npm run eval -- --provider <name> --note "<note>"
```

The runner writes raw results to `eval/runs/<date>-<provider>.json` (gitignored if it holds full provider responses; the scored summary is what gets committed).

If a run fails part-way (rate limit, network), rerun only the failed cases and say so in the report. Never drop a failed case from the score: a case the system could not answer counts as not recognised.

---

## Step 3 — Score

Per case, as defined in `docs/ai-eval.md`:

| Measure | Pass when |
|---|---|
| Recognised | Name and brand match the expected product (EAN when given) |
| Page found | At least one offer is a page that sells this product |
| Price read | The link reader read a price from that page |
| Cheapest right | The first offer is the cheapest of the offers with a price |
| Time | Seconds from photo to offers |
| Cost | From the token and search counts the runner logged, at the provider's current list price (note the date of the price) |

Judge "recognised" and "page found" strictly. When unsure, open the page and look; when still unsure, count it as a fail and note why.

---

## Step 4 — Write it down

Append to `docs/ai-eval.md`:

1. One row per provider in § Runs: date, provider and model, prompt version, the four pass rates as `n/N (x %)`, median time, cost per 100 photos.
2. § Results per group: the same rates per group (`brand-visible`, `brand-hidden`, `barcode`, `no-brand`), because the overall number hides where it fails.
3. Under the tables, three to five sentences: what changed since the last run, where it fails and a guess at why, what to try next.

Add a short entry to `docs/journal.md` if the run changed a decision or surprised you.

---

## Step 5 — Report back

```
## AI evaluation — <date>

| Provider / model | Recognised | Page found | Price read | Cheapest right | Median time | Cost / 100 |
|---|---|---|---|---|---|---|

Weakest group: <group> (<numbers>)
Written to: docs/ai-eval.md (§ Runs, § Results per group), journal: <yes/no>
Next: <one suggestion>
```

Do not commit. The docs change goes on the ticket's branch with `wish-git-commit`.

---

## Rules

- Same cases, same scoring, every run. Changing the set or the scoring is its own change, noted in `docs/ai-eval.md` with the date, and the old runs are not rescored silently.
- Never tune a prompt on the evaluation set and report the result as if it were unseen. If the prompt was changed to fix specific cases, say so.
- Never put provider keys, raw personal data or photos of people in the repo.
- Report failures as plainly as successes. The report is worth more for an honest 55 % than an inflated 80 %.
