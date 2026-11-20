# Wishing Well — tickets

Ordered by epic. Each epic ends with a **checkpoint**: run `/wish-epic-review`, test the app on the developer's own Android phone and in the emulator as owner, a contact who sees it and a contact who does not, and install the result on the family's phones before starting the next epic.

Ticket IDs are `WISH-<N>`, numbered in the order they are planned. This file is the plan. The live tickets are GitHub issues, imported from this file with `/wish-create-ticket import`. New tickets are created with `/wish-create-ticket`.

The schema for epics 1–3 (`supabase/migrations/20261116000000_init.sql`) and its RLS tests were written and run against Postgres 16 before epic 0, with the plan. Epics 4–5 add their own migrations.

---

## Epic 0 — Foundation

An app that runs on an Android phone with mock data, every screen in place, and the tooling that keeps quality up from the first PR.

### WISH-1 · chore · Expo app with TypeScript, Expo Router and the project tooling

**Context**
The base everything else stands on. A development build, not Expo Go, because the app will use native modules for the camera, image handling and sharing.

**Acceptance Criteria**
- [ ] AC1: Expo app on the latest stable SDK (58 when planned) created with the default TypeScript template, Expo Router with routes in `src/app/`, TypeScript `strict`
- [ ] AC2: `app.json`: name "Wishing Well", slug `wishing-well`, scheme `wishingwell`, Android package and iOS bundle identifier `se.noordh.wishingwell` (decided in `docs/decisions/0011-name-and-slogan.md`; it can never change once the app is published), and the camera and photo-library permission texts, written in English and translated to Swedish through Expo's `locales` setting (its Swedish file joins the allowlist in `scripts/check-english.sh`)
- [ ] AC3: `expo-dev-client` added; `eas.json` with profiles `development` (internal, dev client), `preview` (internal, Android APK) and `production`. The developer runs the first `eas build --profile development --platform android` and installs it on their phone (manual step; Claude prints the command)
- [ ] AC4: ESLint with the Expo config and Prettier. `npm run lint` has no errors
- [ ] AC5: Jest with `jest-expo` and React Native Testing Library. One test renders the start screen. `npm test` passes
- [ ] AC6: `npm run build` runs `expo export` for Android and iOS and passes, so CI catches bundling errors without a native build
- [ ] AC7: Folders as in `CLAUDE.md` § Code structure: `src/app/`, `src/components/`, `src/components/ui/`, `src/hooks/`, `src/lib/`, `src/lib/api/`, `src/theme/`, `src/locales/`
- [ ] AC8: `.env.example` with `EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_ANON_KEY`; `.env*.local` ignored
- [ ] AC9: `README.md` § Run locally filled in: install, start Metro, install the development build on the phone and in the emulator
- [ ] AC10: An Android emulator (Android Studio) set up with a small screen (360 dp wide) next to the developer's own phone, and the development build running in both. If a Mac is at hand: an `eas.json` profile with `ios.simulator: true` for the iOS Simulator, which needs no Apple Developer account

**Scope Boundary**
In scope: the empty app, tooling, build profiles.
Out of scope: screens, Supabase.

### WISH-2 · chore · CI green on the first pull request

**Context**
`.github/workflows/ci.yml` is in the repo from the plan commit. Its `app` and `functions` jobs wait until there is an app and a function to check. The `language` job runs from the start. This ticket makes sure all four jobs really run and fail when they should.

**Acceptance Criteria**
- [ ] AC1: The `app` job runs `npm ci`, `npm run lint`, `npx tsc --noEmit`, `npm test` and `npm run build` on every pull request and is green
- [ ] AC2: The `rls` job runs the stand-in, every migration and `rls_test.sql` (34 checks) and is green
- [ ] AC3: Proven to fail: a throwaway commit that breaks one RLS check and one lint rule makes the jobs red, then is reverted (noted in the PR, not merged)
- [ ] AC4: Branch protection on `main`: PRs only, CI must pass (manual step in GitHub settings)

**Scope Boundary**
Out of scope: end-to-end tests (epic 7).

