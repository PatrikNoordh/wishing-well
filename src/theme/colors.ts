// Built from the design system's tokens.json (docs/decisions/0010-look-and-pictures.md).
// Same names in camelCase. Contrast is checked in colors.test.ts.

export const lightColors = {
  bg: '#FFF1E6',
  bgEnd: '#EDDCD2',
  sage: '#B7B7A4',
  surface: '#F0EFEB',
  surfaceSunken: '#E7E3DB',
  peach: '#EDDCD2',
  accent: '#CB997E',
  accentPressed: '#C18F74',
  onAccent: '#3D3027',
  accentText: '#7A4A33',
  ink: '#3D3027',
  inkMuted: '#4E4036',
  line: '#DCD5CB',
  lineStrong: '#857A6E',
  focus: '#3D3027',
  successBg: '#DCE3D0',
  successText: '#3F5A2E',
  dangerBg: '#F3D9D0',
  dangerText: '#9A2E1E',
  honeyBg: '#EFE3C8',
  honeyText: '#5E4A1A',
  glass: 'rgba(240, 239, 235, 0.72)',
  glassLine: 'rgba(255, 255, 255, 0.6)',
  scrim: 'rgba(61, 48, 39, 0.45)',
  skeleton: '#E2DDD4',
};

export type Colors = typeof lightColors;
export type ColorName = keyof Colors;

export const darkColors: Colors = {
  bg: '#1F1613',
  bgEnd: '#1F1613',
  sage: '#1F1613',
  surface: '#2B1F1B',
  surfaceSunken: '#36271F',
  peach: '#5A3526',
  accent: '#D9A386',
  accentPressed: '#E0AE92',
  onAccent: '#3D3027',
  accentText: '#E8B79C',
  ink: '#FBEDE2',
  inkMuted: '#CBB1A2',
  line: '#45322A',
  lineStrong: '#9C7D6D',
  focus: '#FBEDE2',
  successBg: '#1F3A2D',
  successText: '#8FD9AE',
  dangerBg: '#4A1D17',
  dangerText: '#FFB4A8',
  honeyBg: '#4A3A12',
  honeyText: '#F5CE73',
  glass: 'rgba(31, 22, 19, 0.7)',
  glassLine: 'rgba(255, 255, 255, 0.16)',
  scrim: 'rgba(0, 0, 0, 0.6)',
  skeleton: '#36271F',
};

// The background behind every screen, top to bottom. In dark mode the colours are the
// same, so it is flat.
export const backgroundGradient = {
  colors: ['bg', 'sage', 'sage', 'bgEnd'],
  locations: [0, 0.29, 0.67, 1],
} as const satisfies { colors: readonly ColorName[]; locations: readonly number[] };
