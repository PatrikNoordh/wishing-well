---
name: wish-git-branch-and-ship
description: "Move staged changes onto a proper wish/WISH-<N>-... branch, then hand off to wish-git-ship. Use when: there is staged work on main or on the wrong branch that should be shipped properly (e.g. 'branch and ship WISH-16')."
argument-hint: "WISH-<N> and an optional hint, e.g. 'WISH-16 reserve a wish'"
allowed-tools: Bash(git status), Bash(git diff --stat), Bash(git diff --name-only *), Bash(git stash push --staged *), Bash(git stash pop), Bash(git switch -c *), Bash(git rev-parse --abbrev-ref HEAD), Bash(git branch --show-current)
---

# Git Branch and Ship — Wishing Well

Takes the **staged** changes only, moves them onto a correctly named `wish/WISH-<N>-...` branch, then hands off to `wish-git-ship` to validate, commit, push and open a PR.

The argument is: `$ARGUMENTS`

---

## Step 1 — Survey the staged changes only

```bash
git diff --name-only --cached
```

Unstaged and untracked files must never be touched by this skill.

If nothing is staged, **stop**:
```
Nothing is staged. Stage the files you want to ship first with:
  git add <files>
Then run this skill again.
```

Read the staged list and decide in one sentence what the work is, and which layers it touches (database / Edge Functions / data layer / UI / tests / docs).

---

## Step 2 — Branch name

```
wish/WISH-<N>-short-kebab-description
```

- `WISH-<N>` is required. Take it from `$ARGUMENTS`. If it is missing, **stop and ask** which ticket this belongs to. If there is no ticket yet, suggest `wish-create-ticket` first
- Slug: 2–5 lowercase words describing what changed, no ticket number in the slug
- At most 50 characters after `wish/`

Examples:
```
wish/WISH-1-expo-app
wish/WISH-9-invite-a-contact
wish/WISH-16-reserve-a-wish
```

Tell the developer the branch name before continuing.

---

## Step 3 — Stash only the staged changes

```bash
git stash push --staged -m "branch-and-ship: WISH-<N>"
```

If the stash fails, **stop and report**. Never lose work.

Check that the index is empty and the unstaged files are untouched:
```bash
git diff --name-only --cached   # must be empty
git status                      # unstaged and untracked files still present
```

---

## Step 4 — Create the branch

```bash
git switch -c wish/WISH-<N>-short-description
```

The branch starts from the current commit. If that is not an up-to-date `main`, tell the developer, because `wish-git-ship` will rebase onto `origin/main`.

If the branch already exists, stop and ask whether to reuse it or pick another name. Never add `-2` on your own.

---

## Step 5 — Restore the staged changes

```bash
git stash pop
```

On conflicts, **stop**:
```
Stash pop produced conflicts in: <files>
Resolve them manually, then run /wish-git-ship to continue.
```

Never resolve stash conflicts automatically.

---

## Step 6 — Verify and hand off

```bash
git diff --name-only --cached
```

The list must match Step 1 exactly. Then run `wish-git-ship`. It must only commit the files that are staged now. Never `git add .` or `git add -A`.

---

## Completion checks

- [ ] Something was staged before starting
- [ ] Ticket id confirmed, branch follows `wish/WISH-<N>-...`, branch is not `main`
- [ ] Stash used `--staged`; unstaged and untracked files untouched
- [ ] Stash popped cleanly and the staged list matches Step 1
- [ ] `wish-git-ship` completed
