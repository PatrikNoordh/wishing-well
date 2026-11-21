import { renderRouter, screen } from 'expo-router/testing-library';

import RootLayout from '@/app/_layout';
import StartScreen from '@/app/index';

// On a device, Constants.expoConfig is the `expo` object of app.json.
jest.mock('expo-constants', () => ({
  __esModule: true,
  default: { expoConfig: jest.requireActual('../../app.json').expo },
}));

describe('StartScreen', () => {
  it('opens at start and shows the app name from app.json as the heading', async () => {
    await renderRouter({ _layout: RootLayout, index: StartScreen });

    expect(screen).toHavePathname('/');
    expect(screen.getByRole('header', { name: 'Wishing Well' })).toBeOnTheScreen();
  });
});
