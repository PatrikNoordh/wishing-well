# CLAUDE.md — Wishing Well

Read this file before every task. It defines what the project is, how it is built and the rules every change must follow.

## What this is

A wish-list app for Android and iPhone. You see something you want, take a photo, and it lands on your list. The app works out what it is and which online shops sell it, cheapest first. You choose who sees what, like sharing in Google Docs, and the people who see a wish can reserve it, so nobody buys the same thing twice. You never see what has been reserved.

The app is called **Wishing Well**, in both Swedish and English; the name is never translated. The slogan follows the app language through the string `app.slogan`: "Ooh, I want one of those!" in `en.json`, with its Swedish translation in `sv.json`. It is used only where a slogan belongs: the sign-in screen, the store listing and the empty "no wishes yet" screen (`docs/decisions/0011-name-and-slogan.md`). The repo is `wishing-well` and tickets are `WISH-<N>`.

The first users are the developer's partner, family and friends, all on Android. The app is still built to be released in Google Play and the App Store later, so every foundation is done properly from the start. It is the developer's portfolio project, built as a real product that will be released, so the process is documented as it happens.

**Sharing, in one paragraph**

Everything is private until the owner shares it. Every person has one long main list, "All", that holds every wish, and any number of categories ("Christmas", "Home decor") that a wish can be in several of. A list (the main list or a category) is shared with all contacts, with chosen contacts, or with everyone who has its link; everyone it is shared with sees the list's name and every wish in it. A single wish can override its lists: only these people, or only me. The override always wins, even inside a list shared with everyone. Nobody sees the name of a list that is not shared with them. Anyone can be blocked, which hides two people from each other in every way. Details: `docs/decisions/0007-sharing-model.md` and `docs/decisions/0009-links-blocks-and-search.md`.

