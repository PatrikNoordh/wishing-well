# Journal

The project diary. One short entry when a ticket teaches something, a decision is made or something goes wrong — material for the README and the portfolio. Newest first.

Format:

```
## YYYY-MM-DD — <ticket or topic>
**What happened:** …
**What I learned / decided:** …
**Next:** …
```

---

## 2026-11-24 — WISH-2: CI that fails when it should
**What happened:** CI was already green, so the work was proving it can go red. A throwaway commit let the owner see reservations on their own wishes and added an unused variable. The RLS job stopped at check 19 ("owner sees reservations"), but the lint step would have passed: `expo lint` exits 0 on warnings. It now runs with `--max-warnings 0`. The `app` job also lost its "skip without a `package.json`" guard from before the app existed, which would have shown green with nothing checked. Branch protection then failed with a 403: GitHub Free only protects branches on public repos. The repo was made public after a scan of every file version, issue and PR for keys and personal data found none.
**What I learned / decided:** Green only means something once you have seen red. A guard written for the time before something exists has to go when it arrives, or it turns into a silent pass. `main` now takes changes only through a PR with all four jobs green, for the admin too.
**Next:** WISH-3, Swedish and English, and the theme.

## 2026-11-21 — WISH-1: the Expo app
**What happened:** Created the app from the SDK 58 default template, kept only the 12 of its 23 runtime dependencies that an empty Expo Router app needs, and added a development build, ESLint with Prettier, Jest with React Native Testing Library, and EAS profiles. Three surprises: npm refused to install the test tooling until `react-dom` was pinned to React's exact version (an optional web peer of Expo Router); TypeScript 6 no longer loads `@types/*` packages by itself, so the Jest globals are named in `tsconfig.json`; and in Jest `expo-constants` has no app config, so the start-screen test feeds it `app.json`.
**What I learned / decided:** A template is a demo as much as a starting point: every dependency left in is one more thing to build, update and explain. The permission texts are written in English, and Expo's `locales` setting carries the Swedish ones into the iOS build; Android shows its own system dialog. An `expo prebuild` in a scratch folder showed both in the generated projects before any build credit was spent.
**Next:** The first development build on the phone, then WISH-2.

## 2026-11-20 — English as the working language
**What happened:** The docs, tickets and skills named the UI by its Swedish labels, while everything else was in English. Rewrote them all in English, with a glossary of UI terms (en → sv) in `docs/ui-spec.md`, made `en.json` the language every string is written in first, and added `scripts/check-english.sh` and a `language` CI job that fail on Swedish letters outside `sv.json` and a short allowlist. The RLS test data is in English now too.
**What I learned / decided:** The language users start in (Swedish) and the language the project is written in (English) are two separate choices. The first version of the check passed everything, because the allowlist variable never reached perl; a check is only trusted once it has been seen to fail.
**Next:** Start WISH-1.

## 2026-11-19 — App id, tabs and icons
**What happened:** Chose the app id `se.noordh.wishingwell` (0011), four tabs around the camera and Lucide icons (`docs/decisions/0012-tabs-and-icons.md`).
**What I learned / decided:** The app id is the one name that can never change, so it was decided before the first build, not during it.

## 2026-11-19 — Slogan per language, and a portfolio project
**What happened:** The slogan follows the app language (`app.slogan`): "Ooh, I want one of those!" in English, with its Swedish translation in `sv.json`. The app is the developer's own portfolio project, not the degree project, but it is still built as a real product to be released.
**What I learned / decided:** The old name found its place as the Swedish slogan. Without a degree deadline the order of the epics stays, but the pace follows LIA and the course.

## 2026-11-19 — New name: Wishing Well
**What happened:** Renamed the app from "Åh, en sån vill jag ha" to Wishing Well, and the repo from `ah-en-san` to `wishing-well`, before the repo exists (`docs/decisions/0011-name-and-slogan.md`). The old joke lives on as a slogan: "Ooh, I want one of those!".
**What I learned / decided:** A name has to survive an icon label, a search box and two languages. Personality can live in a slogan instead. Renaming before the first commit cost one search and replace; the package identifier is the one name that can never change later, so it waits for a deliberate choice.
**Next:** Decide the bundle identifier and the Swedish slogan, then create the repo and start WISH-1.

