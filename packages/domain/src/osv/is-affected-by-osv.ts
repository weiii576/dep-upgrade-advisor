import { isAffected } from '../semver/is-affected.js';

type OsvEvent =
  | { introduced: string }
  | { fixed: string }
  | { last_affected: string }
  | { limit: string };

interface OsvRange {
  events: OsvEvent[];
}

interface OsvAffected {
  ranges: OsvRange[];
}

export interface OsvAdvisory {
  affected?: OsvAffected[];
}

function eventsToRange(events: OsvEvent[]): string {
  const parts: string[] = [];
  let lower: string | null = null;

  for (const e of events) {
    if ("introduced" in e) {
      lower = e.introduced === "0" ? "" : `>=${e.introduced}`;
      continue;
    }

    if ("limit" in e) {
      throw new Error(`Unsupported OSV event "limit": ${e.limit}`);
    }

    if (lower === null) continue;

    let upper: string;
    if ("fixed" in e) {
      upper = `<${e.fixed}`;
    } else if ("last_affected" in e) {
      upper = `<=${e.last_affected}`;
    } else {
      const _exhaustive: never = e;
      throw new Error(`Unknown OSV event: ${JSON.stringify(_exhaustive)}`);
    }

    parts.push(`${lower} ${upper}`.trim());
    lower = null;
  }

  if (lower !== null) parts.push(lower || "*");
  return parts.join(" || ");
}

function advisoryToRange(adv: OsvAdvisory): string {
  const parts = (adv.affected ?? [])
    .flatMap(a => a.ranges)
    .map(r => eventsToRange(r.events))
    .filter(Boolean);

  return parts.length ? parts.join(" || ") : "";
}

export function isAffectedByOsv(version: string, advisory: OsvAdvisory, packageName: string): boolean {
  return isAffected(version, advisoryToRange(advisory), { includePrerelease: true })
}
