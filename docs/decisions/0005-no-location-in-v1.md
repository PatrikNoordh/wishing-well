# 0005 — No location in v1

- **Status:** accepted
- **Date:** 2026-11-15

## Context

The first idea used the phone's location to name the shop where the photo was taken. Research showed:

- Most gifts are ordered online; the shop you stand in matters less than where it is cheapest.
- Android's photo picker removes location from photos by default, and sharing a photo from the gallery strips it unless the app holds `ACCESS_MEDIA_LOCATION`. Location from shared photos cannot be relied on.
- Asking for location is a permission and a privacy cost for every user.

## Decision

No location permission and no location data in v1. Photos are re-encoded on the phone, which removes any location they carry.

## Consequences

- A simpler first run and a stronger privacy story.
- "Seen at …" can return later as an opt-in hint, with its own decision record.
