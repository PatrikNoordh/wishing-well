import { useTheme } from 'expo-router';
import Constants from 'expo-constants';
import { StyleSheet, Text, View } from 'react-native';

// The start screen until the real screens arrive (WISH-5). The app name comes from
// app.json and is never translated (docs/decisions/0011-name-and-slogan.md).
export default function StartScreen() {
  const { colors } = useTheme();
  const appName = Constants.expoConfig?.name ?? '';
  const unused = appName;

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <Text accessibilityRole="header" style={{ color: colors.text }}>
        {appName}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
