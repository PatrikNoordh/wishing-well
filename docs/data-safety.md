# Data safety map

How Wishing Well keeps data from being lost, left half done, or seen or changed by someone who should not. It lists where each piece of data lives, what a delete takes with it, who may read and write what, which guard stops each mistake, and the test that proves the guard works.

`/wish-data-safety` keeps this map up to date. In diff mode, run by `/wish-review-pr`, it reads this map and only the chains a branch touches. In full mode, run by `/wish-epic-close`, it rebuilds the map from the schema, the policies, the Edge Functions and the scripts.

**Last full run:** 2026-11-16, with the plan, before epic 0. Built from the one migration (`20261116000000_init.sql`) applied to a fresh Postgres 16 database after `supabase/tests/local_stub.sql`, with `supabase/tests/rls_test.sql` passing (checks 1–34). Each guard marked with a check below was also removed on purpose once, and the check failed. Two guards are a second layer that no single test can separate (see § 7).

**Rules for this file.** The repo is public, so this file holds no secrets, no real data and no open vulnerability. A gap is written down only once it has an issue or a line in `TICKETS.md`, and a gap that lets someone reach another person's data goes to an issue with the `security` label first. Once there are users outside the family, such a gap goes to a private GitHub security advisory instead.

**The two promises.** Nothing is seen by someone it was not shared with (security rule 7), and the owner of a wish never learns whether it is reserved (security rule 1). Every row in this map is read with both in mind. The sharing model is `docs/decisions/0007-sharing-model.md`; links, blocks and the prepared search are `docs/decisions/0009-links-blocks-and-search.md`.

---

## 1. Where the data lives and what a delete takes with it

| Data | Owner key | References (on delete) | Deleting it also removes |
|---|---|---|---|
| `auth.users` | `id` | — | its `profiles` row (cascade), and through it everything below. Not its photos: Storage has no foreign key |
| `profiles` | `id` = the Auth user's id | `auth.users(id)` cascade | its connections, blocks (both sides), link access, invites, lists (the main list included), wishes, and every row that names it as a chosen person or reserver (cascade). Invites it accepted keep the row with `accepted_by` set to null |
| `connections` | the pair `(user_a, user_b)`, `user_a < user_b` | `profiles(id)` cascade, both sides | through the trigger `connections_cleanup`: each side's reservations on the other's wishes, and each side's rows in the other's `wish_audience` and `list_shares` (checks 24, 25) |
| `blocks` | `blocker_id`; the pair `(blocker_id, blocked_id)` is the key, never yourself | `profiles(id)` cascade, both sides | nothing. Creating one runs `blocks_cleanup` (check 33). Lifting one brings nothing back |
| `invites` | `inviter_id` | `profiles(id)` cascade · `accepted_by` → `profiles(id)` set null | nothing |
| `lists` | `owner_id`; one main list per owner (`is_main`, partial unique index) | `profiles(id)` cascade | its `list_shares` and `list_items` (cascade). **Not its wishes**: deleting a category leaves them in "Allt". The main list cannot be deleted while the profile exists (`main_list_protected`, check 17) |
| `list_links` | the list's owner; one code per list | `lists(id)` cascade | nothing. Made by `lists_link_lifecycle` when `share` becomes `link`, deleted when it stops, given a new code by `regenerate_list_link()` (checks 26, 29, 30) |
| `list_link_access` | the person who opened the link, `(list_id, user_id)` | `lists(id)` cascade · `profiles(id)` cascade | nothing. Cleared on a new code, when the list stops being shared by link, and by a block (checks 29, 30, 33) |
| `list_shares` | the list's owner | `lists(id)` cascade · `profiles(id)` cascade | nothing |
| `wishes` | `owner_id` | `profiles(id)` cascade | its `list_items`, `wish_audience` and reservation (cascade). Not its photo |
| `list_items` | the list's and the wish's owner (always the same, `owner_mismatch`) | `lists(id)` cascade · `wishes(id)` cascade | nothing |
| `wish_audience` | the wish's owner | `wishes(id)` cascade · `profiles(id)` cascade | nothing |
| `reservations` | `reserved_by`; one per wish (`wish_id` is the key) | `wishes(id)` cascade · `profiles(id)` cascade | nothing |
| `storage.objects`, bucket `wish-images` | the first folder of the path, `<owner_id>/<file>` | none to the tables | nothing. Private bucket, JPEG/PNG/WebP, at most 5 MB |

