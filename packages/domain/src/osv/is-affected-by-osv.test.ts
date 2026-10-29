import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { isAffectedByOsv } from './is-affected-by-osv.js';

interface Case {
  n: string;
  version: string;
  expected: boolean;
  basis: string;
}

const ADVISORY_ID = 'GHSA-c2qf-rxjj-qqgw';
const PACKAGE_NAME = 'semver';

function parseRow(line: string): Case | null {
  if (!line.startsWith('|')) return null;
  const cells = line.split('|').slice(1, -1).map((c) => c.trim());
  if (cells.length !== 4) {
    if (/^\d+$/.test(cells[0] ?? '')) throw new Error(`CASES.md row has ${cells.length} cells, expected 4: ${line}`);
    return null;
  }
  const [n, version, expected, basis] = cells;
  if (!/^\d+$/.test(n) || version === '') return null;
  if (expected !== 'true' && expected !== 'false') return null;
  return { n, version, expected: expected === 'true', basis };
}

const here = dirname(fileURLToPath(import.meta.url));
const advisory = JSON.parse(readFileSync(join(here, 'fixtures', `${ADVISORY_ID}.json`), 'utf8'));
const cases = readFileSync(join(here, 'CASES.md'), 'utf8')
  .split('\n')
  .map(parseRow)
  .filter((c): c is Case => c !== null);

describe(`isAffectedByOsv (${ADVISORY_ID}, CASES.md)`, () => {
  it('loads a non-trivial table with unique row numbers', () => {
    expect(cases.length).toBeGreaterThan(0);
    expect(new Set(cases.map((c) => c.n)).size).toBe(cases.length);
  });

  it.each(cases)('#$n  $version  -> $expected   ($basis)', ({ version, expected }) => {
    expect(isAffectedByOsv(version, advisory, PACKAGE_NAME)).toBe(expected);
  });
});
