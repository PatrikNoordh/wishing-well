import { formatDate, formatPrice, formatTime } from './format';

// Intl separates thousands and the currency with non-breaking spaces.
const plain = (text: string) => text.replace(/\s/g, ' ');

describe('formatPrice', () => {
  it('writes kronor the Swedish way in both languages', () => {
    expect(plain(formatPrice(1299, 'SEK', 'sv'))).toBe('1 299 kr');
    expect(plain(formatPrice(1299, 'SEK', 'en'))).toBe('1 299 kr');
  });

  it('shows decimals only when there are any', () => {
    expect(plain(formatPrice(1299.5, 'SEK', 'sv'))).toBe('1 299,50 kr');
    expect(plain(formatPrice(0, 'SEK', 'sv'))).toBe('0 kr');
  });

  it('formats other currencies', () => {
    expect(plain(formatPrice(20, 'EUR', 'sv'))).toBe('20 €');
  });
});

describe('formatDate', () => {
  it('writes the month in the language', () => {
    expect(formatDate(new Date(2026, 11, 24), 'sv')).toBe('24 december 2026');
    expect(formatDate(new Date(2026, 11, 24), 'en')).toBe('24 December 2026');
  });

  it('keeps a date without a time on its own day', () => {
    expect(formatDate('2026-01-01', 'en')).toBe('1 January 2026');
  });
});

describe('formatTime', () => {
  it('uses the 24-hour clock', () => {
    expect(formatTime(new Date(2026, 0, 1, 14, 2), 'sv')).toBe('14:02');
    expect(formatTime(new Date(2026, 0, 1, 0, 5), 'en')).toBe('00:05');
  });
});
