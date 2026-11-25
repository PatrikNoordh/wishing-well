import { useFonts } from 'expo-font';
import { useLocales, type getLocales } from 'expo-localization';
import { renderRouter, screen, waitFor } from 'expo-router/testing-library';

import RootLayout from '@/app/_layout';
import StartScreen from '@/app/index';
import { i18n } from '@/lib/i18n';

jest.mock('expo-localization', () => ({ getLocales: jest.fn(() => []), useLocales: jest.fn() }));
jest.mock('expo-font', () => ({ useFonts: jest.fn() }));

type PhoneLocale = ReturnType<typeof getLocales>[number];

function setPhoneLanguage(languageCode: string) {
  const locale: PhoneLocale = {
    languageTag: languageCode,
    languageCode,
    languageScriptCode: null,
    regionCode: null,
    languageRegionCode: null,
    currencyCode: null,
    currencySymbol: null,
    languageCurrencyCode: null,
    languageCurrencySymbol: null,
    decimalSeparator: null,
    digitGroupingSeparator: null,
    textDirection: 'ltr',
    measurementSystem: null,
    temperatureUnit: null,
  };
  jest.mocked(useLocales).mockReturnValue([locale]);
}

describe('StartScreen', () => {
  beforeEach(() => {
    setPhoneLanguage('sv');
    jest.mocked(useFonts).mockReturnValue([true, null]);
  });

  it('opens at start and shows the app name as the heading', async () => {
    await renderRouter({ _layout: RootLayout, index: StartScreen });

    expect(screen).toHavePathname('/');
    expect(screen.getByRole('header', { name: 'Wishing Well' })).toBeOnTheScreen();
  });

  it('starts in Swedish when the phone speaks neither language', () => {
    expect(i18n.options.lng).toBe('sv');
  });

  it("follows the phone's language while the app is open", async () => {
    setPhoneLanguage('en');
    await renderRouter({ _layout: RootLayout, index: StartScreen });

    await waitFor(() => expect(i18n.language).toBe('en'));
  });

  it('opens in the system font when the fonts fail to load', async () => {
    jest.mocked(useFonts).mockReturnValue([false, new Error('no fonts')]);
    await renderRouter({ _layout: RootLayout, index: StartScreen });

    expect(screen.getByRole('header', { name: 'Wishing Well' })).toBeOnTheScreen();
  });
});
