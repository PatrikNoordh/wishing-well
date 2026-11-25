import { getLocales } from 'expo-localization';
import { createInstance } from 'i18next';
import { initReactI18next } from 'react-i18next';

import en from '@/locales/en.json';
import sv from '@/locales/sv.json';

import { FALLBACK_LOCALE, LOCALES, resolveLocale } from './locale';

export const i18n = createInstance();

i18n.use(initReactI18next).init({
  resources: { en: { translation: en }, sv: { translation: sv } },
  lng: resolveLocale(getLocales().map((locale) => locale.languageCode)),
  fallbackLng: FALLBACK_LOCALE,
  supportedLngs: LOCALES,
  // The texts are bundled, so they are ready before the first render.
  initAsync: false,
  // React Native draws text, not HTML.
  interpolation: { escapeValue: false },
});
