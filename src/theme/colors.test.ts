import { darkColors, lightColors, type ColorName, type Colors } from './colors';

function luminance(hex: string): number {
  const [r, g, b] = [1, 3, 5].map((start) => {
    const channel = parseInt(hex.slice(start, start + 2), 16) / 255;
    return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrast(a: string, b: string): number {
  const [lighter, darker] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (lighter + 0.05) / (darker + 0.05);
}

// WCAG AA: 4.5:1 for text, 3:1 for borders that carry meaning. `sage` is missing where the
// design system forbids it.
const TEXT: Partial<Record<ColorName, ColorName[]>> = {
  ink: ['bg', 'bgEnd', 'sage', 'surface', 'surfaceSunken', 'peach'],
  inkMuted: ['bg', 'bgEnd', 'sage', 'surface', 'surfaceSunken', 'peach'],
  accentText: ['bg', 'surface', 'surfaceSunken', 'peach'],
  onAccent: ['accent', 'accentPressed'],
  bg: ['ink'],
  successText: ['successBg'],
  dangerText: ['dangerBg', 'bg', 'surface'],
  honeyText: ['honeyBg'],
};
const BORDERS: Partial<Record<ColorName, ColorName[]>> = {
  lineStrong: ['surface', 'surfaceSunken'],
  focus: ['bg', 'bgEnd', 'sage', 'surface', 'surfaceSunken', 'peach'],
};

function pairs(groups: Partial<Record<ColorName, ColorName[]>>): [ColorName, ColorName][] {
  return (Object.keys(groups) as ColorName[]).flatMap((front) =>
    (groups[front] ?? []).map((back): [ColorName, ColorName] => [front, back]),
  );
}

describe.each<[string, Colors]>([
  ['light', lightColors],
  ['dark', darkColors],
])('%s colours', (_name, colors) => {
  it.each(pairs(TEXT))('%s on %s is readable text', (front, back) => {
    expect(contrast(colors[front], colors[back])).toBeGreaterThanOrEqual(4.5);
  });

  it.each(pairs(BORDERS))('%s on %s is a visible border', (front, back) => {
    expect(contrast(colors[front], colors[back])).toBeGreaterThanOrEqual(3);
  });
});
