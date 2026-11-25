import type { AppLocale } from '@/lib/i18n/locale';

// English formats as in Sweden too ("1 299 kr", 24-hour times): the prices and the users are
// Swedish, whatever language the app is in.
const INTL_LOCALES: Record<AppLocale, string> = { sv: 'sv-SE', en: 'en-SE' };

const DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/;

// `new Date('2026-12-24')` is midnight UTC, which is the day before west of Greenwich. A
// date without a time (a birthday) is read as that day on the phone's own calendar.
function toDate(value: Date | string): Date {
  if (value instanceof Date) return value;
  const match = DATE_ONLY.exec(value);
  return match
    ? new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]))
    : new Date(value);
}

/** "24 december 2026" */
export function formatDate(value: Date | string, locale: AppLocale): string {
  return new Intl.DateTimeFormat(INTL_LOCALES[locale], {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(toDate(value));
}

/** "14:02" */
export function formatTime(value: Date | string, locale: AppLocale): string {
  return new Intl.DateTimeFormat(INTL_LOCALES[locale], {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(toDate(value));
}

/** "1 299 kr", or "1 299,50 kr" when there are decimals. `currency` is an ISO 4217 code. */
export function formatPrice(amount: number, currency: string, locale: AppLocale): string {
  return new Intl.NumberFormat(INTL_LOCALES[locale], {
    style: 'currency',
    currency,
    ...(Number.isInteger(amount) && { minimumFractionDigits: 0, maximumFractionDigits: 0 }),
  }).format(amount);
}
