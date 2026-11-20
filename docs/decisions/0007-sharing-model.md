# 0007 — Sharing like Google Docs: private until shared, and the wish's own choice wins

- **Status:** accepted
- **Date:** 2026-11-16
- **Replaces:** the first model (partner and friends as roles, a visibility per list, and a wish that could only narrow its list)

## Context

The first model had roles (one partner, many friends) and lists with a fixed visibility. Talking it through with the first users showed what they actually want:

- No roles. "Partner", "family" and "friend" mean different things to different people. They want to pick people, the way you share a Google Doc.
- One long list of everything, with categories (Christmas, Birthday, Home decor, Kitchen, Garden) to find their way. A wish can belong to several.
- Share a whole category with someone in one tap ("Sofia sees all of Home decor, including what I add later").
- Share a single wish with exactly the right people — an intimate wish only for the partner — even when it sits in a list shared with everyone.
- Nothing visible until they choose. Not even the names of their categories.

Example: Jakob sees three things, Sofia ten, mum fifteen, depending only on what has been shared with each.

## Decision

- **Contacts, no roles.** An accepted invite makes two people contacts. That shares nothing by itself.
- **Lists:** every person has one main list, "All", holding every wish (`lists.is_main`), and any number of categories (`lists`, `list_items`). A wish can be in many categories.
- **A list is shared** as `private` (default), `contacts` (all my contacts) or `people` (chosen contacts in `list_shares`). Whoever it is shared with sees the list's name and every wish in it that follows its lists, including wishes added later.
- **A wish follows its lists by default** (`audience = 'lists'`): it is visible to whoever sees "All" or any category it is in.
- **A wish can override** (`people`: exactly the chosen contacts in `wish_audience`; `only_me`). The override always wins, in both directions: a wish for Bo only is hidden from everyone else even in a list shared with all contacts, and visible to Bo even if no list is shared with him.
- **Nobody sees the name of a list that is not shared with them,** or that a wish is in such a list.
- **Every way of seeing also needs a current connection.** Ending a contact hides everything at once and cleans up reservations and choices between the two.
- **One function decides** who sees a wish (`can_view_wish`) and one who sees a list (`can_view_list`). Wishes, list items, reservations and photos all go through them.

## Alternatives

| Option | Why not |
|---|---|
| Roles (partner, friends, family) | Rigid; the users wanted to pick people |
| Several separate lists, each with its own audience | A wish would live in one list only; the users wanted one long list with categories on top |
| Category sharing without a per-wish override | The intimate-gift case needs a wish to beat its lists |
| Per-wish sharing only, no list sharing | Too many taps for "Sofia sees all of Home decor" |

## Consequences

- One mental model for the user: lists are folders, wishes are files, and a file's own setting wins.
- The glass label on the owner's card shows the result, whichever way it came ("Bo, Cleo +2"), and the sheet explains the ways ("Via Christmas: Mum, Bo").
- 26 RLS checks cover the model (34 after `0009`), and every guard in `can_view_wish` and `can_view_list` was broken on purpose once to see a check fail.
- Groups of contacts ("Family") can be added later as a shortcut for choosing people, without changing the rules.
