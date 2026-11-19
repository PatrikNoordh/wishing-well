## [WISH-<N>] <Title>

Closes #<issue number>

### Summary

<!-- One or two sentences: what was built and why. -->

### What Changed

1. **Database** — <!-- migrations, RLS, or "Not touched" -->
2. **Edge Functions** — <!-- or "Not touched" -->
3. **Data layer** — <!-- src/lib/api, src/hooks, or "Not touched" -->
4. **UI** — <!-- screens, components, or "Not touched" -->
5. **Tests** — <!-- or "Not touched" -->
6. **Native** — <!-- new native module or app.json plugin? Then a new development build is needed. Or "None" -->

### Acceptance Criteria

<!-- Every AC from the issue. Unchecked ones say why. -->

- [ ] AC1:

### Manual Test Steps

<!-- On your own Android phone and in the Android emulator. Say who each step is run as: owner, a contact who sees it, a contact who does not, stranger. -->

1.

### Tradeoffs

<!-- Decisions, deferrals, new dependencies, schema changes. -->

-

### Validation

- [ ] `npm run lint`, `npx tsc --noEmit`, `npm test` and `npm run build` pass
- [ ] RLS tests pass (`supabase/tests/run_local.sh` and CI), if `supabase/` changed
- [ ] The owner sees no reservation anywhere this PR touches
- [ ] Tested on my own Android phone and in the emulator, as owner, and as a contact who sees it and one who does not if shared data is touched