## 2026-11-18 — PawPals look, and pictures
**What happened:** Built a clickable prototype (Design artifact) with the first warm design and three light variants, then a fourth in the colours of PawPals, an earlier app built with classmates. Chose the PawPals look; the design system now uses it (`docs/decisions/0010-look-and-pictures.md`).
**What I learned / decided:** Real product photos changed what looked right: the interface should be quiet and let the products be the colour. Most wishes will start as screenshots from shopping online. A bad picture is best replaced by the shop's own image of the exact product; an AI-drawn image is a last resort and must say so, since a gift giver could buy from a drawing.
**Next:** Create the repo and start WISH-1.

## 2026-11-16 — Links, blocks, and preparing for search
**What happened:** Added "Anyone with the link" as a fourth way to share a list, blocking, and the schema for searchable profiles and public lists before there is a screen for them (`docs/decisions/0009-links-blocks-and-search.md`). 8 new RLS checks (34 in all). 21 of the new guards were broken on purpose; 19 were caught at once. The two that survived are block checks that a block already makes redundant on every other path, so they stay as a second layer and are written down as such.
**What I learned / decided:** Preparing the data model costs little while there are no users, and a column on a table with real data costs a lot later. A link needs an account, because "take it back" only works if you know who opened it. Being findable must not open anything but a name, otherwise search would leak birthdays.
**Next:** The design system in the warm style, then the screens.

## 2026-11-16 — Sharing like Google Docs

**What happened:** Showed the first model (partner and friends as roles, a visibility per list) to the first users, and it did not match how they think. They want to pick people, keep one long list with categories, share a whole category in one tap, and still hide a single wish from everyone but one person. Also chose the name "Åh, en sån vill jag ha" and a warm, playful look (peach, coral, cream) after comparing three AI-generated mockups.

**What I learned / decided:** Rebuilt the schema around folders and files: "All" and categories are lists that can be shared, a wish follows its lists unless it overrides them, and everything starts private (`docs/decisions/0007-sharing-model.md`). All visibility now goes through two functions, which made the rules easier to test: 26 RLS checks, and every guard in them was broken on purpose once. One guard survived at first (that every path needs a current connection), so a test was added that plants a leftover choice and proves a former contact still sees nothing.

**Next:** The design system, then the repo.

---

## 2026-11-15 — The idea, research and the plan

**What happened:** The idea came from a real moment: seeing something in a shop and wanting to save it without hunting for a link. Researched the market and the technology before writing any code.

- GoWish dominates wish lists in Sweden (close to one million registered Swedish users) but is built around links from web shops. Photo-first apps exist (Trove, Klarna's Shopping Lens), but none combine a photo, the cheapest shop and a shared list with secret reservations.
- Location as a hint turned out to be weak: Android's photo picker strips location by default, and most gifts are ordered online anyway. Dropped for v1 (`docs/decisions/0005-no-location-in-v1.md`).
- Google's search grounding for Gemini does not allow storing links or showing results to other users, which is exactly what a shared wish list does. The AI is kept behind one interface and prices are read from the shop's own page (`docs/decisions/0003-ai-provider.md`, `0004-prices-from-the-page.md`).
- Swift was ruled out: the family uses Android. Flutter was ruled out: it is Dart, and the rest of the stack is TypeScript (`docs/decisions/0001-expo-react-native-typescript.md`).

**What I learned / decided:** Build the plan, the rules and the schema first, the same way as mini-ATS. The schema and its RLS checks were written and run on Postgres 16 before any app code, and each key guard was broken on purpose once to see its check fail.

**Next:** Create the repo, import the tickets, start WISH-1.
