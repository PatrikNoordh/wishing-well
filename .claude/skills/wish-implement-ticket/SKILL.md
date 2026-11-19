---
name: wish-implement-ticket
description: "Implement a Wishing Well ticket end-to-end: fetch the GitHub issue, branch, implement following CLAUDE.md, validate, commit in logical steps and report. Use when asked to implement a ticket, work on an issue or start a ticket (e.g. 'Implement WISH-9' or 'implement issue #7')."
argument-hint: "WISH-<N> or GitHub issue number, e.g. WISH-9 or #7"
---

# Implement Ticket — Wishing Well

Implements one ticket end-to-end, following every rule in `CLAUDE.md`. Read `CLAUDE.md` first if it is not already in context.

The ticket is: `$ARGUMENTS`

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

---

## Step 1 — Fetch the ticket

Accept `WISH-9`, `#7` or `7`.

```bash
gh issue list --repo "$REPO" --state all --search "WISH-<N> in:title" --json number,title,body,labels,milestone,state --limit 10
# or, by issue number:
gh issue view <number> --repo "$REPO" --json number,title,body,labels,milestone,state
```

Use the issue whose title starts with exactly `[WISH-<N>]`. The search also matches `WISH-20` when you ask for `WISH-1`.

If there is no issue, fall back to the ticket's block in `TICKETS.md` and say so in the final summary.

From the ticket, extract:

1. **Type:** feat / fix / chore / docs / spike
2. **Acceptance Criteria:** every `- [ ]` item. Items already `- [x]` are done
3. **Layers:** Database / Edge Function / Data layer / UI
4. **Spec:** the relevant part of `docs/ui-spec.md`, `docs/requirements.md` and any decision record it names

Then check the stop conditions. **Stop and ask the developer before writing any code** if the ticket needs any of these and the ticket text does not already decide it:

| Condition | Why |
|---|---|
| A change to the database schema, RLS or grants that is not in the ticket | Security rests on the schema. `CLAUDE.md` § Security rules |
| A new dependency or native module the ticket does not name | `CLAUDE.md` § Ask before |
| Deleting files | `CLAUDE.md` § Ask before |
| Using the service role key anywhere except the one action an Edge Function exists for | Security rule 2 |
| Anything that could let the owner learn about a reservation | Security rule 1 |
| Running anything on EAS or against the linked Supabase project | `CLAUDE.md` § Workflow: print it for the developer |

When running unattended (`CLAUDE.md` § Working on your own): choose the simplest option that matches the spec, note it in the summary and keep going. Stop only for schema changes, dependencies and security rules.

---

## Step 2 — Create the branch

```bash
git switch main
git pull --ff-only origin main
git switch -c wish/WISH-<N>-short-kebab-description
```

The slug is 2–5 lowercase words describing what changes. If the branch already exists, ask whether to continue on it.

---

## Step 3 — Plan

Read the existing code in the area before changing anything. Where things live:

| What | Where |
|---|---|
| Screens (file-based routes) | `src/app/` |
| Screen parts | `src/components/<feature>/`, one component per file |
| Building blocks | `src/components/ui/`, `src/components/States.tsx` |
| Data functions, one file per table or function | `src/lib/api/<name>.ts` |
| Query keys | `src/lib/queryKeys.ts` (every key includes the user id) |
| TanStack Query hooks | `src/hooks/use<Thing>.ts` |
| Auth | `src/contexts/AuthContext.tsx` (`useAuth()`) |
| Supabase client and generated types | `src/lib/supabase/` |
| Theme | `src/theme/` |
| Translations | `src/locales/sv.json`, `src/locales/en.json` |
| Constants | `src/lib/constants.ts` |
| Migrations | `supabase/migrations/<timestamp>_<name>.sql` |
| RLS tests | `supabase/tests/rls_test.sql` |
| Edge Functions | `supabase/functions/<name>/index.ts`, `handler.ts`, `handler.test.ts` |
| Shared function code (CORS, link reader, AI layer) | `supabase/functions/_shared/` |
| App tests | next to the code as `*.test.ts(x)`, or in `src/test/` |

Only touch the layers the ticket needs. Write the plan as a short list before coding.

---

## Step 4 — Implement

Follow `CLAUDE.md` exactly. The rules that matter most:

### Data and security
- Supabase calls only in `src/lib/api/`. Components use hooks, never the client directly
- Every query key includes the signed-in user's id. Sign-out clears the cache
- Mutations invalidate the keys they affect; optimistic updates roll back on error
- Never send `owner_id` or `reserved_by` from the client. The database sets them
- Never show, count, sort by or cache anything about reservations on the owner's own wishes
- Edge Functions: verify the caller first, read with the caller's JWT, use the service role only for the one privileged write, handle CORS and `OPTIONS`, read secrets with `Deno.env.get`, return error codes
- Fetching a URL a user gave: security rule 10, every time
- AI output: zod-validated structured output, shown as a suggestion, never saved without the user's confirmation; a shown price comes from the shop's page
- Every new table: RLS enabled, policies written, explicit grants, and a check added to `supabase/tests/rls_test.sql`

### TypeScript
- Strict mode. No `any`, no `as` casts to silence errors, no `@ts-ignore`
- Validate external input (route params, forms, Edge Function bodies, AI output, fetched pages) with zod

