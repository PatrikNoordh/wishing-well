# 0012 — Four tabs around the camera, and Lucide icons

- **Status:** accepted
- **Date:** 2026-11-19

## Context

The first UI spec had three tabs (Mina önskningar, Folk, Reserverat), with settings behind the profile avatar. The design system and the prototype were drawn with the camera button in the middle of the tab bar, which needs an even number of tabs around it. The prototype also needed a set of icons, drawn in one style.

## Decision

- **Four tabs** around the camera button: Önskningar, Folk, **camera**, Reserverat, Jag. "Jag" holds the profile and settings; the avatar in the header also opens it.
- **Icons from Lucide** (`lucide-react-native`, with `react-native-svg`), approved in WISH-3. Line icons on a 24 grid with a 2 px stroke, coloured from the theme.

## Alternatives

| Option | Why not |
|---|---|
| Three tabs, settings behind the avatar | The camera, the app's most important button, would sit off-centre between two tabs, and settings would be hidden |
| Draw our own icons | Every icon drawn and kept consistent by hand; no gain for this app |
| Material icons / Expo vector icons | Work too, but their style is heavier than the calm look in `0010-look-and-pictures.md` |

## Consequences

- The camera stays in the middle, one thumb away, and every tab has a label.
- Two more packages in the app, approved in WISH-3.
- The design system's TabBar and the prototype already show this layout.
