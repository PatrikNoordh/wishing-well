# 0011 — The name Wishing Well, and a slogan

- **Status:** accepted
- **Date:** 2026-11-19
- **Replaces:** the name "Åh, en sån vill jag ha" / "Åh, en sån" and the repo name `ah-en-san`

## Context

The first name, "Åh, en sån vill jag ha", carried the app's wink, but it worked badly as a name:

- Too long for an Android icon label; even the short form "Åh, en sån" gets cut or crowded.
- Hard to type and search for: the å, the comma and the apostrophe people add ("Åh', en sån") all break search in stores and on GitHub.
- Swedish only, while the app has English as its second language and may be released more widely.

The repo has not been created yet, so changing now costs a search and replace, not a migration.

## Decision

- The app is called **Wishing Well**, in both Swedish and English. The name is never translated.
- The repo is `wishing-well`. Expo slug `wishing-well`, deep-link scheme `wishingwell://`.
- The personality lives in a slogan that follows the app language through the string `app.slogan`: **"Ooh, I want one of those!"** in `en.json`, with its Swedish translation in `sv.json`. It is used only where a slogan belongs: the sign-in screen, the store listing, and the empty "no wishes yet" screen. Not on every screen.
- Unchanged: the ticket prefix `WISH-<N>`, the `wish-…` skills, and the branch and commit conventions. They still fit.
- The Android package and iOS bundle identifier are `se.noordh.wishingwell`: reverse-domain form with the developer's surname, unique in the stores. It can never change once the app is published, and it stays even if the app later moves to a company account.

## Alternatives

| Option | Why not |
|---|---|
| Keep "Åh, en sån vill jag ha" | The problems above; the joke is kept as the Swedish slogan instead |
| A Swedish name and an English name | Two names to keep apart in stores, screenshots and links; one untranslated name is simpler for an app whose users start in Swedish |
| A made-up brand word | Says nothing about what the app does; "Wishing Well" is about wishes and reads well in Swedish too |

## Consequences

- Every file in the repo uses Wishing Well; the journal keeps the old name where it records what happened then.
- Invite and list links are `wishingwell://invite/<code>` and `wishingwell://l/<code>`.
- The design system and prototype artifacts still carry the old title until renamed; their links do not change.
- The Swedish store listing uses the Swedish slogan, the English listing the English one. The old name lives on as the Swedish slogan.
