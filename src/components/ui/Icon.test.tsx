import { render, screen } from '@testing-library/react-native';
import type { LucideProps } from 'lucide-react-native';
import Camera from 'lucide-react-native/icons/camera';
import { forwardRef } from 'react';
import type { Svg } from 'react-native-svg';
import { Text } from 'react-native';

import { lightColors } from '@/theme/colors';

import { Icon } from './Icon';

const ProbeIcon = forwardRef<Svg, LucideProps>(function ProbeIcon(props, _ref) {
  return <Text>{`${props.size} ${props.strokeWidth} ${String(props.color)}`}</Text>;
});

describe('Icon', () => {
  it('draws on a 24 grid with a 2 px stroke in a theme colour', async () => {
    await render(<Icon icon={ProbeIcon} color="accentText" />);

    expect(screen.getByText(`24 2 ${lightColors.accentText}`)).toBeOnTheScreen();
  });

  it('renders a Lucide icon', async () => {
    await render(<Icon icon={Camera} />);

    expect(screen.toJSON()).not.toBeNull();
  });
});
