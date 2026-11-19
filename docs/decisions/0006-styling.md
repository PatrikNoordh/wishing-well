# 0006 — Styling with StyleSheet and our own theme

- **Status:** accepted (revisit at WISH-3 if it slows the work down)
- **Date:** 2026-11-15

## Context

Every value must have one named source (`CLAUDE.md` § No hardcoded values), the app needs light and dark mode, and it should feel like one designed thing. The developer knows Tailwind from web work.

## Decision

React Native's `StyleSheet` with a typed theme in `src/theme/` (colours for light and dark, spacing, radii, type), and our own small set of building blocks in `src/components/ui/`. No UI kit.

## Alternatives

| Option | Why not (for now) |
|---|---|
| NativeWind (Tailwind for React Native) | Familiar classes, but another build step and dependency; can be adopted later on top of the same tokens |
| A UI kit (Tamagui, React Native Paper) | Faster start, but its look and its rules come first, and fewer of the decisions are ours to explain |

## Consequences

- No extra dependency, and every token is ours.
- More components to write in WISH-4, which is also good material to show.
