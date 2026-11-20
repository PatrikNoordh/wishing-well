---
name: wish-create-ticket
description: "Create a GitHub issue for Wishing Well from a short description, or import every ticket in TICKETS.md as issues. Use when asked to create, open or add a ticket/issue (e.g. 'Create a ticket for …'), or to import the ticket plan ('/wish-create-ticket import')."
argument-hint: "Short description of the ticket, or 'import' to create issues from TICKETS.md"
---

# Create GitHub Issue — Wishing Well

Creates well-structured GitHub issues following the project's conventions. GitHub Issues are the live source of truth for tickets and their status. `TICKETS.md` is the plan.

The request is: `$ARGUMENTS`

Always work against the current repository. Never hardcode the repo name:

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

If `$ARGUMENTS` is `import`, go to **Import mode** at the bottom. Otherwise follow the steps below.

---

## Step 1 — Classify the ticket

| Type | When | Example title |
|------|------|---------------|
| `feat` | New user-facing behaviour, screen, Edge Function or table | `Reserve a wish from a person's list` |
| `fix` | Something broken or incorrect | `Fix reservations shown after switching account` |
| `chore` | Tooling, CI, config, builds, no user-visible change | `Add the Deno job to CI` |
| `refactor` | Restructure without behaviour change | `Move image sizes into constants` |
| `docs` | Documentation only | `Write the AI evaluation method` |
| `spike` | Time-boxed investigation | `Spike: which provider recognises products best` |

---

## Step 2 — Check that the work does not already exist

1. Pick the key identifiers from `$ARGUMENTS`: screen, component, hook, table, function or file names.
2. Search the code:

   ```bash
   grep -rn "<Symbol>" src/ supabase/ --include="*.ts" --include="*.tsx" --include="*.sql" | head -10
   ```

3. Search open and closed issues:

   ```bash
   gh issue list --repo "$REPO" --state all --search "<key words>" --json number,title,state --limit 20
   ```

If anything matches, show the file:line or issue and stop with these options:

```
⚠️  DUPLICATE RISK
"<Symbol>" already exists in <file:line> / issue #<n> [WISH-<N>] <title>

Options:
  A) Stop — already implemented or already ticketed.
  B) Proceed — this ticket extends the existing work (state what is new).
  C) Link — reference the existing file or issue in the new ticket.
```

Do not continue until the developer chooses.

---

## Step 3 — Next WISH number

```bash
gh issue list --repo "$REPO" --state all --json title --limit 300 | \
  python3 -c "
import sys, json, re
nums = [int(m.group(1)) for i in json.load(sys.stdin) for m in [re.search(r'WISH-(\d+)', i['title'])] if m]
print(max(nums) + 1 if nums else 1)
"
```

Also check the highest `WISH-<N>` in `TICKETS.md` and use whichever is higher. Call it `NEXT`.

---

## Step 4 — Milestone and labels

**Milestone:** the epic the work belongs to, using the exact `## Epic N — Name` heading from `TICKETS.md` (for example `Epic 3 — Sharing and reservations`). Ask if unsure.

**Labels:**
- The type from Step 1
- `security` if the ticket touches RLS, auth, grants, Edge Functions, the service role key, fetching URLs, or anything that could show a reservation to its owner
- `database` if it changes `supabase/migrations/`
- `native` if it adds a native module or changes `app.json` plugins (a new development build is needed)
- `ai` if it touches the AI layer or the evaluation
- Any label or milestone the request names, for example `priority:high` from `wish-audit-to-issues`

Create a label if it is missing (safe to re-run):

```bash
gh label create "<label>" --repo "$REPO" --force
```

---

## Step 5 — Draft the issue body

Write the issue in English and name the UI by its English text from `src/locales/en.json` (`CLAUDE.md` § Language): "People → **Invite**", not the Swedish label. A description given in Swedish is translated, labels included, with the terms in `docs/ui-spec.md` § UI terms (en → sv).

### feat / fix / chore template

