---
name: wish-data-safety
description: "Check that no Wishing Well data is lost or left half done, that nobody sees or changes data they should not, and that the owner never learns a wish is reserved. Diff mode (default) checks the current branch against docs/data-safety.md and reads only the chains the diff touches; full mode checks the whole schema, policies, grants, Edge Functions and scripts and rebuilds the map. Use when asked for a data-safety check, from /wish-review-pr (diff) and /wish-epic-close (full), or before a migration that changes who owns or sees rows."
argument-hint: "diff (default) or full. diff checks the current branch against main"
allowed-tools: Bash(git diff *), Bash(git log --oneline *), Bash(git rev-parse *), Bash(grep -rn *), Bash(bash supabase/tests/run_local.sh), Bash(psql *), Bash(createdb *), Bash(dropdb *), Read, Glob, Grep
---

# Data safety check — Wishing Well

Checks three things: **no data is lost or left half done**, **nobody sees or changes data they should not**, and **the owner never learns a wish is reserved**. The map in `docs/data-safety.md` says where each piece of data lives, what a delete takes with it, who may read and write it, which guard stops each mistake, and which test proves the guard. This skill checks a change against the map, or the whole app, and keeps the map true.

The mode is: `$ARGUMENTS` (empty means `diff`).

**Never run a remote Supabase command**, not even a read-only one (`CLAUDE.md` § Workflow). When the check needs something from the project, print the command for the developer to run and paste back.

---

## Diff mode

### Step 1 — Is a data path touched?

```bash
git diff origin/main...HEAD --name-only
```

The data paths are `supabase/`, `src/lib/api/`, `src/hooks/`, `src/lib/queryKeys.ts`, `src/contexts/` (the session and the cache clear on sign-out), `src/lib/supabase/`, anything that uploads or deletes photos, anything that shows reservations, `eval/` (photos must show products only), `.github/workflows/`, `.claude/settings.json`, `app.json` and `eas.json`.

If none is touched, answer in one line and stop:

```
Data safety: no data path touched (<n> files, all <UI / docs / tests>). Nothing to check.
```

### Step 2 — Read only what the diff reaches

1. Read `docs/data-safety.md`.
2. Read the diff of the data paths: `git diff origin/main...HEAD -- <paths>`.
3. For each changed table, function, policy, grant, bucket or flow, find its rows in the map and read the files those rows name: the migration that last defined it, the Edge Function handler, the `src/lib/api/` file, the checks in `rls_test.sql`. Follow a delete chain one step past the changed table in each direction.
4. If the diff adds, drops or moves a foreign key, or renames a table or a column a key uses, grep the data layer for PostgREST embeds across it, for each table at either end of the key: `grep -rnE "<table>(!\w+)?\(" src/lib/api/`. An embed such as `profiles(display_name)` or `list_items(count)` in a supabase-js `select` needs a foreign key between the two tables; without one PostgREST answers `PGRST200` at run time, and no type check or unit test sees it. Each embed the diff breaks is a 🔴 finding, and one without a test that runs the query against a real database is a gap.
5. Do not read the rest of the repo. If the map has no row for something the diff changes, that is a finding in itself.

### Step 3 — The lenses

Ask each question of every change the diff reaches. Each "yes" or "not sure" becomes a row in the risk table.

| Lens | Questions |
|---|---|
| **The promise** | Can the owner learn, directly or by inference, that a wish is reserved? Through a row, a count, a sort, a timing or error difference, a cache, a notification, a log? |
| **Who** | Can a stranger, a former contact, a contact the wish or list is not shared with, someone who sees the list but not a wish overridden away from them, a deleted account, `anon` or Claude reach this? |
| **Order, repeat, half done** | Can the steps run in the wrong order? Run twice? Stop halfway? |
| **References and deletes** | What references this row, and what does it reference, with which `on delete`? Does a delete reach data it should not, or leave orphans (rows or photos)? |
| **Database and Storage** | Does a flow write to both without a shared transaction? Is its worst case written down in § 4? |
| **Ids and shared values** | Does an id ever change? Do two concepts share one value, and does the change treat one as the other? A profile's id is its Auth user's id, and a photo's folder in `wish-images` is its owner's id (security rule 5), so a change that writes ids or storage paths itself must keep both. Is a placeholder (the nil UUID) ever stored as real? |
| **Between `db push` and merge** | Does the code on `main` still work against the migrated database? What if the PR is closed after the push? |
| **Guards in layers** | Which layers guard this: policy, grant, trigger, check constraint, test? Does the change weaken one, or rest on the app alone (rule 8)? Does a new definer function check its caller and answer only about the caller? |
| **Proof** | For every guard the change adds or relies on: is there a test that fails when the guard is removed? Name the file and check number. A guard without such a test is a gap |

### Step 4 — Report

