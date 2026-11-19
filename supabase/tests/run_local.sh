#!/usr/bin/env bash
# Runs the RLS tests against a fresh throwaway database on a local Postgres, the same
# way the CI rls job does: the Supabase stand-in, every migration in order, then the tests.
# Never point it at the local Supabase stack's database or at the project.
#
# Usage: bash supabase/tests/run_local.sh   (uses the usual PG* environment variables)
set -euo pipefail

DB="wish_rls_test_$$"
cd "$(dirname "$0")/../.."

createdb "$DB"
trap 'dropdb --if-exists "$DB"' EXIT

psql -q -v ON_ERROR_STOP=1 -d "$DB" -f supabase/tests/local_stub.sql
for f in supabase/migrations/*.sql; do
  psql -q -v ON_ERROR_STOP=1 -d "$DB" -f "$f"
done
status=0
out=$(psql -v ON_ERROR_STOP=1 -d "$DB" -f supabase/tests/rls_test.sql 2>&1) || status=$?
echo "$out" | grep -E "OK [0-9]+:|ERROR|FAIL" | sed 's/^.*NOTICE:  //'
if [ "$status" -eq 0 ]; then echo "All RLS checks passed."; else echo "RLS checks FAILED"; fi
exit "$status"
