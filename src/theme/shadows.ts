// Values for the `boxShadow` style. Warm brown in light mode, never grey.
export const lightShadows = {
  shadowCard: '0 4px 10px rgba(61, 48, 39, 0.12)',
  shadowFloat: '0 6px 16px rgba(61, 48, 39, 0.22)',
  shadowSheet: '0 -6px 28px rgba(61, 48, 39, 0.16)',
};

export type Shadows = typeof lightShadows;

export const darkShadows: Shadows = {
  shadowCard: '0 2px 10px rgba(0, 0, 0, 0.35)',
  shadowFloat: '0 8px 20px rgba(0, 0, 0, 0.5)',
  shadowSheet: '0 -6px 28px rgba(0, 0, 0, 0.5)',
};
