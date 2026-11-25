export const LOCALES = ['sv', 'en'] as const;
export type AppLocale = (typeof LOCALES)[number];

// What users start in when the phone speaks neither language.
export const DEFAULT_LOCALE: AppLocale = 'sv';
// Where a text missing in the chosen language is taken from.
export const FALLBACK_LOCALE: AppLocale = 'en';

// The first of the phone's languages, in the user's order, that the app speaks.
export function resolveLocale(phoneLanguages: readonly (string | null)[]): AppLocale {
  for (const language of phoneLanguages) {
    const match = LOCALES.find((locale) => locale === language);
    if (match) return match;
  }
  return DEFAULT_LOCALE;
}
