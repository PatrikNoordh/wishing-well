# UI spec

Every screen, what it shows and does, and its states. Swedish UI text is shown as it should read; the English locale follows. Visual design comes from the design system artifact (https://claude.ai/artifact/FM4zenrV1VAiiQ1M81sn1o; `docs/decisions/0010-look-and-pictures.md`: calm PawPals colours with a cream-to-sage gradient, off-white cards, one terracotta accent, Inter headings over Nunito text, a wink of humour in the words) and the building blocks in `src/components/ui/` (WISH-3, WISH-4). Sharing follows `docs/decisions/0007-sharing-model.md`.

## Navigation

Four bottom tabs around one big action in the middle (`docs/decisions/0012-tabs-and-icons.md`):

| Tab | Screen | |
|---|---|---|
| **Önskningar** | "Allt" with category chips (Mina önskningar) | Start screen |
| **Folk** | Contacts and invites | |
| — | **Lägg till** (round terracotta camera button, always visible, in the middle of the tab bar) | Opens the camera at once (at most two taps) |
| **Reserverat** | What I am buying | |
| **Jag** | Profile and settings | |

The profile avatar in the header of **Önskningar** also opens **Jag**. Icons come from Lucide.

## Screens

### Sign-in
- "Wishing Well" and the slogan (`app.slogan`: "Åh, en sån vill jag ha!" / "Ooh, I want one of those!") above the form.
- Email field → "Skicka kod" → six-digit code field → signed in.
- States: sending, wrong code, expired code (with "Skicka ny kod"), no network.

### Onboarding (first sign-in)
- "Vad heter du?" (display name, required), birthday (optional, year optional), then one sentence: "Allt du lägger in är bara ditt tills du väljer att dela det." Then straight to the camera.

### Mina önskningar ("Allt")
- Header: "Allt", a sharing line under it ("Bara du ser" / "Delas med alla dina kontakter" / "Delas med Bo, Cleo +2"), tap to change.
- **Category chips** in a horizontal row: "Allt", "Jul", "Födelsedag", "Inredning" …, and "+ Ny kategori". A chip filters the grid; a long-press opens the category's menu (rename, share, delete).
- A grid of wish cards: photo, title, price and shop.
- **Glass label** in the top-left corner of each photo, on my own cards only: who sees the wish, whichever way. "Alla", "Bo, Cleo +2", "Bara jag". Tap opens **Vem ser den?**.
- **Never** any sign of reservations.
- Empty: "Din första önskan", the slogan under it, and a button to the camera.

### A category (mine)
- The same grid filtered to the category, with the category's own sharing line and "Dela".

### Dela (for "Allt" or a category)
- "Bara jag" (default) · "Alla mina kontakter" (one tap) · "Utvalda personer" (checkboxes for my contacts) · "Alla med länken".
- "Alla med länken": the link with "Kopiera länk" and "Dela" (share sheet), "Ny länk" (confirmation: "Den gamla länken slutar fungera, också för de som redan öppnat den."), and "Har öppnat" with names. Under the copy button: "Alla som har länken och loggar in kan se listan. Skicka den bara till dem du vill."
- Explains: "De ser listans namn och allt i den, också det du lägger till senare. Önskningar du har valt själv för påverkas inte."

### Vem ser den? (one wish)
- "Som listorna" (default) — with who that is right now and how: "Via Allt: alla kontakter", "Via Jul: Mamma, Bo".
- "Bara utvalda" — checkboxes for my contacts, pre-filled with who sees it now.
- "Bara jag".
- Says: "Ditt val här gäller före listorna."

### A wish (mine)
- Photo, title, price and shop, link ("Öppna i butiken"), note, categories (chips, editable), the glass label.
- From epic 5: offers, cheapest first, each with shop, price and "pris hämtat <tid>".
- Actions: edit, categories, "Vem ser den?", delete.

### Lägg till
1. Camera opens at once; switch to gallery, or "Klistra in länk" (epic 4).
2. After the photo: the wish is saved at once, private, in "Allt" (and in the category chip that was selected, if any), and the edit form opens with the photo. Title is required.
3. From epic 5: "Letar…" while the AI works; then a sheet **"Stämmer det?"** with the suggested name and offers. One tap accepts; everything can be edited; "Sök själv" opens the browser.

### Folk
- My contacts and open invites (with "Återkalla").
- Actions: "Bjud in" → share sheet with the link; open a person; end a contact (confirmation says what goes with it); block.
- **Blockera** (in a person's menu, also for someone who came by link): confirmation "Ni kan inte se eller nå varandra längre. Det ni delat, reserverat och kontakten tas bort. Anna får inte veta det." Blocked people are listed under Inställningar → Blockerade, with "Häv blockering" ("Ingenting kommer tillbaka.").

### A list link (opened from a link)
- Signs in first if needed, then opens the list as on "A person", filtered to that list: owner's name, the list's name, its cards, reserve.
- No invite button: becoming contacts still goes through an invite from one of the two.
- Errors: `link_not_found` → "Länken fungerar inte längre. Be om en ny." (the same message for every reason).

### Invite (opened from a link)
- "Anna vill lägga till dig som kontakt." → "Godkänn" / "Inte nu".
- After accepting: "Ni är kontakter. Anna väljer själv vad du får se."
- Errors: used, expired, own invite, already contacts — each with its own message.

### A person
- Name, birthday ("fyller år om 12 dagar").
- **"Allt jag kan se"** and chips for the categories shared with me. Nothing hints at what I cannot see.
- Cards with photo, title, price, shop and **"Reserverad"** or **"Jag köper den"**. My own reservation shows "Du köper den" and "Ångra".

### Reserverat
- Everything I have reserved, grouped by person: photo, title, price, link.
- Actions: "Köpt" (marked on the phone in v1), "Ångra reservation".
- Empty: "Inget reserverat än."

### Jag (profile and settings)
- Name, birthday, language (follow the phone / Svenska / English), theme (follow the phone / light / dark), app version, "Logga ut", "Radera mitt konto" (confirmation lists what disappears).

## States, everywhere

Every screen that loads data has **loading** (skeleton), **empty** (teaches the next step) and **error** (what went wrong, "Försök igen"). Without network, cached data is shown with a quiet "offline" note and writes wait or fail clearly.

## Rules

- Works from 360 dp wide, in light and dark mode, with large system fonts.
- All text through `t()`, in both locales.
- The owner sees no reservation anywhere: not on a card, not in a count, not in a sort order.
- Others never see a hint of what is not shared with them: no counts of hidden wishes, no names of unshared categories, no glass labels.