**Kept in step by the database, not by the client** (security rule 5):

- `lists.owner_id`, `wishes.owner_id` and `reservations.reserved_by` default to `auth.uid()` and are not in any grant (checks 16, 22). Owners and `is_main` never change (`owner_change_not_allowed`; `is_main` not granted, check 17).
- The main list is created by `handle_new_user` (check 1), has no title (check constraint, check 17), holds no items (`main_list_has_no_items`, check 17) and cannot be deleted while the account exists (`main_list_protected`, check 17).
- A category holds only its owner's wishes (`owner_mismatch` and the `list_items_insert` policy, check 16).
- `wishes.image_path` must start with the owner's id (`image_path_not_owned`, check 17).
- Link codes and link access are only written by the database: `lists_link_lifecycle`, `open_list_link()` and `regenerate_list_link()`. No client grant on insert or update (checks 26–30).
- `profiles.handle` is lower case, 3–30 of `a-z 0-9 . _`, and unique; `discoverable` is off by default (check 32).
- Connections are only written by `accept_invite()` (checks 7, 8). An invite lasts at most 7 days (`invites_max_7_days`, check 4).

### The delete chains

| What is deleted | How | Order, and what a failure leaves |
|---|---|---|
| A reservation | client delete, only by the one who made it | one row (check 21) |
| A wish | client delete by the owner | the row, its category memberships, chosen people and reservation in one statement. The photo is deleted by the app first (WISH-14 AC5); if that fails the wish stays, so no row ever points at a missing photo |
| A category | client delete by the owner | the list, its shares and its memberships in one statement. Its wishes stay in "Allt" |
| A connection | client delete by either side | the connection, then the cleanup trigger in the same transaction (check 24) |
| A block (created) | client insert by the blocker | the block, then `blocks_cleanup` in the same transaction: the connection (and through it `connections_cleanup`), link access both ways, reservations both ways (check 33) |
| A link | the owner sets `share` away from `link`, or asks for a new link | the code and every access row in the same statement (checks 29, 30) |
| An invite | client delete by the inviter | one row |
| An account | the `delete-account` Edge Function (WISH-10) | the photo folder first, then the Auth user with the service role; the rest cascades in one statement, the main list included (check 34). If the folder delete fails, nothing else is deleted and the call can be repeated |

---

## 2. Who may read and write

### Rows (RLS) and table privileges

Every table in `public` has RLS on. `anon` has no privilege on any of them (check 2).

| Table | Policies | `authenticated` may | Column grants (insert / update) |
|---|---|---|---|
| `profiles` | select: `can_see_profile` (self; or not blocked and a contact or the owner of a list the caller can see); update: self | select, update | update `display_name, birthday, handle, discoverable` only (checks 9, 27, 32) |
| `blocks` | select, insert, delete: the blocker | select, insert, delete | insert `blocked_id` only (check 33) |
| `connections` | select and delete: either side | select, delete | none: created only by `accept_invite()` (check 8) |
| `invites` | select, insert, delete: the inviter | select, insert, delete | insert `expires_at` only, and only shorter than 7 days (checks 3–5) |
| `lists` | select: owner or `can_view_list`; insert, update, delete: owner | select, insert, update, delete | insert and update `title, share` (checks 10–12, 16, 17) |
| `list_links` | select: the list's owner | select | none (checks 26, 29) |
| `list_link_access` | select and delete: the person themself or the list's owner | select, delete | none: written by `open_list_link()` (checks 27, 28) |
| `list_shares` | select, insert, delete: the list's owner; insert only for a contact | select, insert, delete | insert `list_id, person_id` (check 15) |
| `wishes` | select: owner or `can_view_wish`; insert, update, delete: owner | select, insert, update, delete | insert and update `title, note, url, price, currency, store_name, image_path, audience` (checks 10–13, 16) |
| `list_items` | select: the list's owner, or someone who `can_view_list` **and** `can_view_wish`; insert: owner of both; delete: the list's owner | select, insert, delete | insert `list_id, wish_id` (checks 12, 14, 16) |
| `wish_audience` | select, insert, delete: the wish's owner; insert only for a contact | select, insert, delete | insert `wish_id, person_id` (check 15) |
| `reservations` | select: the reserver, or anyone who `can_view_wish` and does not `owns_wish`; insert: as self, on a wish you can see and do not own; delete: the reserver | select, insert, delete | insert `wish_id` only (checks 18–22) |
| `storage.objects` in `wish-images` | select: own folder, or `can_view_image`; insert, update, delete: own folder | Storage API | — (check 23) |

