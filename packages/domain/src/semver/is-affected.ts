import semver from 'semver';

export interface IsAffectedOptions {
  /**
   * Whether a version carrying a pre-release tag (e.g. 1.0.0-rc.1) may satisfy a
   * comparator that does not name a pre-release on the same major.minor.patch.
   *
   * false = node-semver default: `1.0.0-rc.1` does NOT satisfy `<1.0.0`.
   *         Right for "what would npm install".
   * true  = plain semver.org precedence: `1.0.0-rc.1` DOES satisfy `<1.0.0`.
   *         Right for "is this version before the fix" (security advisories).
   */
  includePrerelease: boolean;
}

/**
 * Does `version` fall inside `range`?
 *
 * `range` uses npm range syntax (comparators, ^, ~, x, ||). Build metadata on
 * either side is ignored for precedence (semver.org §11.1).
 *
 * Throws on an unparsable version or range rather than returning false.
 */
export function isAffected(version: string, range: string, opts: IsAffectedOptions): boolean {
  if (semver.valid(version) === null) {
    throw new TypeError(`Invalid semver version: ${JSON.stringify(version)}`);
  }
  if (semver.validRange(range) === null) {
    throw new TypeError(`Invalid semver range: ${JSON.stringify(range)}`);
  }
  return semver.satisfies(version, range, { includePrerelease: opts.includePrerelease });
}
