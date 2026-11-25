import * as constants from './constants';

// Typed by hand: the app has no Node types. Jest runs from the repo root.
const { readFileSync } = jest.requireActual<{
  readFileSync: (path: string, encoding: 'utf8') => string;
}>('fs');
const schema = readFileSync('supabase/migrations/20261116000000_init.sql', 'utf8');

describe('limits match the database checks', () => {
  it.each([
    [`char_length(display_name) <= ${constants.DISPLAY_NAME_MAX_LENGTH})`],
    [`not is_main and char_length(btrim(title)) between 1 and ${constants.LIST_TITLE_MAX_LENGTH})`],
    [`check (char_length(btrim(title)) between 1 and ${constants.WISH_TITLE_MAX_LENGTH})`],
    [`char_length(note) <= ${constants.WISH_NOTE_MAX_LENGTH})`],
    [`char_length(url) <= ${constants.WISH_URL_MAX_LENGTH})`],
    [`char_length(store_name) <= ${constants.STORE_NAME_MAX_LENGTH})`],
    [`'wish-images', false, ${constants.IMAGE_MAX_BYTES},`],
  ])('%s', (check) => {
    expect(schema).toContain(check);
  });
});
