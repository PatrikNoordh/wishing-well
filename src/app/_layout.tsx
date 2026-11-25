import { useFonts } from 'expo-font';
import { DarkTheme, DefaultTheme, SplashScreen, Stack, ThemeProvider } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { I18nextProvider } from 'react-i18next';

import { useSyncLocale } from '@/hooks/useSyncLocale';
import { i18n } from '@/lib/i18n';
import { fonts } from '@/theme/fonts';
import { useAppTheme } from '@/theme/useAppTheme';

void SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const { isDark, colors } = useAppTheme();
  const [fontsLoaded, fontError] = useFonts(fonts);
  // Without the fonts the app still works, in the system font.
  const isReady = fontsLoaded || fontError !== null;
  useSyncLocale();

  useEffect(() => {
    if (isReady) void SplashScreen.hideAsync();
  }, [isReady]);

  if (!isReady) return null;

  const base = isDark ? DarkTheme : DefaultTheme;
  const navigationTheme = {
    ...base,
    colors: {
      ...base.colors,
      primary: colors.accentText,
      background: colors.bg,
      card: colors.surface,
      text: colors.ink,
      border: colors.line,
    },
  };

  return (
    <I18nextProvider i18n={i18n}>
      <ThemeProvider value={navigationTheme}>
        <Stack screenOptions={{ headerShown: false }} />
        <StatusBar style="auto" />
      </ThemeProvider>
    </I18nextProvider>
  );
}
