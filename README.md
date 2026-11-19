# Wishing Well

*Ooh, I want one of those!*

A wish-list app for Android and iPhone. See something you want, take a photo, and it lands on your list. The app works out what it is and which online shops sell it, cheapest first. You choose who sees what, like sharing in Google Docs: your partner, your family, a friend. They can reserve a gift so nobody buys the same thing twice — and you never see what has been reserved.

> **Status:** planning done, epic 0 not started. The plan is in [`TICKETS.md`](TICKETS.md); the live tickets are the GitHub issues.

## Why

Wish-list apps like GoWish are built around links from web shops. But the moment you want something is often in a real shop, or in a friend's kitchen, with a phone in your hand and no link. This app starts from the photo, and does the searching for you.

It is built first for one family and their friends, and with the foundations to be released in Google Play and the App Store later. It is a portfolio project built as a real product, made during the YH programme Mobile App Developer, and the process is documented as it happens.

## What it does

- **One long list, "Allt",** with every wish, and **categories** (Jul, Födelsedag, Inredning …) to find your way. A wish can be in several.
- **Private until you share.** Share a whole list or category with all your contacts or with chosen people, in one tap. Override a single wish: only these people, or only me.
- **Wishes** with a photo, a link, a price, a shop and a note. A small glass label shows you who sees each one.
- **Contacts:** invite people with a link. Nobody sees anything you have not shared with them, not even the names of your lists.
- **Reservations:** "I'll buy it." Everyone else who sees the wish sees it is taken. The owner never does.
- **From a link** (epic 4): share a product page to the app and it fills in the name, image and price.
- **From a photo** (epic 5): AI recognises the product, finds shops that sell it, and the app reads each shop's price from its own page, cheapest first. AI only suggests; you decide.

## How it is built

Claude Code writes the code. I plan the work, set the rules, review every change, test it on real phones and decide what ships. The rules are in [`CLAUDE.md`](CLAUDE.md), the workflow runs through project skills in [`.claude/skills/`](.claude/skills/), and every change goes through a ticket, a branch, a pull request, a review and green CI. The same way of working as my earlier project [mini-ATS](https://github.com/PatrikNoordh/mini-ats).

## Stack

- **App:** Expo (React Native) with TypeScript and Expo Router, one codebase for Android and iPhone
- **Backend:** Supabase — Postgres with Row Level Security, Auth with email codes, Storage, Edge Functions (Deno)
- **AI:** behind one interface, so the provider can be swapped; measured with a fixed set of test photos ([`docs/ai-eval.md`](docs/ai-eval.md))
- **Builds:** EAS Build; Android APK for the family first

## Security in one paragraph

Every table has Row Level Security and explicit grants, and the policies are tested in CI against a real Postgres ([`supabase/tests/rls_test.sql`](supabase/tests/rls_test.sql)). The one rule the app rests on — the owner of a wish never learns it is reserved — has its own checks, including that the owner cannot find out by trying to reserve. Photos are re-encoded on the phone, so no location leaves it. More in [`docs/data-safety.md`](docs/data-safety.md).

## Docs

| Doc | What it holds |
|---|---|
| [`docs/requirements.md`](docs/requirements.md) | Who the app is for and what it must do |
| [`docs/ui-spec.md`](docs/ui-spec.md) | Every screen and its states |
| [`docs/architecture.md`](docs/architecture.md) | How the parts fit, and the main flows |
| [`docs/data-safety.md`](docs/data-safety.md) | Where data lives, who may read and write it, and the test behind each rule |
| [`docs/error-codes.md`](docs/error-codes.md) | Every error code and where it comes from |
| [`docs/decisions/`](docs/decisions/) | Why things are the way they are |
| [`docs/ai-eval.md`](docs/ai-eval.md) | How well the AI works, measured |
| [`docs/journal.md`](docs/journal.md) | The project diary |

## Run locally

*Filled in by WISH-1.*

RLS tests against a local Postgres (no Supabase needed):

```bash
bash supabase/tests/run_local.sh
```
