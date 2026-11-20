# Requirements

What the app is for and what it must do. Tickets refer to these ids (R1, N1 …).

## Who it is for

| Person | Situation | What they need |
|---|---|---|
| **The owner** (everyone) | Sees something in a shop, at a friend's place or online and thinks "ooh, I want one of those!" | To save it in seconds, with a photo, find it again in a long list sorted into categories, and decide exactly who sees it |
| **A contact who sees it** (a partner, mum, a friend) | Wants to know what to give for birthdays and Christmas | To see what has been shared with them, reserve a gift, see what others have reserved, and find the cheapest shop |
| **A contact who does not** | Connected, but this was not shared with them | Nothing of it, not even that a list exists |
| **A stranger** | Anyone not connected | Nothing at all |

The first users are one family and their friends, all on Android. iPhone users follow when the Apple Developer Program is paid for; a public release may come later.

## Functional requirements

### People
- **R1** Sign in with an email code. No password.
- **R2** A profile with a display name and, optionally, a birthday. Never shows an email address to others.
- **R3** Invite people with a link; the invited person sees who invites them before accepting. Being contacts shares nothing by itself.
- **R4** No roles: everyone is a contact, and sharing is chosen per list and per wish.
- **R5** End a contact; they lose access to everything at once, and reservations and choices between the two are removed.
- **R6** Delete my account and everything that is mine.
- **R6a** Block anyone. We stop seeing and reaching each other in every way, and what was between us goes. They are not told.

### Wishes, categories and sharing
- **R7** One long main list, "All", with every wish, and categories (Christmas, Birthday, Home decor, Kitchen, Garden, my own) to filter it. A wish can be in several categories.
- **R8** Everything is private until I share it.
- **R9** Share "All" or a category with all my contacts in one tap, or with chosen contacts. They see the list and every wish in it, also ones added later.
- **R10** Override a single wish: only chosen contacts, or only me. The override wins over every list.
- **R11** Nobody sees the name of a list that is not shared with them.
- **R12a** Share a list with everyone who has its link, also people who are not my contacts yet. They sign in to open it. I can see who opened it, make a new link that shuts out everyone who came through the old one, or stop sharing by link.
- **R12** My own cards show who sees each wish, whichever way, with a small glass label.
- **R13** A wish has a title and optionally a photo, link, price, currency, shop and note.
- **R14** Add a wish with the camera in at most two taps from opening the app.
- **R15** Add a wish from a link, by pasting it or sharing it from another app (epic 4).
- **R16** Add a wish from a photo: the app suggests what it is and which shops sell it, cheapest first; I confirm or edit (epic 5).

### Contacts' wishes and reservations
- **R17** See everything a contact has shared with me, and the categories shared with me.
- **R18** Reserve a wish so others who see it know it is taken; undo my own reservation.
- **R19** The owner never sees whether their wish is reserved.
- **R20** A list of everything I have reserved, as a shopping list.

## Non-functional requirements

- **N1 Privacy:** data is stored in the EU. No location is collected in v1. Photos leave the phone without EXIF data. Others never see an email address.
- **N2 Security:** every rule in R3–R20 (R6a and R12a included) is enforced by the database (RLS), not by the app, and tested in CI.
- **N3 Speed:** saving a wish never waits for AI or the network; a list opens from cache at once and refreshes in the background.
- **N4 Accessibility:** labels on every control, 48 dp touch targets, large system fonts, enough contrast in light and dark mode.
- **N5 Language:** Swedish and English, both complete. The app starts in Swedish (default locale `sv`, fallback `en`); every text is written in English first (`CLAUDE.md` § Language).
- **N6 Platforms:** Android first; iPhone from the same code without changes in the code.
- **N7 Honest AI:** AI only suggests. A price shown as a shop's price is read from that shop's page.
- **N8 Cost:** free or nearly free at family scale (Supabase free tier, AI at a fraction of a krona per photo).

## Out of scope for v1

Payments, gift money pools, public profiles, public lists or search for people (the database is prepared, `docs/decisions/0009-links-blocks-and-search.md`), a web page for links, comments and chat, location, a web version, notifications.
