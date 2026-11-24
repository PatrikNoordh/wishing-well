// https://docs.expo.dev/guides/using-eslint/
const { defineConfig } = require('eslint/config');
const expoConfig = require('eslint-config-expo/flat');
const prettierRecommended = require('eslint-plugin-prettier/recommended');

module.exports = defineConfig([
  expoConfig,
  prettierRecommended,
  {
    // Edge Functions run on Deno and are checked by `deno check` in CI.
    ignores: ['dist/*', '.expo/*', 'supabase/functions/*'],
  },
]);