### Security definer functions

Each runs past RLS to answer one question about the caller, or to do one controlled write.

| Function | What it does | Who may run it |
|---|---|---|
| `is_connected(other)` | Is the caller a contact of `other`? | `authenticated` |
| `owns_list(list)`, `owns_wish(wish)` | Does the caller own it? | `authenticated` |
| `is_blocked(other)` | Has either of the two blocked the other? | `authenticated` |
| `can_view_list(list)` | Owner; or signed in, not blocked, and by `share`: `contacts` → a current contact; `people` → a current contact in `list_shares`; `link` → has opened the current link; `public` → anyone; `private` → no | `authenticated` (checks 10–12, 24–31, 33) |
| `can_view_wish(wish)` | **The one place that decides who sees a wish.** Owner; or signed in, not blocked, and: `only_me` → no; `people` → a current contact chosen in `wish_audience`; `lists` → can see the owner's main list or a category the wish is in. Used by wishes, list items, reservations and photos | `authenticated` (checks 10–14, 18, 21, 23–28, 31, 33) |
| `can_see_profile(person)` | Self; or not blocked and a contact, or the owner of a list the caller can see. Being findable does **not** open the profile | `authenticated` (checks 9, 27, 32, 33) |
| `can_view_image(path)` | Is there a wish the caller can see that uses this photo? | `authenticated` (check 23) |
| `preview_invite(code)` | Inviter's name and expiry for a valid code, to a signed-in caller | `authenticated` (check 5) |
| `accept_invite(code)` | Checks the invite and the caller, creates the connection once, marks the invite used. Across a block it answers `invite_not_found` | `authenticated` (checks 4–7, 33) |
| `open_list_link(code)` | For a signed-in caller and a current code, not across a block: records access and returns the list and owner. Otherwise `link_not_found` | `authenticated` (checks 26–30, 33) |
| `regenerate_list_link(list)` | Owner only (`not_allowed`); gives the list a new code and clears all access (`list_not_shared_by_link` if not shared by link) | `authenticated` (check 29) |
| `search_profiles(query)` | *Prepared, no screen in v1.* Name and handle of people who chose to be found, by handle prefix, at least 3 characters, wildcards escaped, never yourself, never across a block, at most 20 | `authenticated` (checks 32, 33) |
| `handle_new_user()`, `lists_guard()`, `list_items_guard()`, `connections_cleanup()`, `lists_link_lifecycle()`, `blocks_cleanup()` | Triggers | nobody directly (check 2) |

---

## 3. The promises, guard by guard

### Nothing is seen by someone it was not shared with

| Way it could leak | Guard | Test |
|---|---|---|
| A new wish or list is visible before sharing | `share` defaults to `private`, `audience` to `lists`; the main list starts private | checks 1, 10 |
| A wish for chosen people or "only me" shows through a shared list | `can_view_wish` looks at `audience` first; `people` and `only_me` ignore the lists | checks 12, 13 |
| The name of an unshared category ("Present till Bo") | `lists_select` uses `can_view_list`; the main list's sharing does not reveal categories | checks 11, 12 |
| That a visible wish sits in an unshared category | `list_items_select` needs both the list and the wish | checks 12, 14 |
| Who else was chosen | `list_shares` and `wish_audience` are readable by the owner only | check 15 |
| A photo of a hidden wish | `can_view_image` goes through `can_view_wish` | check 23 |
| A reservation reveals a hidden wish exists | reservations follow `can_view_wish`; trying to reserve a hidden wish is refused before the unique key is checked | checks 18, 21 |
| A former contact keeps access ("all contacts" still set) | every path needs a current connection; cleanup removes their choices | checks 24, 25 |
| Sharing with a stranger | `list_shares` and `wish_audience` inserts need `is_connected` | check 15 |
| Guessing a link | the code is 32 random hex characters, readable only by the owner | check 26 |
| A link that is passed on too far | the owner makes a new link, or stops sharing by link; everyone who came through the old one loses access | checks 29, 30 |
| A link list shows wishes for chosen people or "only me" | the same `can_view_wish`; overrides win over a link too | check 27 |
| A link viewer sees the owner's other lists | access is per list; other lists keep their own `share` | check 27 |
| Being findable exposes the profile (birthday) or lists | `search_profiles` returns name and handle only; `can_see_profile` ignores `discoverable` | check 32 |
| Search used to list everyone | at least 3 characters, prefix only, `%` and `_` escaped, at most 20 hits, opt-in | check 32 |
| A blocked person still sees or reaches you | `is_blocked` in every visibility function, in search, invites and links; the block row is hidden from them | check 33 |