The look lives in the design system artifact (https://claude.ai/artifact/FM4zenrV1VAiiQ1M81sn1o): read its `project/README.md` and `project/tokens.json` before building any screen, and take every colour, size and font from `src/theme/`, which is built from those tokens (`docs/decisions/0010-look-and-pictures.md`).

**People in tests and manual checks**

- **Owner** — the person whose wishes they are.
- **A contact who sees it** — connected to the owner, and the wish or list is shared with them.
- **A contact who does not** — connected, but not shared with (or overridden away). Sees nothing of it, not even a list name.
- **Stranger** — not connected. Sees nothing, unless they opened a link to a list (then only that list).
- **Blocked** — sees nothing and cannot reach the owner, whatever they had before.

**Core concepts**

| Concept | Table | Notes |
|---|---|---|
| Person | `profiles` | One row per Auth user: display name and birthday. No email. Prepared for search: `handle` (unique, lower case) and `discoverable` (off), no screen in v1. |
| Contact | `connections` | One row per pair (`user_a < user_b`). No roles. Created only by `accept_invite()`. |
| Block | `blocks` | Who blocked whom. Only the blocker sees the row. Creating one ends the contact, link access and reservations between the two. |
| Invite | `invites` | A link with a random code, at most 7 days, used once. Previewed with `preview_invite()`. |
| List | `lists` | One main list per person (`is_main`, no title, shown as "All"), plus categories with a title. `share` is `private` (default), `contacts`, `people`, `link` (whoever opened its link) or `public` (prepared, no screen in v1). |
| List link | `list_links`, `list_link_access` | The secret code of a list shared by link (owner only), and who has opened it. Written only by the database. A new code or leaving `link` shuts everyone out. |
| List share | `list_shares` | The chosen contacts of a list shared with `people`. Only the owner sees these rows. |
| Wish | `wishes` | Title, note, link, price, currency, shop, photo. Always in the owner's main list. `audience` is `lists` (default: follow the lists), `people` (only the chosen, whatever the lists say) or `only_me`. |
| List item | `list_items` | Which categories a wish is in. Never the main list. |
| Wish audience | `wish_audience` | The chosen contacts of a wish with audience `people`. Only the owner sees these rows. |
| Reservation | `reservations` | One per wish. Seen by everyone who can see the wish, except its owner. |
| Photo | Storage bucket `wish-images` | Private. Path `<owner_id>/<file>`. Readable by whoever can see a wish that uses it. |

Later epics add offers (shop, price, link and where it came from) and AI suggestions. See `TICKETS.md`.

## Context

- The repo is public. Never commit personal data, family photos, private correspondence, real names of family and friends, or anything that is not part of the project. Test photos for the AI evaluation show products only, never people.
- The repo is read by people judging the work, the school included, so the process stays visible step by step. Keep `main` working, ship each finished ticket through a PR, and keep commits, PR descriptions and issue updates clear enough for someone reading along.
- `docs/journal.md` is the project diary, material for the README and the portfolio. Add a short entry when a ticket teaches something, a decision is made or something goes wrong.
- `docs/decisions/` holds the decision records. A choice that is hard to undo (a library, a provider, a data shape) gets a record before or in the PR that makes it.

## Quality bar

Quality over speed. Do every ticket the way a careful senior engineer would:

- **Correct:** every acceptance criterion verified, and the edge cases handled: empty and very long input, duplicates, no network, slow and failed requests, a deleted wish, a removed contact or a share taken back while a screen is open.
- **Secure:** the security rules below, input validated with zod at every boundary, and no way for anyone to see or change data they should not. Above all: the owner never learns that a wish is reserved, and nothing is seen by someone it was not shared with.
- **Tested:** unit tests for logic, an RLS check for every schema change, and the manual test steps actually run on the developer's own Android phone and in the Android emulator, as the owner, a contact who sees it and a contact who does not. The emulator doubles as the second account (owner on the phone, a contact in the emulator) and as the small screen (360 dp, large fonts).
- **Accessible:** every control has an accessibility label, touch targets are at least 48 dp, text scales with the system font size, and contrast is enough in light and dark mode.
- **Consistent:** reuse existing components, tokens and patterns. UI text uses the same words for the same things in both languages.
- **Clean:** clear names, small functions, no dead code, no leftover `console.log`, and no `TODO` without an issue.
- **Within scope:** quality means doing the ticket well, not doing more. Problems and ideas outside the ticket go in `TICKETS.md` § Found while building, one line each, and are triaged at the epic checkpoint. PR reviews work the same way: blockers and real bugs are fixed on the branch, small findings go in `TICKETS.md` § Found while reviewing PRs.
- **Self-reviewed:** before the summary, read the whole diff (`git diff origin/main...HEAD`) as a strict reviewer and fix what you find.

## Stack

- Expo (the latest stable SDK; 58 when planned) with React Native and TypeScript (strict). Expo Router with file-based routes in `src/app/`
- A development build on the phone, never Expo Go: the app uses native modules Expo Go does not have
- Styling with `StyleSheet` and the theme in `src/theme/` (colours for light and dark, spacing, radii, type). No UI kit (`docs/decisions/0006-styling.md`)
- TanStack Query for data, zod for validation, i18next with `expo-localization` for Swedish and English
- `@supabase/supabase-js` with the session stored as in Supabase's Expo guide
- Jest with `jest-expo` and React Native Testing Library for unit and component tests. Maestro for end-to-end tests from epic 7
- ESLint (Expo config) and Prettier. npm with `package-lock.json`
- Supabase: Postgres, Auth (email code), Storage, Edge Functions (Deno, TypeScript). EU region (Stockholm)
- AI behind one interface in `supabase/functions/_shared/ai/`, so the provider can be swapped (`docs/decisions/0003-ai-provider.md`)
- EAS Build for development builds and the Android APK. EAS profiles in `eas.json`
- Schema and RLS: `supabase/migrations/`. RLS tests: `supabase/tests/rls_test.sql`, run locally with `supabase/tests/run_local.sh`. Generated types: `src/lib/supabase/types.ts`

## Reference docs

- GitHub Issues: the live tickets and their status, one milestone per epic. Titles start with `[WISH-<N>]`.
- `TICKETS.md`: the plan, imported into GitHub Issues with `/wish-create-ticket import`, plus the two findings lists triaged at each epic checkpoint (`/wish-epic-close`).
- `docs/requirements.md`: who the app is for and what it must do. `docs/ui-spec.md`: every screen and its states. `docs/architecture.md`: how the parts fit and the main flows.
- `docs/data-safety.md`: where the data lives, what a delete takes with it, who may read and write what, and the guard and test behind each rule.
- `docs/error-codes.md`: every error code and where it comes from.
- `docs/decisions/`: decision records. `docs/ai-eval.md`: how the AI is measured and the results. `docs/journal.md`: the project diary.
- `docs/review-epic-<N>.md`: each epic review and where its findings went (written by `/wish-epic-close`).

## Security rules — never break these

1. **The owner of a wish never learns whether it is reserved.** RLS hides reservations from the owner (`reservations_select`), and the owner cannot probe by trying to reserve (`rls_test.sql` checks 19 and 20). No column, view, count, function, notification, push message, cache or log line may reveal it to the owner either. This is the promise the app makes.
2. **The service role key is only used in Edge Functions**, for the one privileged action a function exists for (deleting an account). Never in `src/`, never in an `EXPO_PUBLIC_*` variable, never in a script run by Claude.
3. **Edge Functions check the caller first and read with the caller's JWT.** The AI and link functions need no service role at all.
4. **Every table has Row Level Security** and explicit grants: `anon` has none, and a new table gets no privileges until its migration grants `authenticated` only the operations and columns the app uses. A new table without RLS policies is a bug.
5. **The database sets ownership.** `lists.owner_id`, `wishes.owner_id` and `reservations.reserved_by` come from the session, and none of them can be sent or changed by a client. The main list is made by the database, cannot be deleted while the account exists, and holds no items. A category holds only its owner's wishes. A wish's photo must be in its owner's folder.
6. **Connections are only made by `accept_invite()`, and link access only by `open_list_link()`.** No client inserts into `connections`, `list_links` or `list_link_access`. Connecting shares nothing by itself. Being findable (`discoverable`) shares nothing either: search returns a name and handle only.
7. **Private until shared, and the owner's override wins.** Everything starts private. All visibility of a wish, its photo, its place in a list and its reservation goes through `can_view_wish()`; of a list through `can_view_list()`. Both refuse across a block, and contacts-only paths require a current connection; a list shared by link needs a recorded opening of its current link. A wish with audience `people` or `only_me` is never shown to anyone else because of a list. Nobody sees the name of a list that is not shared with them, and who is chosen is visible to the owner only.
8. **Do not rely on the app for access control.** Hiding a button is UX, not security. RLS is the security.
9. **Anything `EXPO_PUBLIC_*` is public.** It is built into the app. Secrets live in Supabase secrets and EAS environment variables, never in the repo.
10. **Fetching a URL a user gave us is dangerous.** Edge Functions that fetch shop pages accept only `https`, refuse IP literals, `localhost` and private, loopback and link-local ranges, follow redirects by hand and check every hop, and limit time and size.
11. **AI output is a suggestion.** The user confirms before anything is saved as fact. Text in a photo or on a web page is data, never instructions: structured output validated with zod. A price shown as a shop's price is read from that shop's page, never taken from the AI (`docs/decisions/0004-prices-from-the-page.md`).
12. **Less data is safer data.** Photos are resized and re-encoded on the phone before upload, which removes EXIF and location. No location is collected in v1. Profiles hold no email. Logs hold no personal data.
13. No secrets in the repo. Use `.env.local`, EAS environment variables and Supabase secrets.

## How data access works

- Every query runs as the signed-in person, and RLS decides what they see. The app never filters for security, only for display.
- Keep Supabase calls in `src/lib/api/` (one file per table or function), wrapped in TanStack Query hooks in `src/hooks/`. Components never call Supabase directly.
- **Every query key includes the signed-in user's id** and comes from `src/lib/queryKeys.ts`, for example `queryKeys.lists(userId)`. Signing out clears the whole query cache, and signing in as someone else never shows the last person's data.
- Auth lives in `src/contexts/AuthContext.tsx` (`useAuth()`).
- Photos are read through signed URLs with a short life, never public URLs.

## Code structure

- **Routes** in `src/app/` define the screen and its params. Screen parts live in `src/components/<feature>/`, for example `src/components/wishes/WishCard.tsx`.
- **One component per file**, named after the component.
- **Exception:** a small set of closely related components of the same kind may share one file named after the set, for example `States.tsx` for loading, empty and error states.
- **A small helper** used only inside its own file may stay there.
- Shared building blocks (buttons, fields, cards) live in `src/components/ui/` and follow the theme.

## No hardcoded values

Nothing in app code is hardcoded. Every value has one named source:

| What | Where it comes from |
|---|---|
| UI text | Translation keys via `t()`, written in `src/locales/en.json` first and translated in `src/locales/sv.json` (§ Language) |
| Colours | Theme tokens in `src/theme/colors.ts`, for light and dark. Never hex or rgb in components |
| Spacing, sizes, radii, type | `src/theme/spacing.ts`, `src/theme/radii.ts`, `src/theme/typography.ts` |
| Magic numbers | Named constants in `src/lib/constants.ts` (limits, delays, image sizes) |
| Config and URLs | `process.env.EXPO_PUBLIC_*` in the app (public values only), `Deno.env.get` in Edge Functions |
| Errors from the server | Codes (for example `invite_expired`) that the app translates, as listed in `docs/error-codes.md`. Never user-facing text from Edge Functions or the database |

Allowed exceptions: theme token definitions, dynamic values computed at runtime (an animation), mock data and test fixtures. User data (list titles, wish names, notes) is never translated.

## UI and UX

- UI text in English and Swedish, written in English first (§ Language). Swedish is the default locale for users.
- Every new string gets a key in both locale files in the same commit.
- Phones first: every screen works from 360 dp wide, in light and dark mode, with large system fonts.
- **Adding a wish takes at most two taps** from opening the app to the camera.
- **Never make the user wait for the AI.** A wish is saved at once; suggestions arrive later and are shown as "Is this right?" with an easy edit.
- Every list and screen that loads data has a loading, empty and error state, and works without network as far as it can.

## Language

English is the working language. Everything in this repo is written in English: code, comments, docs, `TICKETS.md`, skills, CI, commit messages, issue and PR text. All UI copy is written in English first, in `src/locales/en.json`; Swedish exists only as its translation in `src/locales/sv.json`. The app still starts in Swedish for users (default locale `sv`, fallback `en`): that is a runtime setting, not the language the project is written in.

- New UI text goes into `en.json` first, then `sv.json`, in the same commit. Never hard-code UI text in components.
- Everything written about the app names the UI by its English text from `en.json`: "**+ Add wish**", never its Swedish label from `sv.json`. Docs, tickets, PRs, issue comments, manual test steps, commits and code comments all do, so anyone can follow them. The terms are in `docs/ui-spec.md` § UI terms (en → sv); a new term is added there.
- No Swedish anywhere outside `src/locales/sv.json`, except the allowlist in `scripts/check-english.sh`: `src/locales/native/sv.json` (the Swedish system texts, such as permission prompts, that `app.json` `locales` reads), the glossary in `docs/ui-spec.md`, and `docs/journal.md` and `docs/decisions/0011-name-and-slogan.md`, which quote the app's old name as history. Test data is in English. A Swedish text that is itself the subject (a translation fix) is quoted in the PR with the English beside it.
- `bash scripts/check-english.sh` fails on any Swedish letter (a with ring, a or o with diaeresis, either case) outside the allowlist. CI runs it in the `language` job, and `/wish-implement-ticket` and `/wish-git-ship` run it before every commit and push.

## GitHub

- All work happens in feature branches and is merged into `main` through pull requests. Never commit directly to `main`.
- `main` always builds and runs on a phone.
- `main` is protected: a pull request is required, all four CI jobs must pass on a branch that is up to date with `main`, the history must be linear, and the rules apply to admins too.
- **Every PR is squash-merged.** Merge commits and rebase merges are turned off in the repo settings, so each PR becomes exactly one commit on `main`:
  - The PR title becomes the commit title, so it follows the commit convention in § Workflow: `(MODEL_NAME) <type> [WISH-<N>] description`, at most 65 characters, because GitHub adds ` (#<n>)`.
  - The PR description becomes the commit body, so keep it short and useful as history: the template's sections, a line or two each, with no leftover `<!-- -->` hints. Logs, screenshots and long notes go in PR comments.
  - Put any `Co-Authored-By` trailer at the very end of the description, so it survives the squash.
  - Throwaway and work-in-progress commits are fine on the branch, since they never reach `main`.

## Workflow

- **Tickets:** GitHub issues titled `[WISH-<N>] ...`. One ticket per branch. PRs close their issue with `Closes #<n>`.
- **Skills:** the project skills in `.claude/skills/` run the workflow: `wish-create-ticket`, `wish-implement-ticket`, `wish-git-commit`, `wish-git-ship`, `wish-git-branch-and-ship`, `wish-review-pr`, `wish-data-safety`, `wish-epic-review`, `wish-epic-close`, `wish-audit-to-issues`, `wish-ai-eval`. Use them instead of personal skills with similar names.
- **Branch:** `wish/WISH-<N>-short-description`
- **Commit:** `(MODEL_NAME) <type> [WISH-<N>] description`. Types: feat, fix, style, refactor, chore, docs, test.
- **Commits are small and each one builds.** Order within a feature: database → Edge Functions → data layer → UI. A throwaway or work-in-progress commit is the exception: it is fine on the branch (§ GitHub), as long as the branch passes the checks below before it is pushed for review.
- **Before every commit:** `bash scripts/check-english.sh`, `npm run lint`, `npx tsc --noEmit`, `npm test` and `npm run build` (an `expo export` of the JS bundle) must pass.
- **Database changes** go in a new migration in `supabase/migrations/`, get a matching check in `supabase/tests/rls_test.sql`, and `supabase/tests/run_local.sh` passes before the PR.
- **Migrations reach the project before the merge.** A migration is never left to "apply later".
  - Migrations must be backwards compatible with the code on `main`: add columns with a default or as nullable, and drop or rename only in a later migration once no code on `main` uses the old shape.
  - The developer applies the migration: first `npx supabase db push --remote --dry-run`, which must list only the branch's migrations, then `npx supabase db push --remote`. Then the developer regenerates the types: `npx supabase gen types typescript --remote > src/lib/supabase/types.ts && npx prettier --write src/lib/supabase/types.ts`. Claude compares them with `git diff`, and a diff is committed to the branch.
  - If the migration changes tables, policies or functions, the developer runs `supabase/tests/rls_test.sql` in the SQL Editor against the project, and the PR says it passed.
  - If a PR whose migration is already applied is closed without merging, a new migration reverts it.
- **The Supabase CLI** is always run as `npx supabase`. Claude never runs a command against the linked project, not even a read-only one: it prints the command for the developer to run and paste back. For the local stack, Claude runs only `start`, `stop` and `status`. `.claude/settings.json` enforces this.
- **EAS** (`eas build`, `eas update`, `eas submit`, `eas credentials`, `eas env`, `eas device`) is never run by Claude: builds cost credits, updates reach real phones and credentials are secrets. Claude prints the command; the developer runs it.
- **Native changes need a new development build.** A PR that adds a native module or changes `app.json` plugins says so, and the developer builds and installs the new development build before testing.
- **Data safety:** `/wish-review-pr` runs `/wish-data-safety` in diff mode. A 🔴 risk is a blocker fixed on the branch; a change to a chain, policy or guard updates `docs/data-safety.md` in the same PR. `/wish-epic-close` runs the full mode.
- **Pull requests** target `main` with the template: what changed (database / Edge Functions / data layer / UI), acceptance criteria covered, manual test steps, tradeoffs. CI must be green. The title follows the commit convention and the description is kept short, because both become the squash commit on `main` (§ GitHub).
- **Ask before:** adding a dependency, adding a native module, changing the database schema outside a ticket, deleting files, writing to the remote database, running anything on EAS, pushing, or opening a PR. Running `/wish-git-ship` is the developer's request to push and open a PR.

## Working on your own

When a ticket is run without someone watching:

- One ticket per run. Create the branch, work through the acceptance criteria in order and commit as you go.
- If something is unclear, choose the option that best fits the spec and the quality bar, write the choice down in the summary and keep going. Stop only if the choice would break a security rule, change the schema or add a dependency.
- Never push, open a PR, merge or post to GitHub. Never delete files unless the ticket or the prompt that started the run names them.
- Finish with a summary: what was done, each acceptance criterion as done or not done, what was tested and how, and open questions.

## Definition of done

- All acceptance criteria in the ticket are met.
- Lint, type check, tests, build and CI pass.
- Tested on the developer's own Android phone and in the Android emulator, as the owner, and as a contact who sees it and one who does not when the ticket touches shared data.
- If the ticket touches data: checked that a contact it is not shared with and a stranger cannot see or change the owner's rows, that the owner cannot see reservations, and `rls_test.sql` passes if the schema changed.
- If the ticket adds a migration: it is applied to the project as described in § Workflow, and the generated types have no diff.
- A journal entry if the ticket taught something worth telling.
- Nothing is described as working unless it was tested.
