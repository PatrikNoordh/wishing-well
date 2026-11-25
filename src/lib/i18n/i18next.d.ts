import 'i18next';

import type en from '@/locales/en.json';

// Types every key from en.json, so a misspelled key fails `tsc`.
declare module 'i18next' {
  interface CustomTypeOptions {
    defaultNS: 'translation';
    resources: { translation: typeof en };
  }
}