### WISH-3 · feat · Swedish and English, and the theme

**Context**
Text, colours and sizes get one home before there are screens, so nothing is ever hardcoded (`CLAUDE.md` § No hardcoded values). Doing it now costs one ticket; doing it later means finding every value twice.

**Acceptance Criteria**
- [ ] AC1: `i18next`, `react-i18next` and `expo-localization` added (approved by this ticket). `src/locales/en.json` is the source language every string is written in first, `sv.json` its translation (`CLAUDE.md` § Language). The phone's language picks the locale; Swedish is the default and `en` the fallback
- [ ] AC2: Translation keys are typed, so a missing or misspelled key fails `npx tsc --noEmit`
- [ ] AC3: Counts use i18next plurals, never manual if/else. Dates, prices and currencies are formatted with `Intl` through one shared helper
- [ ] AC4: A test checks that `sv` and `en` have exactly the same keys and no empty values
- [ ] AC5: `app.name` is "Wishing Well" in both locales; `app.slogan` is "Ooh, I want one of those!" in `en.json`, with its Swedish translation in `sv.json`
- [ ] AC6: `lucide-react-native` and `react-native-svg` added for icons (approved by this ticket, `docs/decisions/0012-tabs-and-icons.md`); icons are 24 grid, 2 px stroke, colour from the theme
- [ ] AC7: `src/theme/` built from the design system's `tokens.json` (the design system artifact (https://claude.ai/artifact/FM4zenrV1VAiiQ1M81sn1o), `docs/decisions/0010-look-and-pictures.md`): colours for light and dark mode (following the system setting), spacing, radii, shadows and type scale, with contrast checked for text on every background
- [ ] AC8: The light background gradient (`expo-linear-gradient`) and the fonts Inter and Nunito (`@expo-google-fonts/inter`, `@expo-google-fonts/nunito`), all approved by this ticket
- [ ] AC9: `src/lib/constants.ts` exists and holds the first constants (image size, text limits matching the database checks)

**Scope Boundary**
Out of scope: translating user data, more languages.

### WISH-4 · feat · Design system: the building blocks

**Context**
A small set of components that every screen uses, so the app looks and behaves like one thing. Accessibility is built into the blocks, so screens get it for free.

