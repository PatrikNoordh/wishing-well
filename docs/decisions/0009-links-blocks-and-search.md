# 0009 — Sharing by link, blocking, and a schema ready for search and public lists

- **Status:** accepted
- **Date:** 2026-11-16
- **Builds on:** `0007-sharing-model.md`. (0008 is kept for the choice of default AI provider, WISH-25.)

## Context

After the sharing model, two wishes came up:

- **"Alla med länken"**, like Google Docs: send a link to someone who is not a contact yet (a colleague, a grandparent in a group chat) without an invite first.
- **Searchable profiles and public lists** later, maybe a GoWish-like app one day. Not in v1, but the developer does not want to redo the schema and migrate real data when it comes.

Once lists can reach people outside your contacts, you also need a way to shut someone out for good.

## Decision

- **A fourth way to share a list: `share = 'link'`.** The database makes a random 32-character code (`list_links`, owner-only). Whoever opens `.../l/<code>` signs in, `open_list_link()` records them in `list_link_access`, and they see that list, its owner's name, and the wishes in it that follow their lists. Overrides still win: a wish for chosen people or "only me" never shows through a link.
- **The owner stays in control of a link.** "Ny länk" (`regenerate_list_link()`) or leaving `link` shuts out everyone who came through the old one. The owner can see who opened it.
- **A link needs an account.** That is what makes "shut them out" and "who has seen it" possible, and what lets a link viewer reserve. The owner still never sees reservations, also not those made through a link.
- **Blocking.** `blocks` holds who blocked whom. A block hides the two from each other in every way (lists, wishes, profile, search, invites, links), ends the contact, link access and reservations between them, and is visible to the blocker only. Lifting a block brings nothing back.
- **Prepared, no screens in v1:**
  - `profiles.handle` (unique, `a-z 0-9 . _`, 3–30) and `profiles.discoverable` (off by default).
  - `search_profiles(query)`: name and handle of people who chose to be found, by handle prefix, at least 3 characters, at most 20 hits.
  - `share = 'public'`: any signed-in person sees the list.
  - All of it goes through the same `can_view_list`, `can_view_wish` and `can_see_profile`, and is tested now (checks 31–32), so turning it on is a UI ticket, not a migration.

## Alternatives

| Option | Why not |
|---|---|
| A link that works without an account (a web page) | No way to take it back from someone, no reserving, and a second, web-only path through the data. Can come later as an Edge Function that renders a read-only page |
| The code in `lists` itself | Every viewer of the list could read it, and pass it on as if it were theirs |
| Adding search and public lists when they are built | A new column on a table with real data, new branches in the visibility functions and new tests, all in a hurry. Cheap now, with no users |
| No blocking until there is a public part | Links already reach people outside your contacts |

## Consequences

- The visibility functions have one branch per way of sharing, and the tests have one check per branch (26–33).
- Whoever sees a list also sees its owner's profile, birthday included. That is fine for contacts and links the owner sent; public lists need a decision about the birthday before they get a screen (`docs/data-safety.md` § 5).
- A link can be passed on. The owner's answer is a new link; the UI says so next to the copy button.
- Later: a search screen and what a found person may do (send an invite?), public lists on the profile, a web view of a link, and reporting.
