---
name: wish-git-ship
description: "Ship a finished Wishing Well ticket branch: validate, sync with main, commit what is left, push and open a PR that closes the issue. Use when: shipping a finished ticket, sending code for review, pushing a completed change, opening a PR."
argument-hint: "Optional: WISH-<N> or extra notes for the PR description"
allowed-tools: Bash(git status), Bash(git diff --stat), Bash(git diff *), Bash(git log --oneline *), Bash(git add *), Bash(git commit -m *), Bash(git rev-parse --abbrev-ref HEAD), Bash(git rev-parse --abbrev-ref --symbolic-full-name @{u}), Bash(git fetch origin), Bash(git rebase origin/main), Bash(npm run lint), Bash(npx tsc --noEmit), Bash(npm test), Bash(npm run build), Bash(bash supabase/tests/run_local.sh), Bash(gh repo view *), Bash(gh issue list *), Bash(gh issue view *), Bash(gh pr view *)
---

# Git Ship — Wishing Well

Ships the current `wish/WISH-<N>-...` branch and opens a PR to `main`. Run every step in order.

`git push` and `gh pr create` are deliberately **not** in `allowed-tools`: Claude Code asks before each, as `CLAUDE.md` requires. Running this skill is the developer's request to ship, so say yes to those prompts.

Never run this skill unattended (`CLAUDE.md` § Working on your own).

The optional argument is: `$ARGUMENTS`

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

---

## Step 1 — Verify the branch

```bash
git rev-parse --abbrev-ref HEAD
```

- On `main`: **stop**. Direct pushes to `main` are not allowed. Use `wish-git-branch-and-ship`
- The branch must follow `wish/WISH-<N>-...`. Extract `WISH-<N>`
- Exception: an epic close-out branch `wish/epic-<N>-review` from `wish-epic-close`. Use `[Epic <N>]` wherever this skill says `[WISH-<N>]`, skip the issue lookup, and leave out `Closes`
- Find the issue:
  ```bash
  gh issue list --repo "$REPO" --state all --search "WISH-<N> in:title" --json number,title,url,body --limit 10
  ```
  Use the one whose title starts with exactly `[WISH-<N>]`. If none exists, warn and continue without `Closes`

---

## Step 2 — Validation

```bash
bash scripts/check-english.sh
npm run lint
npx tsc --noEmit
npm test
npm run build
```

All five must pass (`scripts/check-english.sh`: no Swedish outside `src/locales/sv.json`, `CLAUDE.md` § Language). Then:

- If the branch touches `supabase/`: `bash supabase/tests/run_local.sh`
- If the branch touches `supabase/functions/`: the Deno checks as CI runs them (`DENO_NO_PACKAGE_JSON=1`):
  ```bash
  deno check supabase/functions/*/index.ts
  deno test --allow-env supabase/functions
  ```

A check that cannot run here (no Postgres or Deno) is noted for CI in the PR's Validation section, never left out silently.

**If anything fails, stop and fix it before continuing.**

---

## Step 3 — Sync with main

```bash
git fetch origin
git rebase origin/main
```

On conflicts, **stop and report**. Never resolve conflicts automatically. After a rebase, run Step 2 again.

---

## Step 4 — Commit what is left

1. `git status` and `git diff --stat`
2. Clean working tree: go to Step 5
3. Otherwise commit with `wish-git-commit`: logical groups, files staged by name, never `git add .`
4. **If a commit fails, stop**

---

## Step 5 — Push

1. Show the branch's commits: `git log --oneline origin/main..HEAD`
2. Check every subject follows `(MODEL_NAME) <type> [WISH-<N>] ...` and list any that do not
3. Push: `git push -u origin <branch>` (no upstream) or `git push`
4. Never force-push. If a rebase means an already-pushed branch needs `git push --force-with-lease`, stop and ask the developer to run it themselves

**If the push fails, stop.**

---

## Step 6 — Open the PR

Use `.github/pull_request_template.md`, filled in: Summary, What Changed (database, Edge Functions, data layer, UI, tests, native), every AC, manual test steps with who they are run as, tradeoffs, validation.

```bash
gh pr create --repo "$REPO" --base main --title "<type> [WISH-<N>] <Title Case Summary>" --body-file "<filled template>"
```

- Title: `<type> [WISH-<N>] Title Case Summary`, where type is the main commit type
- `Closes #<number>` must be in the body so the issue closes when the PR merges
- Show the PR URL to the developer

---

## Step 7 — After the PR is open

- **Migration:** it reaches the project before the merge (`CLAUDE.md` § Workflow). Claude prints each command for the developer to run and paste back:
  1. `npx supabase db push --remote --dry-run` — must list only this branch's migrations
  2. With the developer's yes: `npx supabase db push --remote`
  3. `npx supabase gen types typescript --remote > src/lib/supabase/types.ts && npx prettier --write src/lib/supabase/types.ts`; Claude runs `git diff src/lib/supabase/types.ts`, and commits and pushes a diff
  4. If tables, policies or functions changed: the developer runs `supabase/tests/rls_test.sql` in the SQL Editor; the result goes in the PR's Validation section
- **Edge Function:** the developer deploys it (`npx supabase functions deploy <name>`) before the merge when the code on `main` will call it, and after the merge otherwise. New secrets: the developer sets them (`npx supabase secrets set …`)
- **Native change:** the developer builds and installs a new development build before testing (`eas build --profile development --platform android`)
- Tell the developer to wait for CI before merging, and suggest `/wish-review-pr <number>`
- Ask: "Tick AC1–AC<n> on #<number> now that the PR covers them?" Tick them only after a yes, and only the ACs the PR marks `- [x]`

---

## Completion checks

- [ ] Branch is not `main` and follows `wish/WISH-<N>-...` (or `wish/epic-<N>-review`)
- [ ] check-english, lint, tsc, test and build pass. RLS and Deno tests passed or noted for CI
- [ ] A new migration is applied with the developer's yes, the types are compared, and the SQL Editor RLS run is in the PR when needed
- [ ] Rebased on `origin/main` without conflicts
- [ ] Files staged by name, commits follow the format, no `--no-verify`
- [ ] Push succeeded, no force-push
- [ ] PR to `main` with the template filled in and `Closes #<number>` (not for `wish/epic-<N>-review`)
- [ ] PR URL shown
- [ ] Asked whether to tick the issue's ACs