**Acceptance Criteria**
- [ ] AC1: In `src/components/ui/`: `Screen`, `Button` (primary, secondary, destructive, with loading), `IconButton`, `TextField` (label, error, character count), `Card`, `ListRow`, `Chip`, `Avatar` (initials), `Sheet` (bottom sheet), `Toast`
- [ ] AC2: `src/components/States.tsx`: `Loading`, `Empty` (illustration slot, text, action) and `ErrorState` (text, retry)
- [ ] AC3: Every control has an accessibility label and role, touch targets are at least 48 dp, and text scales with the system font size without clipping
- [ ] AC4: A hidden developer screen shows every block in light and dark mode
- [ ] AC5: Component tests for `Button`, `TextField` and `States`
- [ ] AC6: `TabBar`: four tabs (Wishes, People, Reserved, Me) around the round accent camera button in the middle (`docs/decisions/0012-tabs-and-icons.md`, the design system's TabBar)

**Scope Boundary**
Out of scope: screens.

### WISH-5 · feat · Every screen with mock data

**Context**
As with Lovable in mini-ATS: the whole app first, with typed mock data behind `src/lib/api/`, so the flows can be tried on a phone and in front of the family before any backend exists. Epics 1–3 then replace the mock data ticket by ticket without touching the screens. Spec: `docs/ui-spec.md`.

**Acceptance Criteria**
- [ ] AC1: Every screen in `docs/ui-spec.md` exists with its loading, empty and error states: sign-in, onboarding, my lists, list, wish, add wish, people, invite, a person's lists, my reservations, settings
- [ ] AC2: Typed data functions in `src/lib/api/` (one file per table) backed by an in-memory mock store, wrapped in TanStack Query hooks in `src/hooks/`. Screens only use hooks
- [ ] AC3: The mock store has four people (the owner, two contacts with different shares, and a stranger) and a switcher in the developer screen to view the app as each of them. Each sees exactly what the sharing model allows; as the owner, reservations are never shown
- [ ] AC4: Adding a wish is at most two taps from the start screen to the camera
- [ ] AC5: Every screen works at 360 dp wide, in dark mode and with large system fonts (checked on a phone, screenshots in the PR)

**Scope Boundary**
In scope: all UI with mock data.
Out of scope: Supabase, the real camera upload, AI.

**Checkpoint:** the app runs on the developer's Android phone as a development build with mock data in Swedish and English, and CI is green. Show it to the partner and write down what they say in `docs/journal.md`.

---

## Epic 1 — Accounts and people

### WISH-6 · feat · Supabase project, schema and RLS

**Context**
All security rests on this. Above all: nothing is seen by someone it was not shared with, and the owner never sees a reservation.

**Acceptance Criteria**
- [ ] AC1: Supabase project created in the EU (Stockholm), because the app holds personal data
- [ ] AC2: `supabase/migrations/20261116000000_init.sql` applied to the project
- [ ] AC3: `supabase/tests/rls_test.sql` run in the SQL Editor: all 34 checks print `OK`
- [ ] AC4: `@supabase/supabase-js` added, client in `src/lib/supabase/client.ts` reading `EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_ANON_KEY`, session stored as in Supabase's Expo guide
- [ ] AC5: Types generated into `src/lib/supabase/types.ts`
- [ ] AC6: Database errors (the codes in `docs/error-codes.md`) map to translated messages through one helper, with a test

**Scope Boundary**
Out of scope: screens.

### WISH-7 · feat · Sign in with an email code

**Acceptance Criteria**
- [ ] AC1: The mock in `AuthContext` is replaced by Supabase Auth with a one-time email code (no password, no magic link, so it works inside the app without deep links)
- [ ] AC2: Code entry handles wrong, expired and resent codes with translated errors
- [ ] AC3: Signed-out people only reach sign-in; signed-in people never see it
- [ ] AC4: Sign-out clears the whole query cache (`CLAUDE.md` § How data access works)
- [ ] AC5: The session survives an app restart

### WISH-8 · feat · Profile and onboarding

**Acceptance Criteria**
- [ ] AC1: First sign-in asks for a display name (required) and a birthday (optional, year optional in the UI)
- [ ] AC2: Settings can change both
- [ ] AC3: The name is never the email address

### WISH-9 · feat · Invite contacts

**Context**
Being contacts is the only way anything can be shared, but connecting shares nothing by itself (`docs/decisions/0007-sharing-model.md`). Accepting goes through `accept_invite()` only.

**Acceptance Criteria**
- [ ] AC1: "Invite" creates an invite and opens the phone's share sheet with a link `wishingwell://invite/<code>` and a short, friendly text
- [ ] AC2: Opening the link signs in if needed, shows `preview_invite()` ("Anna wants to add you as a contact.") and lets the person accept or decline
- [ ] AC3: Every error code from `accept_invite()` has a clear translated message
- [ ] AC4: People lists my contacts and open invites (with revoke), and lets me end a contact after a confirmation that says what goes with it: their access to everything I shared, and reservations between us
- [ ] AC5: After connecting, the app says plainly that nothing is shared yet and offers to share "All" or a category
- [ ] AC6: Manual test on the phone and the emulator: invite accepted, used and expired links refused
- [ ] AC7: Block from a person's menu, after a confirmation that says what goes with it and that they are not told. Settings → Blocked lists them with "Unblock" (which brings nothing back). Manual test: after a block the other account sees nothing of mine, cannot open my invite or list link, and I am gone from their People (`rls_test.sql` check 33)

**Scope Boundary**
Out of scope: reporting someone, groups of contacts ("Family"), an https link that opens a web page when the app is not installed.

### WISH-10 · feat · Delete my account

**Context**
Both app stores require it, and it is the right thing to do.

**Acceptance Criteria**
- [ ] AC1: Edge Function `delete-account`: checks the caller, deletes the caller's folder in `wish-images`, then the Auth user with the service role (the one privileged action). Everything else goes by cascade (`rls_test.sql` check 34)
- [ ] AC2: If the photo delete fails, the account is not deleted and the error is returned; running it again finishes the job
- [ ] AC3: Settings → "Delete my account" with a confirmation that says what disappears
- [ ] AC4: Deno tests for the handler: not signed in, photo delete fails, success
- [ ] AC5: `docs/data-safety.md` § delete chains updated

**Checkpoint:** two real accounts, on the phone and in the emulator, are contacts, and a test account has been deleted cleanly.

---

## Epic 2 — Wishes, categories and sharing

The sharing model in `docs/decisions/0007-sharing-model.md`, built in the order the owner meets it.

### WISH-11 · feat · Wishes in "All"

**Acceptance Criteria**
- [ ] AC1: "All" shows every wish of mine, newest first, as cards with photo, title, price and shop
- [ ] AC2: Create, edit and delete wishes with title (required), link, price, currency (SEK default), shop and note, with the same limits as the database
- [ ] AC3: "Open in shop" opens the link in the browser
- [ ] AC4: New wishes are private: a first-time hint says so and shows how to share

### WISH-12 · feat · Categories

**Acceptance Criteria**
- [ ] AC1: Create, rename and delete categories. Suggestions on first use: Christmas, Birthday, Home decor, Kitchen, Garden
- [ ] AC2: A wish can be put in several categories, from the wish and from the category
- [ ] AC3: Category chips above "All" filter the list; the long list stays fast (virtualised) with hundreds of wishes
- [ ] AC4: Deleting a category asks for confirmation and says that its wishes stay in "All"

### WISH-13 · feat · Sharing lists and wishes

**Context**
Like sharing in Google Docs, and the heart of the app's privacy. Security rule 7.

**Acceptance Criteria**
- [ ] AC1: "Share" on "All" and on each category: "Only me" (default), "All my contacts" (one tap), "Chosen people" (checkboxes for my contacts)
- [ ] AC2: "Who can see this?" on each wish: "Same as the lists" (default, says who that is right now), "Only chosen people" (pre-filled with who sees it now, so adding Jakob does not hide it from the others), "Only me". The sheet says that this choice wins over the lists
- [ ] AC3: On my own cards, a small glass label on the photo shows who sees the wish, whichever way: "Everyone", "Bo, Cleo +2", "Only me". Tapping it opens the sheet, which also says "Via Christmas: Mum, Bo". Labels are shown only to the owner. Glass with `expo-blur` (approved by this ticket; on Android with `BlurTargetView`), and a semi-transparent fill where blur is not available
- [ ] AC4: Counts shown to others are computed only from what they can see
- [ ] AC5: Manual test, phone and emulator: share a category with one contact, override one wish to another, set one to "Only me"; each contact sees exactly what the label says
- [ ] AC6: "Anyone with the link" in "Share" (`docs/decisions/0009-links-blocks-and-search.md`): the link `wishingwell://l/<code>` with "Copy link" and "Share", "New link" with a confirmation that the old one stops working, and "Opened by" with names. The glass label says "Anyone with the link" for wishes seen that way
- [ ] AC7: Manual test: share a category by link with an account that is not a contact; it sees that list only, not an "Only me" wish in it; after "New link" it sees nothing (`rls_test.sql` checks 26–30)

### WISH-14 · feat · Photos

**Context**
The camera is the heart of the app: two taps from start to photo.

**Acceptance Criteria**
- [ ] AC1: Take a photo with the camera or pick one from the gallery (`expo-image-picker`, approved by this ticket)
- [ ] AC2: Resized to at most the size in `src/lib/constants.ts` and re-encoded to JPEG on the phone (`expo-image-manipulator`), which removes EXIF and location. A test or a manual check with a geotagged photo proves the location is gone (noted in the PR)
- [ ] AC3: Uploaded to `wish-images/<owner_id>/<uuid>.jpg`; the wish is saved first and shows the photo as "Uploading…" until done; a failed upload can be retried
- [ ] AC4: Photos are shown through signed URLs that are refreshed when they expire, with a placeholder while loading
- [ ] AC5: Deleting a wish or changing its photo deletes the old file (photo first, then the row, so a failure never leaves a row pointing at nothing)
- [ ] AC6: Screenshots are a first-class source: the gallery picker opens on recent images, and a screenshot of a shop page works as well as a photo (most wishes will come from window-shopping on the phone)

**Checkpoint:** the owner adds wishes with photos and categories on the phone, shares one category and overrides one wish; a contact in the emulator sees exactly that and nothing else.

---

## Epic 3 — Contacts' wishes and reservations

### WISH-15 · feat · A contact's wishes

**Acceptance Criteria**
- [ ] AC1: People → a person → "All I can see" and the categories shared with me, read-only, as RLS allows. Nothing hints at what I cannot see
- [ ] AC2: Birthday shown with "Birthday in 12 days" when known
- [ ] AC3: Pull to refresh, and the screen handles losing access while open (a share taken back, a contact ended, a new link, a block)
- [ ] AC4: Opening a list link (`wishingwell://l/<code>`) signs in if needed, calls `open_list_link()` and shows that list in the same screen, with reserving. `link_not_found` shows one message for every reason. Lists opened by link stay reachable from People under the owner's name

### WISH-16 · feat · Reserve and unreserve

**Context**
The promise of the app: no duplicate gifts, and no spoiled surprises. Security rule 1.

**Acceptance Criteria**
- [ ] AC1: On someone else's wish: "I'll buy it" reserves it, "Undo" removes my reservation
- [ ] AC2: Others see "Reserved" (with the name when they know the person); the owner sees nothing different, anywhere in the app
- [ ] AC3: Two people reserving at once: the second gets a clear "Someone got there first" message (unique violation mapped to `already_reserved`)
- [ ] AC4: Query keys and caches are checked so that switching accounts on one phone never shows reservations to the owner
- [ ] AC5: Manual test with three accounts (phone, emulator, and a second emulator or another phone): one contact reserves, another who sees the wish sees it reserved, the owner sees nothing

### WISH-17 · feat · My reservations

**Acceptance Criteria**
- [ ] AC1: A tab with everything I have reserved, grouped by person, with link and price, as a shopping list
- [ ] AC2: Mark as bought (stored on the phone in v1) and remove a reservation from here

**Checkpoint:** with three accounts, one contact reserves, another sees it reserved, and the owner sees nothing.

---

## Epic 4 — Add from a link

### WISH-18 · feat · Edge Function `import-link`

**Context**
Reads name, image, price and currency from a shop page, the way GoWish does when you paste a link. The same reader later checks prices for AI suggestions (`docs/decisions/0004-prices-from-the-page.md`). Security rule 10 applies in full.

**Acceptance Criteria**
- [ ] AC1: Accepts only signed-in callers and `https` URLs; refuses IP literals, `localhost` and private, loopback and link-local ranges; follows at most 5 redirects by hand, checking each; times out and stops reading at the limits in its constants
- [ ] AC2: Reads schema.org `Product`/`Offer` JSON-LD first, then Open Graph and `<title>`; returns `{ title, imageUrl, price, currency, storeName, url }` with only what it found
- [ ] AC3: Deno tests with saved HTML from at least five Swedish shops and every refusal in AC1
- [ ] AC4: Errors are codes (`link_not_allowed`, `link_unreachable`, `link_unreadable`)

### WISH-19 · feat · Paste a link

**Acceptance Criteria**
- [ ] AC1: Add → "Paste link" fills the form from `import-link`; the user can change everything before saving
- [ ] AC2: The product image can be saved as the wish's photo (downloaded, re-encoded and uploaded like a camera photo)

### WISH-20 · feat · Share a link to the app

**Acceptance Criteria**
- [ ] AC1: The app appears in Android's share sheet for links and images (`expo-sharing` share receiving, approved by this ticket); a shared link opens Add with the link imported, a shared image (a screenshot) opens it with the image as the photo
- [ ] AC2: Works when the app was closed and when it was open
- [ ] AC3: iOS share receiving is configured but marked experimental in the README

**Checkpoint:** a product link shared from Chrome becomes a wish with name, image and price.

---

## Epic 5 — From photo to the cheapest shop

The part that makes the app more than a GoWish copy, and the part most worth showing: does it work, how well, and at what cost? Everything here is measured with `/wish-ai-eval`.

### WISH-21 · spike · AI evaluation set and harness

**Context**
Before building the feature, find out how well it can work. The test set and the numbers go into `docs/ai-eval.md`.

**Acceptance Criteria**
- [ ] AC1: `eval/cases.json` with at least 20 cases: a product photo (`eval/photos/`, products only, no people, at most 300 KB each), what it is (name, brand, EAN when known) and at least one shop page that sells it
- [ ] AC2: A mix: branded products with the name visible, branded without, packaging with a barcode, and things without a brand
- [ ] AC3: `npm run eval -- --provider <name>` runs every case through `identifyProduct` and `findOffers` and writes a results table to `docs/ai-eval.md`: recognised, right product page found, price readable from the page, time and cost per case
- [ ] AC4: Run against at least two providers (for example Claude and OpenAI). Results and a recommendation in `docs/ai-eval.md` and a journal entry

### WISH-22 · feat · Edge Function `identify-product`

**Acceptance Criteria**
- [ ] AC1: The AI layer in `supabase/functions/_shared/ai/`: one interface, providers chosen by `AI_PROVIDER` and `AI_MODEL` secrets, at least two providers implemented
- [ ] AC2: Takes the photo's storage path (the caller must be able to read it) and returns `{ name, brand, model, category, ean, searchPhrase, confidence }`, validated with zod
- [ ] AC3: The prompt treats text in the photo as data; a photo of a note saying "ignore your instructions" returns a normal answer (a test with a recorded response)
- [ ] AC4: Deno tests with recorded provider responses; no network in tests

### WISH-23 · feat · Edge Function `find-offers`

**Acceptance Criteria**
- [ ] AC1: Uses the provider's web search (location Sweden) to find candidate product pages for a search phrase
- [ ] AC2: Reads each candidate with the `import-link` reader; a candidate whose price cannot be read is shown without a price, never with the AI's guess (security rule 11)
- [ ] AC3: Returns offers sorted cheapest first, each with shop, price, currency, link and `source`
- [ ] AC4: A migration adds `wish_offers` (or the shape the ticket decides) with RLS, grants and checks in `rls_test.sql`; offers are visible to whoever sees the wish
- [ ] AC5: Before merge: the chosen provider's terms checked for storing and showing search results to other users, noted in `docs/decisions/0003-ai-provider.md`

### WISH-24 · feat · Add a wish from a photo

**Acceptance Criteria**
- [ ] AC1: After the photo, the wish is saved at once with a "Looking for prices…" state; suggestions arrive without blocking the user
- [ ] AC2: "Is this right?" sheet: the suggested name and the offers, cheapest first; one tap to accept, everything editable
- [ ] AC3: "Search yourself" opens the browser with the search phrase
- [ ] AC4: Works when the AI or the search fails: the wish keeps its photo and title, with a calm message
- [ ] AC5: "Change picture" on the owner's wish: use the shop's own product image from an offer the owner picked. The image is fetched by the SSRF-safe reader (security rule 10: size and type checked, nothing followed off the shop's site), re-encoded and stored in the owner's folder like a photo. The owner's own photo is kept until they choose (`docs/decisions/0010-look-and-pictures.md`)

### WISH-25 · docs · Choose the default AI provider

**Acceptance Criteria**
- [ ] AC1: `/wish-ai-eval` run for the final prompt against every implemented provider
- [ ] AC2: `docs/decisions/0008-default-ai-provider.md` with the numbers: accuracy, price found, time, cost per 100 photos
- [ ] AC3: The default set in the Supabase secrets (the developer runs the command)

**Checkpoint:** in the evaluation set, the share of photos where the app suggests the right product and at least one shop with a price read from its page is measured, written down and shown on a phone.

---

## Epic 6 — Ready for the family

### WISH-26 · chore · Install on the family's phones

**Acceptance Criteria**
- [ ] AC1: Android Developer Console "limited distribution" account (free, up to 20 phones), or Play Console internal testing if that is simpler when the time comes (manual step, decision noted in the journal)
- [ ] AC2: `eas build --profile preview --platform android` builds a signed APK (the developer runs it), installed on at least three family phones
- [ ] AC3: Version and build numbers come from one place, and the app shows its version in Settings
- [ ] AC4: `eas update` channel set up for the preview build, so JS-only fixes reach the phones without a new install (the developer runs it)

### WISH-27 · feat · First impression

**Acceptance Criteria**
- [ ] AC1: App icon and splash screen for "Wishing Well"; the icon label reads "Wishing Well" in full on a 360 dp launcher
- [ ] AC2: Empty states that teach: the first list, the first wish (with the slogan `app.slogan`, `docs/decisions/0011-name-and-slogan.md`), no contacts yet, nothing shared yet
- [ ] AC3: A short onboarding (three screens at most) that ends at the camera

### WISH-28 · docs · README and screenshots

**Acceptance Criteria**
- [ ] AC1: README with what the app does, screenshots, architecture, how it is built (honestly: Claude Code writes the code, the developer steers, tests and sets the rules), security and how to run it
- [ ] AC2: Demo data with made-up people for screenshots; no real family data anywhere in the repo

**Checkpoint:** the family uses the app for a real occasion (a birthday or Christmas), and what happened is in the journal.

---

## Epic 7 — Safety net (planned, not yet broken into tickets)

- End-to-end tests with Maestro for sign-in, add wish, invite, reserve; run in CI or EAS Workflows.
- Our own SMTP for the email codes, so sign-in does not hit Supabase's default email limits.
- Error reporting without personal data.

## Later (ideas, not planned)

- Reminders before a connection's birthday (push).
- Price watch: a notice when a wished item gets cheaper.
- "Make the picture nicer": remove the background of the owner's photo or screenshot (on the phone or in an Edge Function), so a messy shop photo looks like a product shot.
- An AI illustration when no usable picture exists: the AI says what the thing is (or asks the owner), and an image model draws one. Always tagged "AI image" on the card for everyone, so nobody buys from a drawing. Costs per image; measure in `/wish-ai-eval` first.
- Prisjakt as a second price source, if partner access is granted.
- iPhone build through the Apple Developer Program and TestFlight.
- A web view of a list for people without the app (a read-only page for a link, through an Edge Function).
- Searchable profiles: a screen for `handle`, "Let others find me" and search (`search_profiles()` is ready and tested, check 32). Decide what a found person may do (send an invite?).
- Public lists on a profile (`share = 'public'` is ready and tested, check 31). Decide first whether the birthday is shown to people who only see a public list.
- Reporting a person or a list, once anything is public.
- Google Play release (a new personal account needs a closed test with 12 testers for 14 days first).
- Where the photo was taken as a hint ("seen at …"), opt-in.

---

## Found while building

Small problems and improvements noticed while working on a ticket but outside its scope. Add one line per finding as soon as it is found, with the ticket where it was found. At each epic checkpoint the list is triaged and emptied: a finding becomes an extra AC on the open ticket that touches the same code, or goes into one hygiene ticket for the epic, or is dropped. `/wish-epic-close` does the triage and records where each line went in `docs/review-epic-<N>.md`.

Format: `- [ ] <What is wrong or could be better> — <file or screen> (found in WISH-<N>)`


## Found while reviewing PRs

Findings from `/wish-review-pr`. Blockers and real bugs are fixed on the branch before the merge; they do not go here. Small things get one line each, so they are not forgotten. They are triaged at the epic checkpoint like the list above.

Format: `- [ ] <What could be better> — <file> (PR #<n>, WISH-<N>)`
