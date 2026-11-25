import type { FontFamily } from './fonts';

type TypeStyle = { fontFamily: FontFamily; fontSize: number; lineHeight: number };

// The weight is in the font family. A `fontWeight` on top makes Android draw a fake bold.
export const typography = {
  display: { fontFamily: 'Inter_700Bold', fontSize: 32, lineHeight: 38 },
  title: { fontFamily: 'Inter_700Bold', fontSize: 24, lineHeight: 30 },
  heading: { fontFamily: 'Inter_600SemiBold', fontSize: 19, lineHeight: 26 },
  body: { fontFamily: 'Nunito_500Medium', fontSize: 16, lineHeight: 24 },
  bodyStrong: { fontFamily: 'Nunito_700Bold', fontSize: 16, lineHeight: 24 },
  label: { fontFamily: 'Nunito_700Bold', fontSize: 14, lineHeight: 20 },
  caption: { fontFamily: 'Nunito_600SemiBold', fontSize: 13, lineHeight: 18 },
  price: { fontFamily: 'Nunito_800ExtraBold', fontSize: 17, lineHeight: 22 },
} as const satisfies Record<string, TypeStyle>;
