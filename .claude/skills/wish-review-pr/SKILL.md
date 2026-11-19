---
name: wish-review-pr
description: "Review a Wishing Well pull request or branch before it merges into main: security and RLS, the reservation promise, data layer rules, TypeScript, UI rules, tests and PR hygiene. Use when asked to review a PR, review this branch, or check a PR before merge."
argument-hint: "Optional: PR number, e.g. 12. Without it, the current branch is reviewed against main"
allowed-tools: Bash(gh repo view *), Bash(gh pr view *), Bash(gh pr diff *), Bash(gh pr checks *), Bash(gh issue view *), Bash(git diff *), Bash(git log --oneline *), Bash(git rev-parse --abbrev-ref HEAD), Bash(grep -rn *), Read, Glob, Grep
---

# PR Review — Wishing Well

Reviews code before it merges into `main`. `main` is what the family's phones get, so this is the last stop.

The argument is: `$ARGUMENTS`

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

---

## Step 1 — What to review

With a PR number:
```bash
gh pr view <number> --repo "$REPO" --json number,title,body,files,commits,baseRefName,headRefName
gh pr diff <number> --repo "$REPO"
gh pr checks <number> --repo "$REPO"
```

Without one, review the current branch:
```bash
git diff origin/main...HEAD --name-only
git diff origin/main...HEAD
git log --oneline origin/main..HEAD
```

Find the linked issue (`Closes #<n>`) and read its acceptance criteria.

---

## Step 2 — Read every changed file in full

Read each file completely before forming an opinion. For changed functions, also read their callers.

---

## Step 3 — Checks

### Security (any failure is a 🔴 blocker)
- **The reservation promise (rule 1):** nothing in the diff lets the owner learn that their wish is reserved — no column, count, sort order, badge, cached query, notification, log line or error message that differs for the owner depending on reservations
- No service role key in `src/` or any `EXPO_PUBLIC_*` variable: `grep -rn "service_role\|SERVICE_ROLE" src/`
- No secrets, keystores or `.env` files in the diff
- Edge Functions verify the caller first, read with the caller's JWT, and use the service role only for the one privileged action
- A function that fetches a URL follows rule 10: https only, private and local addresses refused, redirects checked hop by hop, time and size limits — with tests for the refusals
- New tables: RLS enabled, policies written, explicit grants, and a matching check in `supabase/tests/rls_test.sql`
- Changed RLS policies or grants: flag it and explain the effect
- A new migration follows `CLAUDE.md` § Workflow, and the PR says it was applied or will be before the merge
- No client code sends `owner_id` or `reserved_by`
- AI output is zod-validated, shown as a suggestion, and never saved without the user's confirmation; a shown price comes from the shop's page (rule 11)
- Photos are re-encoded before upload (rule 12)

### Data layer
- Supabase calls only in `src/lib/api/`. Components use hooks from `src/hooks/`
- Query keys include the signed-in user's id; sign-out clears the cache
- Mutations invalidate the right keys. Errors reach the UI as an error state or a toast, never silently
- Supabase results check `error` before using `data`

### TypeScript
- No `any`, no `as` casts that silence errors, no `@ts-ignore`
- External input (route params, forms, function bodies, AI output, fetched pages) validated with zod

### UI
- Files follow `CLAUDE.md` § Code structure
- Every string through `t()` and in both locale files; no hardcoded text (🟡)
- No hex or rgb outside `src/theme/`; no magic numbers outside `src/lib/constants.ts` (🟡)
- Loading, empty and error states; no-network behaviour
- 360 dp wide, dark mode, large system fonts, accessibility labels, 48 dp targets
- Adding a wish is still at most two taps from start to camera; nothing waits for the AI

### Native
- A new native module or `app.json` plugin is flagged in the PR, with the development build step

### Tests and CI
- New pure logic has a unit test; Edge Function handlers have Deno tests without network
- `gh pr checks` shows the `app`, `functions` and `rls` jobs green. If not, it is a blocker
- The manual test steps in the PR say who each step is run as, and were run on a phone

### Quality bar
- Edge cases handled, no dead code or stray `console.log`, no `TODO` without an issue, nothing outside the ticket's scope

### PR hygiene
- Branch `wish/WISH-<N>-...`, commits `(MODEL_NAME) <type> [WISH-<N>] ...`, title `<type> [WISH-<N>] Title Case Summary`
- Body has Summary, What Changed, Acceptance Criteria, Manual Test Steps, Tradeoffs and `Closes #<n>`

### Data safety
- Run `/wish-data-safety` in diff mode on the PR's branch. It answers in one line when no data path is touched; otherwise its risk table goes into the review as it is
- A 🔴 row is a blocker, fixed on the branch before the merge
- If the diff changes a chain, a policy, a grant or a guard, `docs/data-safety.md` is updated on the branch

---

## Step 4 — Output

```
## Code Review — [WISH-<N>] <PR title>

**Status:** ✅ Approved | ⚠️ Needs changes | ❌ Blocked

### Summary
<2–3 sentences>

### Issues
| Severity | File:line | Issue |
|----------|-----------|-------|
| 🔴 Blocker | … | … |
| 🟡 Warning | … | … |
| 🟢 Suggestion | … | … |

### Data Safety
<The risk table from /wish-data-safety, or its one line>

### Acceptance Criteria
- AC1: <text> — ✅ <file:line> / ⚠️ partial / ❌ missing

### Checks That Failed
<Only the failed items from Step 3>

### What Was Done Well
<Specific, concrete good patterns>

### Verdict
<Clear recommendation and why>
```

If reviewing a real PR, ask the developer before posting the review as a comment (`gh pr comment`). When the status is ✅ Approved, the same yes also ticks the issue's ACs that the review marked ✅.

## Severity

- 🔴 **Blocker:** a security rule broken, the reservation promise at risk, missing RLS or grants, a 🔴 data-safety risk, failing CI, a type error, an AC claimed but not implemented. Do not merge
- 🟡 **Warning:** missing state, missing test, hardcoded value, hygiene. Fix before merge if it is quick
- 🟢 **Suggestion:** optional improvement

## Rules

- Do not invent issues that are not in the diff
- Do not suggest refactors outside the PR's scope
- Never approve a PR with a 🔴 blocker
- Never approve or merge on the developer's behalf. The review is advice
- Fix 🔴 blockers and real bugs on the branch before the merge. Log 🟢 suggestions, and 🟡 warnings that are not quick to fix, as one line each in `TICKETS.md` § Found while reviewing PRs, with the PR number
