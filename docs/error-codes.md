# Error codes

The database and the Edge Functions never return user-facing text. They return a code; the app looks up the code in `src/locales/en.json` and `sv.json` (key `errors.<code>`) and shows the translated message. An unknown code shows `errors.unknown`.

## From the database

| Code | Raised by | When |
|---|---|---|
| `not_signed_in` | `accept_invite()`, `open_list_link()` | No session |
| `invite_not_found` | `accept_invite()` | The code does not exist, or a block is in the way |
| `invite_used` | `accept_invite()` | Already accepted |
| `invite_expired` | `accept_invite()` | Past its expiry (at most 7 days) |
| `invite_own` | `accept_invite()` | The inviter opened their own link |
| `already_connected` | `accept_invite()` | The two are already contacts |
| `owner_change_not_allowed` | `lists_guard`, `wishes_guard` | Changing the owner of a list or wish, or whether a list is the main list |
| `main_list_exists` | `lists_guard` | A second main list (only the database makes main lists) |
| `main_list_protected` | `lists_guard` | Deleting "All" while the account exists |
| `main_list_has_no_items` | `list_items_guard` | Putting a wish "in" the main list (every wish is in it already) |
| `owner_mismatch` | `list_items_guard` | Putting a wish in a category that belongs to someone else |
| `image_path_not_owned` | `wishes_guard` | A wish's photo path is not in the owner's folder |
| `link_not_found` | `open_list_link()` | The code does not exist, the list is no longer shared by link, a new link replaced it, or a block is in the way. One answer for all, so a link reveals nothing |
| `list_not_shared_by_link` | `regenerate_list_link()` | Asking for a new link for a list that is not shared by link |
| `not_allowed` | `regenerate_list_link()` | Someone other than the owner asks for a new link (also mapped from `42501`, below) |

## Mapped by the app from Postgres error classes

| Code | Postgres | When |
|---|---|---|
| `already_reserved` | `23505` on `reservations` | Someone reserved the wish first |
| `handle_taken` | `23505` on `profiles.handle` | Someone else has that handle (prepared, no screen in v1) |
| `not_allowed` | `42501` | RLS or a grant refused the action (a share taken back, a contact ended) |
| `invalid_input` | `23514` | A check constraint failed (too long, bad URL, negative price, a title on "All") |
| `network` | — | No connection or timeout |

## From Edge Functions

Added by the tickets that create the functions (WISH-10, WISH-18, WISH-22, WISH-23), for example `link_not_allowed`, `link_unreachable`, `link_unreadable`, `ai_unavailable`.
