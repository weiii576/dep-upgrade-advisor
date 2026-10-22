import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { isAffected } from './is-affected.js';

interface Case {
  section: string;
  n: string;
  version: string;
  range: string;
  expected: boolean;
  rule: string;
}

const TABLE_OPTIONS = { includePrerelease: false } as const;

function parseRow(line: string): Omit<Case, 'section'> | null {
  if (!line.startsWith('|')) return null;
  // GFM escapes a literal pipe in a cell as \|, so `||` ranges are written \|\|.
  const cells = line
    .split(/(?<!\\)\|/)
    .slice(1, -1)
    .map((c) => c.trim().replace(/\\\|/g, '|'));
  if (cells.length !== 6) {
    if (/^\d+$/.test(cells[0] ?? '')) throw new Error(`CASES.md row has ${cells.length} cells, expected 6: ${line}`);
    return null;
  }
  const [n, version, range, expected, , rule] = cells;
  if (!/^\d+$/.test(n) || version === '' || range === '') return null;
  if (expected !== 'true' && expected !== 'false') return null;
  return { n, version, range, expected: expected === 'true', rule };
}

function loadCases(): Case[] {
  const here = dirname(fileURLToPath(import.meta.url));
  const md = readFileSync(join(here, 'CASES.md'), 'utf8');
  const cases: Case[] = [];
  let section = '';
  for (const line of md.split('\n')) {
    const heading = /^## (.+)$/.exec(line);
    if (heading) {
      section = heading[1].trim();
      continue;
    }
    const row = parseRow(line);
    if (row) cases.push({ section, ...row });
  }
  return cases;
}

const cases = loadCases();
const bySection = new Map<string, Case[]>();
for (const c of cases) {
  const rows = bySection.get(c.section) ?? [];
  rows.push(c);
  bySection.set(c.section, rows);
}

describe('isAffected (CASES.md)', () => {
  it('loads a non-trivial table', () => {
    expect(cases.length).toBeGreaterThan(0);
  });

  for (const [section, rows] of bySection) {
    describe(section, () => {
      it.each(rows)('#$n  $version  $range  -> $expected   ($rule)', ({ version, range, expected }) => {
        expect(isAffected(version, range, TABLE_OPTIONS)).toBe(expected);
      });
    });
  }
});

describe('isAffected input validation', () => {
  it('throws on an invalid version instead of returning false', () => {
    expect(() => isAffected('not-a-version', '^1.0.0', { includePrerelease: false })).toThrow(TypeError);
  });

  it('throws on an invalid range instead of returning false', () => {
    expect(() => isAffected('1.0.0', '>>1.0.0', { includePrerelease: false })).toThrow(TypeError);
  });
});
