import en from './en.json';
import sv from './sv.json';

type Tree = { [key: string]: string | Tree };

function flatten(tree: Tree, prefix = ''): [string, string][] {
  return Object.entries(tree).flatMap(([key, value]): [string, string][] =>
    typeof value === 'string' ? [[prefix + key, value]] : flatten(value, `${prefix}${key}.`),
  );
}

const placeholders = (text: string) => (text.match(/{{.*?}}/g) ?? []).sort();

describe('locales', () => {
  const english = new Map(flatten(en));
  const swedish = new Map(flatten(sv));

  it('has the same keys in sv and en', () => {
    expect([...swedish.keys()].sort()).toEqual([...english.keys()].sort());
  });

  it.each([
    ['en', english],
    ['sv', swedish],
  ])('has no empty values in %s', (_name, texts) => {
    expect([...texts].filter(([, text]) => text.trim() === '')).toEqual([]);
  });

  it('uses the same placeholders in sv and en', () => {
    for (const [key, text] of english) {
      expect([key, placeholders(swedish.get(key) ?? '')]).toEqual([key, placeholders(text)]);
    }
  });

  it('never translates the app name', () => {
    expect(en.app.name).toBe('Wishing Well');
    expect(sv.app.name).toBe('Wishing Well');
  });
});
