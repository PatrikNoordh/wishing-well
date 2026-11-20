---
name: wish-epic-review
description: "Senior close-out review of a Wishing Well epic before moving on: ticket and PR completeness, security and RLS, the reservation promise, data layer rules, code quality, validation, AC coverage and build health. Outputs a GO / NO-GO report. Use after the last ticket in an epic is merged, or at an epic checkpoint."
argument-hint: "Epic number, e.g. 2. Without it, the epic of the current branch is used"
allowed-tools: Bash(git log --oneline *), Bash(git branch -a), Bash(gh repo view *), Bash(gh issue list *), Bash(gh issue view *), Bash(gh pr list *), Bash(gh pr view *), Bash(gh run list *), Bash(gh api *), Bash(grep -rn *), Bash(npm ci), Bash(npm run lint), Bash(npx tsc --noEmit), Bash(npm test), Bash(npm run build), Bash(bash supabase/tests/run_local.sh), Glob, Grep, Read
---

# Epic Review — Wishing Well

You are a **senior engineer** doing the close-out review before an epic is marked done. Find problems now, before they compound in the next epic. Be honest: a "GO" that hides real problems is worse than a "NO-GO" that costs an hour.

Input: `/wish-epic-review 2`. Without a number, use the epic of the current branch's ticket, or the most recent milestone with merged PRs.

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

---

## Step 1 — Scope

```bash
gh api "repos/$REPO/milestones?state=all" --jq '.[] | "\(.number) \(.title) open=\(.open_issues) closed=\(.closed_issues)"'
gh issue list --repo "$REPO" --milestone "<Epic N — Name>" --state all --json number,title,state,body --limit 50
```

Identify every `[WISH-<N>]` ticket in the epic, which are closed, and their acceptance criteria. Read the epic's **Checkpoint** line in `TICKETS.md`; it is the epic's own definition of done. Any open ticket is a blocker.

---

## Step 2 — PR audit

```bash
gh pr list --repo "$REPO" --state merged --json number,title,headRefName,mergedAt,body --limit 50
```

For each ticket: a merged PR from a `wish/WISH-<N>-...` branch, with What Changed, Acceptance Criteria, Manual Test Steps and `Closes #<n>`. A ticket closed without a PR is fine only if the work happened outside the code and the issue says so.

---

## Step 3 — Security, RLS and the promise (any finding is a blocker)

```bash
# Service role key in the app or a public variable
grep -rn "service_role\|SERVICE_ROLE" src/ app.json eas.json 2>/dev/null
grep -rn "EXPO_PUBLIC_" src/ .env.example | grep -iv "SUPABASE_URL\|SUPABASE_ANON_KEY"

# Supabase client used outside the data layer and auth
grep -rln "supabase\." src/ | grep -v "src/lib/api/\|src/lib/supabase/\|src/contexts/AuthContext"

# Every table has RLS, and grants are explicit
grep -hn "create table" supabase/migrations/*.sql
grep -hn "enable row level security" supabase/migrations/*.sql
grep -hn "^grant\|^revoke" supabase/migrations/*.sql

# Where reservations are read in the app: each place must be for someone else's wishes
grep -rn "reservation" src/ --include="*.ts" --include="*.tsx" | grep -v "src/locales/"

# Fetching URLs in Edge Functions: each must go through the safe fetcher
grep -rn "fetch(" supabase/functions/ | grep -v "_test.ts\|.test.ts"

# Secrets, keystores or env files committed
git ls-files | grep -E "\.env($|\.)|\.keystore$|\.jks$|\.p8$|\.p12$" | grep -v ".env.example"
```

Also check:
- Every Edge Function checks the caller first and handles `OPTIONS`
- No client code sends `owner_id` or `reserved_by`
- `bash supabase/tests/run_local.sh` passes, and every policy and grant added in the epic has a check
- Photos are re-encoded before upload; nothing in `eval/` shows a person

---

## Step 4 — Code quality

