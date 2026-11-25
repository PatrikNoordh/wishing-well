import { useColorScheme } from 'react-native';

import { darkColors, lightColors, type Colors } from './colors';
import { darkShadows, lightShadows, type Shadows } from './shadows';

export type AppTheme = { isDark: boolean; colors: Colors; shadows: Shadows };

const lightTheme: AppTheme = { isDark: false, colors: lightColors, shadows: lightShadows };
const darkTheme: AppTheme = { isDark: true, colors: darkColors, shadows: darkShadows };

// Follows the system setting.
export function useAppTheme(): AppTheme {
  return useColorScheme() === 'dark' ? darkTheme : lightTheme;
}