### The owner never learns a wish is reserved

| Way the owner could find out | Guard | Test |
|---|---|---|
| Read `reservations` | `reservations_select` excludes `owns_wish` — also for reservations made by someone who came by link | checks 19, 28 |
| Try to reserve (refused only if taken?) | insert is refused for the owner before the unique key is checked, also with `on conflict do nothing` | check 20 |
| Delete a reservation and count rows | delete only by the reserver | check 20 |
| A column or count on `wishes` | there is none | schema review (`/wish-data-safety full`) |
| A cached query in the app after switching accounts | query keys include the user id; sign-out clears the cache | WISH-7 AC4, WISH-16 AC4 |
| A push message or an email | none exist in v1 | — (rule 1 covers future ones) |

---

## 4. Flows across the database and Storage

There is no shared transaction between Postgres and Storage. Each flow picks the order whose worst case is harmless.

| Flow | Order | Worst case |
|---|---|---|
| Add a photo to a wish (WISH-14) | wish row first, then upload, then `image_path` | a wish without a photo (retry offered); or a file in the owner's folder that no wish points at, readable only by the owner |
| Replace or delete a photo | delete the old file, then update or delete the row | a wish without a photo |
| Delete an account (WISH-10) | folder first, then the Auth user | a half-deleted folder, and the account still there; running it again finishes |

---

## 5. Decisions

- **Private until shared.** New wishes follow their lists, and every list starts private, so nothing is visible until the owner shares.
- **The wish's own choice wins, both ways.** `people` shows a wish to exactly the chosen contacts, whatever the lists say; `only_me` hides it from everyone. Chosen by the first users for the intimate-gift case.
- **One reservation per wish** (`wish_id` is the primary key). Simple and enough for gifts.
- **Everything between two people goes when they stop being contacts** (`connections_cleanup`), and every path also checks the connection, so a missed row can never leak (check 25).
- **Taking back a share keeps reservations.** A reservation by someone who no longer sees the wish stays, hidden from them, and comes back if the wish is shared again. Chosen over deleting it because the change may be a mistake that is undone.
- **No email in `profiles`.** Others see a chosen name only.
- **A link needs an account.** Opening a link signs you in first and records that you opened it, so the owner can see who came and a new link can shut them out. A web page without an account is a later idea.
- **Whoever sees a list sees its owner's profile, birthday included.** Fine for contacts and for a link the owner sent. For public lists (prepared, no screen in v1) the birthday may need its own setting; decide before public lists get a screen.
- **Being findable opens nothing.** It only makes name and handle show up in search. Whether a found person can then send an invite is decided with the search screen.
- **A block is silent and one-way to lift.** The blocked person is not told; lifting a block does not bring back the contact, link access or reservations.

## 6. Human steps

| Step | Who | Guard |
|---|---|---|
| Applying a migration to the project | developer, after `--dry-run` | `CLAUDE.md` § Workflow; `.claude/settings.json` refuses remote commands for Claude |
| Setting Edge Function secrets (AI keys) | developer | never in the repo; `.env.example` lists none |
| EAS builds and updates that reach phones | developer | `.claude/settings.json` refuses `eas` for Claude |

## 7. Known gaps

None known.

**Second layers no test can separate.** The `is_blocked` checks in `can_view_wish` and `can_see_profile` survived being removed: a block already ends the contact and link access, and `can_view_list` refuses across a block, so every other path is shut too. They stay as a second layer in case a later path (for example a public wish) skips the list. Any new path that does not go through `can_view_list` needs its own block test.
