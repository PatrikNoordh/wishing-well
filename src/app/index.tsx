import { useTranslation } from 'react-i18next';
import { StyleSheet, Text, View } from 'react-native';

import { ScreenBackground } from '@/components/ui/ScreenBackground';
import { spacing } from '@/theme/spacing';
import { typography } from '@/theme/typography';
import { useAppTheme } from '@/theme/useAppTheme';

// The start screen until the real screens arrive (WISH-5).
export default function StartScreen() {
  const { t } = useTranslation();
  const { colors } = useAppTheme();

  return (
    <ScreenBackground>
      <View style={styles.container}>
        <Text accessibilityRole="header" style={[styles.name, { color: colors.ink }]}>
          {t('app.name')}
        </Text>
      </View>
    </ScreenBackground>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.space4,
  },
  name: {
    ...typography.display,
    textAlign: 'center',
  },
});