```bash
grep -rn "TODO\|FIXME" src/ supabase/ --include="*.ts" --include="*.tsx" --include="*.sql"
grep -rn "console\.log" src/ supabase/functions/ 2>/dev/null
grep -rn ": any\b\|as any\|@ts-ignore\|@ts-expect-error" src/ supabase/functions/ 2>/dev/null

# Raw colours outside the theme
grep -rnE "#[0-9a-fA-F]{3,8}\b|rgba?\(" src/ --include="*.tsx" --include="*.ts" | grep -v "src/theme/"

# Bare numbers in styles outside the theme (spacing, sizes, radii)
grep -rnE "(padding|margin|gap|width|height|borderRadius|fontSize)[A-Za-z]*: *[0-9]+" src/ --include="*.tsx" --include="*.ts" | grep -v "src/theme/"

# Hardcoded UI text: Swedish characters or JSX text outside the locale files
bash scripts/check-english.sh
grep -rnE "<Text[^>]*>[[:space:]]*[[:alpha:]][^<>{}]{2,}<" src/ --include="*.tsx"

# Query keys without the user id
grep -rn "queryKey:" src/ --include="*.ts" --include="*.tsx"
```

Classify each TODO as a known deferral (warning) or a missing implementation (blocker). Check that every query key goes through `src/lib/queryKeys.ts` with the user id.

---

## Step 5 — Validation

On an up-to-date `main`:

```bash
npm ci
npm run lint
npx tsc --noEmit
npm test
npm run build
bash supabase/tests/run_local.sh
gh run list --repo "$REPO" --branch main --limit 5
```

The last CI run on `main` must be green in all four jobs (`language`, `app`, `functions`, `rls`). Any failure is a blocker.

---

## Step 6 — Acceptance criteria

For every ticket, read the code that implements each AC. Do not trust that a closed issue means the AC is met. Mark each AC as implemented (with file:line), partial, or missing.

---

## Step 7 — Build and release health

- `.env.example` lists every `EXPO_PUBLIC_*` variable the code reads
- After a schema change: `src/lib/supabase/types.ts` matches the project (the developer regenerates and Claude compares)
- `npx supabase migration list --remote` shows no local migration missing on Remote (printed for the developer to run)
- Edge Functions in `supabase/functions/` are deployed (ask the developer)
- The checkpoint's manual test was run on real phones, and the installed build is the one from `main` (ask the developer for the build and update ids)

Anything you cannot check: "Could not verify — <reason>". Never guess.

---

## Step 8 — Report

```
# Epic N Review — <Epic name>
Date: <today>
Tickets reviewed: WISH-X, WISH-Y
Generated by: /wish-epic-review

---

## VERDICT: ✅ GO / ❌ NO-GO

<One sentence.>

## 1. Tickets and PRs — PASS / FAIL
## 2. Security, RLS and the reservation promise — PASS / FAIL
| Check | Result |
|---|---|
| No service role key or secret in the app | ✅ / ❌ |
| Supabase calls only in the data layer and auth | ✅ / ❌ |
| Every table has RLS, explicit grants and a test | ✅ / ❌ |
| The owner sees no reservation anywhere | ✅ / ❌ |
| Edge Functions check the caller; URL fetching is safe | ✅ / ❌ / n/a |
| No secrets committed | ✅ / ❌ |
## 3. Code Quality — PASS / FAIL
## 4. Validation — PASS / FAIL
## 5. Acceptance Criteria — PASS / FAIL
## 6. Build and Release — PASS / FAIL

## Blockers (fix before Epic N+1)
## Warnings
## Senior Notes
<2–4 honest sentences.>
```

## Output rules

- Never mark a section PASS if you found a violation, even a small one
- Any ❌ in Security or Validation makes the verdict NO-GO
- Name files, lines and exact issues. Do not skip sections

## Next step

Fix the blockers first: `/wish-audit-to-issues blockers` creates a ticket for each. When the verdict is GO, run `/wish-epic-close <N>`.