```markdown
## Context
<Why this ticket exists. What it gives the owner or the contacts who see the wishes.>

## Acceptance Criteria
- [ ] AC1: <Specific, testable outcome>
- [ ] AC2: <Specific, testable outcome>

## Scope Boundary
**In scope:** <what is included>
**Out of scope:** <what is explicitly not included>

## Technical Notes
- Layers touched: <Database / Edge Function / Data layer (src/lib/api, src/hooks) / UI (src/app, src/components)>
- Database change: <No / Yes — new migration + matching check in supabase/tests/rls_test.sql>
- Security impact: <None / RLS / auth / grants / service role / URL fetching / reservation visibility>
- New dependency: <No / Yes — name and reason, needs approval>
- Native change: <No / Yes — new development build needed>
- Spec reference: <docs/ui-spec.md section, docs/requirements.md id, or "none">
- Depends on: <WISH-<N> or "none">

## Edge Cases
- [ ] Loading, empty and error states; no network
- [ ] Works at 360 dp wide, in dark mode, with large system fonts
- [ ] The owner sees no reservation
- [ ] A contact it is not shared with, and a stranger, cannot see or change the owner's rows
- [ ] New UI text in both sv and en, no hardcoded values

## Definition of Done
- [ ] `npm run lint`, `npx tsc --noEmit`, `npm test` and `npm run build` pass
- [ ] RLS tests pass if the schema changed
- [ ] Tested on my own Android phone and in the emulator as owner (and as a contact who sees it and one who does not, if shared data is touched)
```

### bug variant

Replace Context with:

```markdown
## What Happens
<Actual behaviour>

## What Should Happen
<Expected behaviour>

## Steps to Reproduce
1. <Step>

## Where
- Screen: <e.g. a person's list>
- Signed in as: <owner / contact who sees it / contact who does not / stranger>
- Build: <development build / preview APK / version>
```

Keep Acceptance Criteria and Definition of Done, and add `- [ ] Regression test added` when the bug is in testable logic.

### spike template

```markdown
## Question to Answer
<The specific question>

## Time Box
<Maximum time, e.g. 2 hours>

## Output
- [ ] Findings posted as a comment on this issue, and in docs/ (ai-eval.md or a decision record) when they shape the product
- [ ] Recommendation with pros and cons
- [ ] Follow-up tickets created if needed
```

---

## Step 6 — Create the issue

```bash
gh issue create --repo "$REPO" \
  --title "[WISH-<NEXT>] <Imperative title>" \
  --body "<body from Step 5>" \
  --label "<labels>" \
  --milestone "<milestone>"
```

Then append a short entry to the matching epic in `TICKETS.md` so the plan stays complete:

```markdown
### WISH-<NEXT> · <type> · <Title>

Tracked in #<issue number>.
```

Do not commit. Leave the `TICKETS.md` change for the developer or the next ticket branch.

---

## Step 7 — Report back

```
✅ Issue created: [WISH-<NEXT>] <Title>
🔗 <issue URL>

Type:      <type>
Milestone: <Epic N — Name>
Labels:    <labels>

Suggested branch: wish/WISH-<NEXT>-short-description
```

---

## Import mode (`/wish-create-ticket import`)

Creates one issue per ticket in `TICKETS.md`. Run it once, before the first pull request, so that issue numbers line up with ticket numbers (issues and PRs share GitHub's counter).

1. **Read `TICKETS.md`.** Each `## Epic N — Name` heading is a milestone. Each `### WISH-<N> · <type> · <Title>` block is a ticket. Everything until the next `###` or `##` is its body: Context, Acceptance Criteria, Scope Boundary and any Checkpoint line. Epics without `###` tickets (planned, not broken down) and the "Later" list are skipped.

2. **Skip tickets that already exist:**
   ```bash
   gh issue list --repo "$REPO" --state all --json number,title --limit 300
   ```

3. **Create missing milestones** (gh has no milestone command, so use the API):
   ```bash
   gh api "repos/$REPO/milestones" --jq '.[].title'
   gh api "repos/$REPO/milestones" -f title="Epic 0 — Foundation" -f description="<first paragraph under the heading, if any>"
   ```

4. **Create the labels** with `gh label create ... --force`: the types, plus `security` for WISH-6, WISH-7, WISH-9, WISH-10, WISH-13, WISH-14, WISH-16, WISH-18, WISH-22 and WISH-23; `database` for WISH-6 and WISH-23; `native` for WISH-1, WISH-13, WISH-14 and WISH-20; `ai` for WISH-21 to WISH-25.

5. **Create the issues in WISH order**, one at a time:
   - Title: `[WISH-<N>] <Title>`
   - Body: the ticket's block from `TICKETS.md` as it is, plus a final line `Source: TICKETS.md`
   - The epic's `**Checkpoint:**` line goes in the body of the last ticket in that epic

6. **Close tickets that are already done** (every AC `- [x]`), with a comment that says so.

7. **Report** a table of WISH id, issue number, milestone and state. Flag any ticket where the issue number does not match the WISH number.

Before step 5, show the plan (number of milestones, labels and issues to create) and wait for the developer to say go.

---

## Rules

- Issues only. Never create branches, commit, push or edit code
- Titles: `[WISH-<N>] Short imperative description`
- Label and milestone commands must be safe to re-run
- Database, security and native changes are always flagged in Technical Notes
- New dependencies are flagged and need developer approval
