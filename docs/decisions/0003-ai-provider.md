# 0003 — The AI behind one interface, and no Google search grounding

- **Status:** accepted
- **Date:** 2026-11-15

## Context

Two AI tasks: recognise a product in a photo, and find shop pages that sell it. Several providers can do both (OpenAI, Anthropic Claude, xAI Grok, Google Gemini). They differ in accuracy, price, speed and terms, and they change often.

The terms matter as much as the quality. A wish stores a shop link and shows it to the contacts the owner shares it with.

What the providers' documentation said on 2026-11-15:

| Provider | Web search: display requirement | Storing links, showing to others |
|---|---|---|
| Google Gemini, grounding with Google Search | Google's search suggestions must be shown with the result | The 2025 terms allow storing the text of a result but not its links, and showing results only to the user who asked. **Does not fit a shared wish list.** |
| OpenAI, `web_search` | Sources shown as prominent, clickable links | Not addressed in the tool guide |
| Anthropic Claude, web search | Citations shown when the output is shown to users | Not addressed on the tool page; see the commercial terms |
| xAI Grok, `web_search` | Responses carry citations | Not checked |

Gemini without search (recognising a photo) is not affected.

## Decision

- One interface in `supabase/functions/_shared/ai/`: `identifyProduct(photo)` and `findOffers(searchPhrase)`. Providers are adapters, chosen by the secrets `AI_PROVIDER` and `AI_MODEL`.
- Google search grounding is not used for finding offers.
- The default provider is chosen by measurement (`docs/ai-eval.md`, WISH-25, decision 0008).
- Before the offers feature merges (WISH-23), the chosen provider's commercial terms are read for storing and showing search results to other users, and the result is added here.

## Consequences

- Switching provider is a configuration change, and the evaluation can compare providers on the same photos.
- Each adapter needs its own tests with recorded responses.
- A shown price never comes from the AI (decision 0004), so a provider's mistakes cost a missed offer, not a wrong price.
