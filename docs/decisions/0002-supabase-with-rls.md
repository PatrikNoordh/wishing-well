# 0002 — Supabase, with every rule in Row Level Security

- **Status:** accepted
- **Date:** 2026-11-15

## Context

The app shares data between people with rules that must never break: who sees which list, and that the owner never sees a reservation. The app is open source and runs on phones the developer does not control, so nothing in the app can be trusted to enforce a rule.

## Decision

Supabase (EU, Stockholm): Postgres with Row Level Security on every table and explicit grants, Auth with email codes, private Storage, and Edge Functions for what the app must not do itself. Every rule is a policy, a trigger or a grant, and has a check in `supabase/tests/rls_test.sql` that runs in CI against a real Postgres.

## Alternatives

| Option | Why not |
|---|---|
| Firebase (Firestore) | Known from school, but the reservation rule ("everyone who can see the wish, except its owner") and the visibility rules are harder to express and to test in security rules than in SQL; no real test against a database in CI |
| Own backend (Node + Postgres) | More to build and run, and the same RLS would be written by hand |

## Consequences

- The same patterns as mini-ATS: migrations, RLS tests in CI, the developer applies migrations, Claude never touches the project.
- Security is tested where it lives. A policy change without a check is a review blocker.
