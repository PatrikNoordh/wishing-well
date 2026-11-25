import { LinearGradient } from 'expo-linear-gradient';
import type { PropsWithChildren } from 'react';
import { StyleSheet } from 'react-native';

import { backgroundGradient } from '@/theme/colors';
import { useAppTheme } from '@/theme/useAppTheme';

const [top, upper, lower, bottom] = backgroundGradient.colors;

// The background behind every screen: cream to sage to peach in light mode, flat in dark.
export function ScreenBackground({ children }: PropsWithChildren) {
  const { colors } = useAppTheme();

  return (
    <LinearGradient
      colors={[colors[top], colors[upper], colors[lower], colors[bottom]]}
      locations={backgroundGradient.locations}
      style={styles.fill}
    >
      {children}
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
});
