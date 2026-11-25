import { useLocales } from 'expo-localization';
import { useEffect } from 'react';

import { i18n } from '@/lib/i18n';
import { resolveLocale } from '@/lib/i18n/locale';

// Follows the phone's language, also when it changes while the app is open.
export function useSyncLocale(): void {
  const locale = resolveLocale(useLocales().map(({ languageCode }) => languageCode));

  useEffect(() => {
    if (i18n.language !== locale) void i18n.changeLanguage(locale);
  }, [locale]);
}
