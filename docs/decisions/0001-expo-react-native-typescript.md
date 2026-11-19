# 0001 — React Native with Expo and TypeScript

- **Status:** accepted
- **Date:** 2026-11-15

## Context

The first users are a family and their friends, all on Android; one sibling has an iPhone and should get the app later without a rewrite. The app needs the camera, the photo library, image processing and the share sheet, and it should be possible to release in Google Play and the App Store. The developer knows Swift, Kotlin, React, React Native and TypeScript, and the LIA placement works in React and TypeScript against Supabase.

## Decision

React Native with Expo (the latest stable SDK; 58 when this was written), TypeScript in strict mode, Expo Router, and development builds (not Expo Go). The Edge Functions are TypeScript too, so the whole project is one language.

## Alternatives

| Option | Why not |
|---|---|
| Swift (SwiftUI) | iPhone only; the family uses Android |
| Kotlin (Compose) | Android only; the sibling's iPhone would need a second app |
| Flutter | Two platforms, but Dart: a second language next to the TypeScript backend, and not the stack used at the LIA placement |
| A web app (PWA) | No reliable share target on iPhone, weaker camera flow, and not "a real app" in the stores |

## Consequences

- One codebase for Android and iPhone; an iPhone build needs only the Apple Developer Program (99 USD a year) when the time comes, no code change.
- Native modules need a development build, so adding one is a "native change" that the PR must flag (`CLAUDE.md` § Workflow).
- Expo's share receiving (`expo-sharing`) is experimental on iOS; Android is the target for sharing into the app in v1.
