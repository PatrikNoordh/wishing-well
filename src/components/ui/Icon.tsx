import type { LucideIcon } from 'lucide-react-native';

import type { ColorName } from '@/theme/colors';
import { iconSize, iconStrokeWidth } from '@/theme/icons';
import { useAppTheme } from '@/theme/useAppTheme';

type IconProps = {
  // Import each icon from its own file, `lucide-react-native/icons/<name>`: the package's
  // index would bundle every icon.
  icon: LucideIcon;
  color?: ColorName;
};

// Decorative for screen readers: the label belongs on the control or the text beside it.
export function Icon({ icon: LucideGlyph, color = 'ink' }: IconProps) {
  const { colors } = useAppTheme();

  return (
    <LucideGlyph
      size={iconSize}
      strokeWidth={iconStrokeWidth}
      color={colors[color]}
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
    />
  );
}
