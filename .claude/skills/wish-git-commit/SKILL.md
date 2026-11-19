---
name: wish-git-commit
description: 'Commit message format and commit splitting for Wishing Well. Use when: committing changes, writing a commit message, staging and committing files, git commit -m.'
argument-hint: 'Optional: commit type (feat|fix|docs|style|refactor|test|chore)'
---

# Git Commit Format — Wishing Well

Commit format for every Claude-assisted commit in Wishing Well. Same format as `CLAUDE.md` § Workflow.

## Format

```
(MODEL_NAME) <type> [WISH-<N>] <imperative description>
```

Replace `MODEL_NAME` with the **actual model running this session**. Never hardcode a model name.

Examples:
```
(claude-opus-5-5) chore [WISH-1] Create the Expo app with Expo Router and strict TypeScript
(claude-opus-5-5) feat [WISH-7] Replace the mock AuthContext with Supabase email codes
(claude-opus-5-5) feat [WISH-16] Reserve and unreserve a wish from a person's list
(claude-opus-5-5) fix [WISH-16] Clear the query cache when another account signs in
(claude-opus-5-5) test [WISH-14] Check that a re-encoded photo carries no location
```

Take `WISH-<N>` from the branch name (`wish/WISH-<N>-...`). If the branch has no ticket id, stop and ask which ticket the work belongs to.

## Types

| Type | When |
|------|------|
| `feat` | New feature or behaviour |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting or visual-only change, no logic change |
| `refactor` | Restructure, no behaviour change |
| `test` | Tests only |
| `chore` | Config, tooling, dependencies, CI |

## Before every commit

```bash
npm run lint
npx tsc --noEmit
npm test
npm run build
```

All four must pass. `npm run build` (an `expo export` of the JS bundle) does not type-check, so `tsc` is not optional. If the commit touches `supabase/`, also run `bash supabase/tests/run_local.sh` (see `wish-implement-ticket` § Validation).

## Splitting into several commits

1. `git status` and `git diff --stat` to survey the changes
2. Group by **what changed and why**, not by file
3. Order: database (migrations, RLS tests) → Edge Functions → data layer (`src/lib/api/`, `src/hooks/`) → UI (`src/app/`, `src/components/`) → tests → docs
4. Stage each group by name with `git add <files>`. Never `git add .` or `git add -A`
5. Every commit must build and pass on its own

## Rules

- The ticket id repeats on every commit in the branch
- Imperative mood, subject under 72 characters, no body
- Never add a `Co-Authored-By` footer or other attribution. The `(MODEL_NAME)` prefix already says who wrote it
- Never `--no-verify`
- Never commit `.env`, `.env*.local`, secrets, keystores or the Supabase service role key
- Never commit directly on `main`