### No hardcoded values (`CLAUDE.md` § No hardcoded values)
- UI text through `t()` with a key in both locale files, added in the same commit. Counts use i18next plurals
- Colours, spacing, radii and type from `src/theme/`. Never hex or rgb in components
- Magic numbers become named constants in `src/lib/constants.ts`
- Errors from Edge Functions and the database are codes; the app translates them (`docs/error-codes.md`)

### UI and UX
- Code, comments and identifiers in English
- Reuse `src/components/ui/` and `States.tsx` before writing new components
- Loading, empty and error states; sensible behaviour without network
- 360 dp wide, dark mode, large system fonts, accessibility labels, 48 dp touch targets
- Adding a wish stays at most two taps from start to camera; nothing waits for the AI

### Tests
- Pure logic (formatting, validation, mapping error codes, query keys, parsers) gets a unit test
- Components with behaviour get a React Native Testing Library test
- Edge Function handlers get Deno tests with recorded responses; no network in tests

---

## Step 5 — Validation

Run all of them. Each must pass before every commit:

```bash
npm run lint
npx tsc --noEmit
npm test
npm run build
```

If the branch touches `supabase/`, also run the RLS tests against a throwaway local database:

```bash
bash supabase/tests/run_local.sh
```

Every check must print `OK`. If Postgres is not available locally, say so in the summary. CI runs the same job on the PR.

If the branch touches `supabase/functions/`, also run the Deno checks the way CI does (`DENO_NO_PACKAGE_JSON=1`): `deno check supabase/functions/*/index.ts` and `deno test --allow-env supabase/functions`.

If the branch adds a migration, it must follow the migration rules in `CLAUDE.md` § Workflow. Print the dry run for the developer to run in their own terminal and paste back. Never run a command against the linked project yourself:

```bash
npx supabase db push --remote --dry-run
```

If the branch adds a native module or changes `app.json` plugins, print the development build command for the developer (`eas build --profile development --platform android`) and say that testing waits for the new build.

Manual test, described in the summary, on the developer's own Android phone and in the Android emulator: as the owner, and for shared data also as a contact who sees it and a contact who does not (one of them in the emulator), and as a stranger who must see nothing.

---

## Step 5b — Self-review

Before the last commit, read the whole branch as a strict reviewer:

```bash
git diff origin/main...HEAD
```

Check it against the quality bar in `CLAUDE.md`. If a script, an env variable, CI or user-facing behaviour changed, check that `README.md` and `.env.example` still match. Fix what you find and run the validation again. Note anything you chose not to fix, and why, in the summary.

---

## Step 6 — Commit in logical steps

Use `wish-git-commit`. Several small commits, ordered database → Edge Functions → data layer → UI → tests → docs. Stage files by name. Every commit builds and passes on its own.

```
(MODEL_NAME) <type> [WISH-<N>] imperative description
```

If the ticket taught something worth telling, add an entry to `docs/journal.md` in the docs commit.

---

## Step 7 — Summary and issue update

Print this summary:

```markdown
## [WISH-<N>] Implementation complete

### Summary
<One or two sentences: what was built and why.>

### What Was Done
1. **Database** — <item or "Not touched">
2. **Edge Functions** — <item or "Not touched">
3. **Data layer** — <item or "Not touched">
4. **UI** — <item or "Not touched">
5. **Tests** — <item or "Not touched">
6. **Native** — <new module or plugin, or "None">

### Acceptance Criteria
- [x] AC1: <text> — <how it was verified>
- [ ] AC2: <text> — <why not done>

### Manual Test Steps
1. <Step, with who it is run as: owner, contact who sees it, contact who does not, stranger>

### Decisions and Tradeoffs
- <Choices made, things deferred, anything a reviewer should know>

### Validation
- lint ✅ / tsc ✅ / test ✅ / build ✅ / RLS ✅ or "not run locally — CI"

### Commands for the developer
- <migration dry run, development build, secrets — or "none">
```

Then, **only if the developer is present and says yes**, post it to the issue and tick off the done ACs:

```bash
gh issue comment <number> --repo "$REPO" --body "<summary>"
gh issue edit <number> --repo "$REPO" --body-file "<file with completed - [ ] changed to - [x]>"
```

Never tick an AC that was not verified. Do not close the issue. The PR closes it with `Closes #<number>`.

When running unattended: print the summary and stop. Do not push, open a PR or post to GitHub.

---

## Completion checks

- [ ] Ticket fetched, every AC addressed or explained
- [ ] Branch `wish/WISH-<N>-...` created from an up-to-date `main`
- [ ] No Supabase calls outside `src/lib/api/`
- [ ] Query keys include the user id; nothing shows reservations to the owner
- [ ] No service role key in `src/`; Edge Functions read with the caller's JWT
- [ ] New tables have RLS, grants and a check in `rls_test.sql`
- [ ] No `any` or silencing casts; external input validated with zod
- [ ] No hardcoded values: text via `t()` in sv and en, theme tokens, named constants
- [ ] Loading, empty and error states; 360 dp, dark mode, large fonts, accessible
- [ ] lint, tsc, test and build pass. RLS and Deno tests pass or are deferred to CI with a note
- [ ] Commits follow `(MODEL_NAME) <type> [WISH-<N>]` and are staged by file
- [ ] Self-review of the full diff done against the quality bar
- [ ] Summary printed. Issue updated only with the developer's yes
