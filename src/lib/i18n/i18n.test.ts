import en from '@/locales/en.json';
import sv from '@/locales/sv.json';

import { i18n } from '.';
import { resolveLocale } from './locale';

describe('resolveLocale', () => {
  it.each([
    [['sv'], 'sv'],
    [['en'], 'en'],
    [['de', 'en', 'sv'], 'en'],
    [['de'], 'sv'],
    [[null], 'sv'],
    [[], 'sv'],
  ])('%j gives %s', (languages, expected) => {
    expect(resolveLocale(languages)).toBe(expected);
  });
});

describe('i18n', () => {
  it('translates into both languages', () => {
    expect(i18n.getFixedT('en')('app.slogan')).toBe('Ooh, I want one of those!');
    expect(i18n.getFixedT('sv')('app.slogan')).toBe(sv.app.slogan);
  });

  it('picks the plural form', () => {
    const t = i18n.getFixedT('en');
    expect(t('person.birthdayInDays', { count: 1 })).toBe('Birthday in 1 day');
    expect(t('person.birthdayInDays', { count: 12 })).toBe('Birthday in 12 days');
    expect(i18n.getFixedT('sv')('person.birthdayInDays', { count: 1 })).toBe(
      sv.person.birthdayInDays_one.replace('{{count}}', '1'),
    );
  });

  it('falls back to English for a text missing in Swedish', () => {
    i18n.removeResourceBundle('sv', 'translation');
    expect(i18n.getFixedT('sv')('app.slogan')).toBe(en.app.slogan);
    i18n.addResourceBundle('sv', 'translation', sv);
  });

  it('rejects a misspelled key when type checking', () => {
    // @ts-expect-error: tsc fails here if keys ever stop being typed.
    expect(i18n.getFixedT('en')('app.sloggan')).toBe('app.sloggan');
  });
});
