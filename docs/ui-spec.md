# UI spec

Every screen, what it shows and does, and its states. UI text is quoted by its English text from `src/locales/en.json`; the Swedish translation lives in `src/locales/sv.json`, and the terms used for both are in [UI terms](#ui-terms-en--sv) at the end. The app starts in Swedish for users (`CLAUDE.md` § Language). Visual design comes from the design system artifact (https://claude.ai/artifact/FM4zenrV1VAiiQ1M81sn1o; `docs/decisions/0010-look-and-pictures.md`: calm PawPals colours with a cream-to-sage gradient, off-white cards, one terracotta accent, Inter headings over Nunito text, a wink of humour in the words) and the building blocks in `src/components/ui/` (WISH-3, WISH-4). Sharing follows `docs/decisions/0007-sharing-model.md`.

## Navigation

Four bottom tabs around one big action in the middle (`docs/decisions/0012-tabs-and-icons.md`):

| Tab | Screen | |
|---|---|---|
| **Wishes** | "All" with category chips (My wishes) | Start screen |
| **People** | Contacts and invites | |
| — | **Add** (round terracotta camera button, always visible, in the middle of the tab bar) | Opens the camera at once (at most two taps) |
| **Reserved** | What I am buying | |
| **Me** | Profile and settings | |

The profile avatar in the header of **Wishes** also opens **Me**. Icons come from Lucide.

## Screens

### Sign-in
- "Wishing Well" and the slogan (`app.slogan`: "Ooh, I want one of those!" in `en.json`, its Swedish translation in `sv.json`) above the form.
- Email field → "Send code" → six-digit code field → signed in.
- States: sending, wrong code, expired code (with "Send a new code"), no network.

### Onboarding (first sign-in)
- "What's your name?" (display name, required), birthday (optional, year optional), then one sentence: "Everything you add is yours alone until you choose to share it." Then straight to the camera.

### My wishes ("All")
- Header: "All", a sharing line under it ("Only you can see this" / "Shared with all your contacts" / "Shared with Bo, Cleo +2"), tap to change.
- **Category chips** in a horizontal row: "All", "Christmas", "Birthday", "Home decor" …, and "+ New category". A chip filters the grid; a long-press opens the category's menu (rename, share, delete).
- A grid of wish cards: photo, title, price and shop.
- **Glass label** in the top-left corner of each photo, on my own cards only: who sees the wish, whichever way. "Everyone", "Bo, Cleo +2", "Only me". Tap opens **Who can see this?**.
- **Never** any sign of reservations.
- Empty: "Your first wish", the slogan under it, and a button to the camera.

### A category (mine)
- The same grid filtered to the category, with the category's own sharing line and "Share".

### Share (for "All" or a category)
- "Only me" (default) · "All my contacts" (one tap) · "Chosen people" (checkboxes for my contacts) · "Anyone with the link".
- "Anyone with the link": the link with "Copy link" (then "Copied") and "Share" (share sheet), "New link" (confirmation: "The old link stops working, also for people who have already opened it."), and "Opened by" with names. Under the copy button: "Anyone who has the link and signs in can see the list. Only send it to people you want to see it."
- Explains: "They see the list's name and everything in it, including what you add later. Wishes you have set yourself are not affected."

### Who can see this? (one wish)
- "Same as the lists" (default) — with who that is right now and how: "Via All: all contacts", "Via Christmas: Mum, Bo".
- "Only chosen people" — checkboxes for my contacts, pre-filled with who sees it now.
- "Only me".
- Says: "Your choice here wins over the lists."

### A wish (mine)
- Photo, title, price and shop, link ("Open in shop"), note, categories (chips, editable), the glass label.
- From epic 5: offers, cheapest first ("Cheapest" on the first), each with shop, price and "price checked <time>".
- Actions: edit, categories, "Who can see this?", delete.

### Add
1. Camera opens at once; switch to gallery, or "Paste link" (epic 4).
2. After the photo: the wish is saved at once, private, in "All" (and in the category chip that was selected, if any), and the edit form opens with the photo. Title is required.
3. From epic 5: "Looking for prices…" while the AI works; then a sheet **"Is this right?"** with the suggested name and offers. One tap accepts; everything can be edited; "Search yourself" opens the browser.

### People
- My contacts and open invites (with "Revoke").
- Actions: "Invite" → share sheet with the link; open a person; "Remove contact" (confirmation says what goes with it); block.
- **Block** (in a person's menu, also for someone who came by link): confirmation "You will no longer see or reach each other. What you have shared, your reservations and the contact are removed. Anna is not told." Blocked people are listed under Settings → Blocked, with "Unblock" ("Nothing comes back.").

### A list link (opened from a link)
- Signs in first if needed, then opens the list as on "A person", filtered to that list: owner's name, the list's name, its cards, reserve.
- No invite button: becoming contacts still goes through an invite from one of the two.
- Errors: `link_not_found` → "This link no longer works. Ask for a new one." (the same message for every reason).

### Invite (opened from a link)
- "Anna wants to add you as a contact." → "Accept" / "Not now".
- After accepting: "You're now contacts. Anna chooses what you get to see."
- Errors: used, expired, own invite, already contacts — each with its own message.

### A person
- Name, birthday ("Birthday in 12 days").
- **"All I can see"** and chips for the categories shared with me. Nothing hints at what I cannot see.
- Cards with photo, title, price, shop and **"Reserved"** or **"I'll buy it"**. My own reservation shows "You're buying it" and "Undo". If someone else reserved it a moment earlier: "Someone got there first".

### Reserved
- Everything I have reserved, grouped by person: photo, title, price, link.
- Actions: "Bought" (marked on the phone in v1), "Undo reservation".
- Empty: "Nothing reserved yet."

### Me (profile and settings)
- Name, birthday, language (follow the phone / Swedish / English), theme (follow the phone / light / dark), app version, "Log out", "Delete my account" (confirmation lists what disappears).

## States, everywhere

Every screen that loads data has **loading** (skeleton), **empty** (teaches the next step) and **error** (what went wrong, "Try again"). Without network, cached data is shown with a quiet "offline" note and writes wait or fail clearly. Dialogs confirm with the action's own name or "Done", and close with "Cancel".

## Rules

- Works from 360 dp wide, in light and dark mode, with large system fonts.
- All text through `t()`, written in `en.json` first and translated in `sv.json`.
- The owner sees no reservation anywhere: not on a card, not in a count, not in a sort order.
- Others never see a hint of what is not shared with them: no counts of hidden wishes, no names of unshared categories, no glass labels.

## UI terms (en → sv)

The same words for the same things, in both languages. Docs, tickets, PRs and code comments use the English column. This table is the only place in `docs/` where the Swedish terms appear; a new term is added here when its string is added to the locale files.

| English (`en.json`) | Swedish (`sv.json`) |
|---|---|
| All (the main list) | Allt |
| My wishes / Wishes | Mina önskningar / Önskningar |
| People | Folk |
| Reserved (the tab) | Reserverat |
| Reserved (on a card) | Reserverad |
| Me | Jag |
| Add | Lägg till |
| Share | Dela |
| Who can see this? | Vem ser den? |
| Only me | Bara jag |
| All my contacts | Alla mina kontakter |
| Everyone (glass label) | Alla |
| Chosen people | Utvalda personer |
| Only chosen people | Bara utvalda |
| Same as the lists | Som listorna |
| Anyone with the link | Alla med länken |
| Copy link / Copied | Kopiera länk / Kopierad |
| New link | Ny länk |
| Opened by | Har öppnat |
| I'll buy it | Jag köper den |
| You're buying it | Du köper den |
| Undo | Ångra |
| Undo reservation | Ångra reservation |
| Bought | Köpt |
| Someone got there first | Någon hann före |
| Nothing reserved yet. | Inget reserverat än. |
| New category | Ny kategori |
| Christmas · Birthday · Home decor · Kitchen · Garden (suggested categories) | Jul · Födelsedag · Inredning · Kök · Trädgård |
| Change picture | Byt bild |
| AI image | AI-bild |
| Make the picture nicer | Gör bilden snyggare |
| Cheapest | Billigast |
| price checked <time> | pris hämtat <tid> |
| Is this right? | Stämmer det? |
| Search yourself | Sök själv |
| Looking for prices… | Letar pris… |
| Your first wish | Din första önskan |
| No wishes yet | Inga önskningar än |
| Snap something | Fota något |
| Open in shop | Öppna i butiken |
| Paste link | Klistra in länk |
| Uploading… | Laddar upp… |
| Invite | Bjud in |
| Revoke | Återkalla |
| Accept / Not now | Godkänn / Inte nu |
| Block / Unblock | Blockera / Häv blockering |
| Blocked | Blockerade |
| Remove contact | Ta bort kontakt |
| Settings | Inställningar |
| Delete my account | Radera mitt konto |
| Log out | Logga ut |
| Send code / Send a new code | Skicka kod / Skicka ny kod |
| What's your name? | Vad heter du? |
| All I can see | Allt jag kan se |
| Birthday in 12 days | Fyller år om 12 dagar |
| Let others find me | Låt andra hitta mig |
| seen at … | sett hos … |
| Family (a group of contacts, later) | Familjen |
| Try again | Försök igen |
| Done | Klar |
| Cancel | Avbryt |