```
## Data safety — <branch or PR>

Mode: diff. Data paths touched: <list>. Map rows read: <§ and rows>.

| Risk | What happens | Severity | Guard | Test |
|---|---|---|---|---|
| <the change and the lens> | <the concrete outcome> | 🔴 / 🟡 / 🟢 | <what stops it, or "none"> | <file:check, or "none"> |

Map: <updated § n, rows …> / <no change needed>
Commands for the developer: <only if something has to be checked on the project, else "none">
```

Severity:

- 🔴 **The owner can learn about a reservation; data lost; or seen or changed by someone who should not.** A blocker, fixed on the branch before the merge.
- 🟡 **Half done but recoverable**, an orphaned photo, or a guard without a test.
- 🟢 **Cosmetic**: a stale map row, a comment that overstates a guard.

When every lens comes out clean, say so in one line under the table, and list the guards and tests that make it clean.

### Step 5 — Keep the map true

If the diff changes a chain, a policy, a grant, a guard, a flow across the database and Storage, or a human step, update the matching rows of `docs/data-safety.md` on the branch. Add a row for anything new. A gap goes in § 7 only once it has a line in `TICKETS.md` or an issue.

---

## Full mode

The same lenses over everything. It rebuilds the map from what is really there, not from the old map.

1. **Build the schema** in a throwaway database, never the local Supabase stack's data and never the project: `bash supabase/tests/run_local.sh` must pass, then build once more by hand to read the result:

   ```bash
   createdb wish_safety && psql -q -d wish_safety -f supabase/tests/local_stub.sql \
     && for f in supabase/migrations/*.sql; do psql -q -v ON_ERROR_STOP=1 -d wish_safety -f "$f"; done
   ```

   ```sql
   -- foreign keys and their on delete
   select conrelid::regclass, conname, pg_get_constraintdef(oid)
   from pg_constraint where contype = 'f' and connamespace = 'public'::regnamespace order by 1;
   -- RLS on every table
   select relname, relrowsecurity from pg_class
   where relnamespace = 'public'::regnamespace and relkind = 'r' order by 1;
   -- policies, also on storage.objects
   select schemaname, tablename, policyname, cmd, qual, with_check
   from pg_policies where schemaname in ('public', 'storage') order by 1, 2, 4;
   -- table and column grants
   select table_name, grantee, string_agg(privilege_type, ',')
   from information_schema.role_table_grants
   where table_schema = 'public' and grantee in ('anon', 'authenticated') group by 1, 2 order by 1, 2;
   select table_name, privilege_type, string_agg(column_name, ',')
   from information_schema.column_privileges
   where table_schema = 'public' and grantee = 'authenticated'
     and privilege_type in ('INSERT', 'UPDATE') group by 1, 2 order by 1, 2;
   -- triggers, and functions with their security mode and who may run them
   select tgrelid::regclass, tgname, pg_get_triggerdef(oid) from pg_trigger where not tgisinternal order by 1, 2;
   select proname, pg_get_function_identity_arguments(oid), prosecdef, proacl
   from pg_proc where pronamespace = 'public'::regnamespace order by 1;
   -- check constraints, unique keys and buckets
   select conrelid::regclass, conname, pg_get_constraintdef(oid)
   from pg_constraint where contype in ('c', 'u', 'p') and connamespace = 'public'::regnamespace order by 1;
   select id, public, file_size_limit, allowed_mime_types from storage.buckets;
   ```

   Then `dropdb wish_safety`.

2. **Read the Edge Functions**: who the caller must be, which client reads, what the service role does, what is fetched from where, and the order of each step across the database and Storage.
3. **Read the data layer**: `src/lib/api/`, `src/hooks/`, `src/lib/queryKeys.ts`, `src/contexts/`, the photo upload and delete code, every place reservations are shown.
4. **Map every guard to its proof**: the `OK <n>:` lines in `rls_test.sql`, the Deno handler tests, the app tests.
5. **Try what looks open.** When a lens suggests a gap, prove it in the throwaway database inside a transaction that is rolled back, as the person who would exploit it, before writing it down.
6. **Check the decisions** in § 5 one by one against the code.
7. **Rewrite `docs/data-safety.md`**: every section, the date and the `main` sha of this run.
8. **Report** the risk table for the whole app, and a short list of what changed in the map since the last full run.

---

## Rules

- Never run a remote Supabase command; print it for the developer.
- Never write a secret, real data or an exploit to `docs/data-safety.md`, an issue or a review: the repo is public. A gap that reaches another person's data, or lets an owner learn about a reservation, goes to an issue with the `security` label before it goes in the map, and once there are real users (the family's phones, from epic 6), to a private GitHub security advisory instead.
- Never call something a guard without naming its proof, or "none".
- Do not fix findings from this skill unless the caller says so: `/wish-review-pr` fixes 🔴 on the branch, `/wish-epic-close` triages the rest.
- In diff mode, never read past the chains the diff reaches.
