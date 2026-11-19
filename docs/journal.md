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

## 2026-11-19 — App id, tabs and icons
**What happened:** Chose the app id `se.noordh.wishingwell` (0011), four tabs around the camera and Lucide icons (`docs/decisions/0012-tabs-and-icons.md`).
**What I learned / decided:** The app id is the one name that can never change, so it was decided before the first build, not during it.

## 2026-11-19 — Slogan per language, and a portfolio project
**What happened:** The slogan follows the app language: "Åh, en sån vill jag ha!" in Swedish, "Ooh, I want one of those!" in English (`app.slogan`). The app is the developer's own portfolio project, not the degree project, but it is still built as a real product to be released.
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
**What happened:** Added "Alla med länken" as a fourth way to share a list, blocking, and the schema for searchable profiles and public lists before there is a screen for them (`docs/decisions/0009-links-blocks-and-search.md`). 8 new RLS checks (34 in all). 21 of the new guards were broken on purpose; 19 were caught at once. The two that survived are block checks that a block already makes redundant on every other path, so they stay as a second layer and are written down as such.
**What I learned / decided:** Preparing the data model costs little while there are no users, and a column on a table with real data costs a lot later. A link needs an account, because "take it back" only works if you know who opened it. Being findable must not open anything but a name, otherwise search would leak birthdays.
**Next:** The design system in the warm style, then the screens.

## 2026-11-16 — Sharing like Google Docs

**What happened:** Showed the first model (partner and friends as roles, a visibility per list) to the first users, and it did not match how they think. They want to pick people, keep one long list with categories, share a whole category in one tap, and still hide a single wish from everyone but one person. Also chose the name "Åh, en sån vill jag ha" and a warm, playful look (peach, coral, cream) after comparing three AI-generated mockups.

**What I learned / decided:** Rebuilt the schema around folders and files: "Allt" and categories are lists that can be shared, a wish follows its lists unless it overrides them, and everything starts private (`docs/decisions/0007-sharing-model.md`). All visibility now goes through two functions, which made the rules easier to test: 26 RLS checks, and every guard in them was broken on purpose once. One guard survived at first (that every path needs a current connection), so a test was added that plants a leftover choice and proves a former contact still sees nothing.

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
