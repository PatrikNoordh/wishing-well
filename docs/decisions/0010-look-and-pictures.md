# 0010 — The look, and where a wish's picture comes from

- **Status:** accepted
- **Date:** 2026-11-18
- **Builds on:** `0006-styling.md` (how styling is built); this decides what it looks like.

## Context

The first design system was warm peach, coral and cream. Tried in a clickable prototype against three other light variants, it felt too loud next to real product photos. The developer's earlier app PawPals (built with classmates, SwiftUI) had a calm look the developer likes: a cream-to-sage gradient, off-white cards and a terracotta accent.

Pictures came up at the same time. Most wishes will start from window-shopping on the phone, so screenshots, not studio photos, and some photos taken in a shop will be bad.

## Decision

**Look.** The design system takes PawPals' colours for light mode: background gradient `#FFF1E6` → `#B7B7A4` (29–67%) → `#EDDCD2`, off-white `#F0EFEB` cards, terracotta `#CB997E` as the one accent, dark brown `#3D3027` text. Two changes from PawPals, for contrast: dark brown (not white) text on terracotta (white is 2.2:1), and darker secondary text. Headings in Inter, body in Nunito. Dark mode keeps its own warm dark palette with a lighter terracotta. The token `coral` is renamed `accent`.

**Pictures.** Screenshots are a first-class source (picker and share sheet). A wish's picture can be swapped, in this order of preference:

1. The shop's own product image, from an offer the owner picked. Exact product, free, and the reader already fetches it.
2. The owner's photo cleaned up (background removed). Later.
3. The owner's photo as it is.
4. An AI illustration, only when nothing else works. Later, and always tagged "AI-bild" for everyone.

The app never swaps a picture on its own; the owner chooses.

## Alternatives

| Option | Why not |
|---|---|
| Keep the warm coral look | Too loud next to real photos; the products should be the colour |
| PawPals exactly, white text on terracotta and sage | 2.2:1 contrast, hard to read, fails the project's own rule |
| Always generate a clean AI image of the product | A generated chair is not the chair you want: a gift giver could buy the wrong one. It also costs per image and can hide what the owner actually photographed |

## Consequences

- WISH-3 builds `src/theme/` from the design system's `tokens.json` and adds `expo-linear-gradient` and the two font packages.
- WISH-14, WISH-20 and WISH-24 gain screenshots, shared images and "Byt bild" with the shop's image.
- A shop's image stored in the owner's folder is a copy of someone else's picture, shown only to the people the wish is shared with, as GoWish does. Check before a public launch.
- Background removal and AI illustrations are in "Later"; the illustration needs the "AI-bild" tag and a cost check in `/wish-ai-eval`.
