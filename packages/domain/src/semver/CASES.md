# is_affected(version, range) — test cases

Input: `version` (a semver string), `range` (npm range syntax). Output: `true` when the version satisfies the range.
One rule per row; for each rule, one row on each side of the boundary.
Only two sources: semver.org §11 and the node-semver README "Ranges" section.

Source keys:
- `S11` = https://semver.org/#spec-item-11 (version precedence)
- `NR`  = https://github.com/npm/node-semver#ranges (range syntax)
- `NR-pre` = https://github.com/npm/node-semver#prerelease-tags (pre-release matching in ranges)

Rule keys (semver.org §11; "rule under test" cites these):
- `11.1` precedence is computed from major, minor, patch, pre-release only; build metadata is ignored
- `11.2` major, minor, patch compared numerically, left to right, first difference wins
- `11.3` same major.minor.patch: a pre-release version ranks below the normal version
- `11.4` same major.minor.patch, both pre-release: compare identifiers left to right, first difference wins
  - `11.4.1` both numeric: compared numerically
  - `11.4.2` both alphanumeric: compared lexically in ASCII order
  - `11.4.3` numeric vs alphanumeric: numeric is lower
  - `11.4.4` all preceding identifiers equal: the longer identifier list is higher

## 1 | Comparison operators (`>=`, `<`, `>`, `<=`, `=`)

| # | version | range | expected | source | rule under test |
|---|---------|-------|----------|--------|-----------------|
| 1 | 1.1.0 | <1.0.1 | false | S11 | 11.2 |
| 2 | 1.0.0 | <1.0.1 | true | S11 | 11.2 |
| 3 | 2.0.1 | >1.20.1 | true | S11 | 11.2 (major compared before minor) |
| 4 | 1.1.1+ASD | =1.1.1+123 | true | S11 | 11.1 |
| 5 | 2.0.0-alpha | <=2.0.0 | false | NR-pre | comparator has no pre-release tag on 2.0.0, so the pre-release is excluded even though 11.3 orders it lower |
| 6 | 2.0.0-beta | >=2.0.0 | false | NR-pre, S11 | excluded by NR-pre; also lower by 11.3 |
| 7 | 1.1.1 | =1.1.1 | true | NR, S11 | `=` comparator: equal precedence (11.2, no difference) |
| 8 | 1.1.2 | =1.1.1 | false | NR, S11 | `=` comparator: patch differs (11.2) |
| 9 | 1.0.1 | <1.0.1 | false | NR, S11 | `<` is strict at equal precedence |
| 10 | 1.0.1 | <=1.0.1 | true | NR, S11 | `<=` includes equal precedence |
| 11 | 1.0.1 | >1.0.1 | false | NR, S11 | `>` is strict at equal precedence |
| 12 | 1.0.1 | >=1.0.1 | true | NR, S11 | `>=` includes equal precedence |

## 2 | `^` (caret)

| # | version | range | expected | source | rule under test |
|---|---------|-------|----------|--------|-----------------|
| 1 | 1.2.3 | ^1.2.3 | true | NR | left-most non-zero = major; lower bound inclusive |
| 2 | 1.2.4 | ^1.2.3 | true | NR | left-most non-zero = major; patch may change |
| 3 | 1.3.4 | ^1.2.3 | true | NR | left-most non-zero = major; minor may change |
| 4 | 2.1.1 | ^1.2.3 | false | NR | left-most non-zero = major; major changed |
| 5 | 0.2.3 | ^0.2.3 | true | NR | left-most non-zero = minor; lower bound inclusive |
| 6 | 0.2.4 | ^0.2.3 | true | NR | left-most non-zero = minor; patch may change |
| 7 | 0.3.3 | ^0.2.3 | false | NR | left-most non-zero = minor; minor changed |
| 8 | 1.2.3 | ^0.2.3 | false | NR | left-most non-zero = minor; major changed |
| 9 | 0.0.3 | ^0.0.3 | true | NR | left-most non-zero = patch; lower bound inclusive, and the only allowed version |
| 10 | 0.0.4 | ^0.0.3 | false | NR | left-most non-zero = patch; patch changed |
| 11 | 0.1.3 | ^0.0.3 | false | NR | left-most non-zero = patch; minor changed |
| 12 | 1.1.3 | ^0.0.3 | false | NR | left-most non-zero = patch; major changed |
| 13 | 1.2.3-beta.2 | ^1.2.3-beta.2 | true | NR | pre-release lower bound inclusive (NR-pre: same tuple, has tag) |
| 14 | 1.2.3-rc | ^1.2.3-beta.2 | true | NR | same tuple, later pre-release (11.4.2) |
| 15 | 1.2.3 | ^1.2.3-beta.2 | true | NR | release above its own pre-release (11.3) |
| 16 | 1.2.4-beta.2 | ^1.2.3-beta.2 | false | NR | NR-pre: pre-release on a different tuple is excluded even though inside the numeric range |
| 17 | 1.2.0 | ^1.2.x | true | NR | x desugars to 0; lower bound inclusive |
| 18 | 1.3.0 | ^1.2.x | true | NR | x desugars to 0; minor may change |
| 19 | 2.0.0 | ^1.2.x | false | NR | x desugars to 0; major changed |
| 20 | 1.1.0 | ^1.2.x | false | NR | x desugars to 0; below lower bound |
| 21 | 1.0.0 | ^1.x | true | NR | x desugars to 0; lower bound inclusive |
| 22 | 1.1.0 | ^1.x | true | NR | x desugars to 0; minor may change |
| 23 | 1.1.1 | ^1.x | true | NR | x desugars to 0; patch may change |
| 24 | 2.0.0 | ^1.x | false | NR | x desugars to 0; major changed |
| 25 | 0.1.1 | ^1.x | false | NR | x desugars to 0; below lower bound |
| 26 | 0.0.1 | ^0.0.x | true | NR | no non-zero element; x desugars to 0; patch may change |
| 27 | 0.1.1 | ^0.0.x | false | NR | no non-zero element; minor changed |
| 28 | 0.0.1 | ^0.x | true | NR | no non-zero element; x desugars to 0; patch may change |
| 29 | 0.1.1 | ^0.x | true | NR | no non-zero element; minor may change |
| 30 | 1.0.0 | ^0.x | false | NR | no non-zero element; major changed |
| 31 | 0.0.1 | ^0.0 | true | NR | missing patch desugars to x; same as ^0.0.x |
| 32 | 0.1.1 | ^0.0 | false | NR | missing patch desugars to x; same as ^0.0.x |
| 33 | 0.0.1 | ^0 | true | NR | missing minor and patch desugar to x; same as ^0.x |
| 34 | 0.1.1 | ^0 | true | NR | missing minor and patch desugar to x; same as ^0.x |
| 35 | 1.0.0 | ^0 | false | NR | missing minor and patch desugar to x; same as ^0.x |

## 3 | `~` (tilde)

| # | version | range | expected | source | rule under test |
|---|---------|-------|----------|--------|-----------------|
| 1 | 1.2.3 | ~1.2.3 | true | NR | major.minor.patch given: lower bound inclusive |
| 2 | 1.2.9 | ~1.2.3 | true | NR | major.minor.patch given: patch may change |
| 3 | 1.3.0 | ~1.2.3 | false | NR | major.minor.patch given: minor may NOT change |
| 4 | 1.1.9 | ~1.2.3 | false | NR | major.minor.patch given: below lower bound |
| 5 | 1.2.0 | ~1.2 | true | NR | major.minor given: same as ~1.2.0, lower bound inclusive |
| 6 | 1.2.9 | ~1.2 | true | NR | major.minor given: patch may change |
| 7 | 1.3.0 | ~1.2 | false | NR | major.minor given: minor may NOT change (differs from ^1.2.x) |
| 8 | 1.1.9 | ~1.2 | false | NR | major.minor given: below lower bound |
| 9 | 1.0.0 | ~1 | true | NR | major only: same as ^1.x, lower bound inclusive |
| 10 | 1.9.9 | ~1 | true | NR | major only: minor and patch may change |
| 11 | 2.0.0 | ~1 | false | NR | major only: major changed |
| 12 | 0.9.9 | ~1 | false | NR | major only: below lower bound |
| 13 | 0.2.3 | ~0.2.3 | true | NR | 0.x with patch: lower bound inclusive |
| 14 | 0.2.9 | ~0.2.3 | true | NR | 0.x with patch: patch may change |
| 15 | 0.3.0 | ~0.2.3 | false | NR | 0.x with patch: minor changed |
| 16 | 0.2.0 | ~0.2 | true | NR | 0.x without patch: same as ~0.2.0 |
| 17 | 0.3.0 | ~0.2 | false | NR | 0.x without patch: minor changed |
| 18 | 1.2.3-beta.4 | ~1.2.3-beta.2 | true | NR-pre, S11 | same tuple with tag, later pre-release (11.4.1) |
| 19 | 1.2.4-beta.2 | ~1.2.3-beta.2 | false | NR | NR-pre: pre-release on a different tuple is excluded |
| 20 | 1.2.4 | ~1.2.3-beta.2 | true | NR | release inside >=1.2.3-beta.2 <1.3.0-0; no tag so NR-pre does not apply |

## 4 | `||` (fill on 10/21)

| # | version | range | expected | source | rule under test |
|---|---------|-------|----------|--------|-----------------|
| 1 | 1.2.7 | 1.2.7 \|\| >=1.2.9 <2.0.0 | true | NR | satisfies first set only (bare version = `=` comparator) |
| 2 | 1.2.8 | 1.2.7 \|\| >=1.2.9 <2.0.0 | false | NR | gap between sets: satisfies neither |
| 3 | 1.2.9 | 1.2.7 \|\| >=1.2.9 <2.0.0 | true | NR | second set: lower bound inclusive |
| 4 | 1.4.6 | 1.2.7 \|\| >=1.2.9 <2.0.0 | true | NR | second set: inside the range |
| 5 | 2.0.0 | 1.2.7 \|\| >=1.2.9 <2.0.0 | false | NR, S11 | second set: upper bound strict (11.2) |
| 6 | 1.2.6 | 1.2.7 \|\| >=1.2.9 <2.0.0 | false | NR, S11 | below every set (11.2) |
| 7 | 1.2.3-beta.2 | >=1.2.3-beta.1 <1.3.0 \|\| >=2.0.0 | true | NR-pre, S11 | tagged comparator with the same tuple is in the matching set (11.4.1) |
| 8 | 1.2.4-beta.2 | >=1.2.3-beta.1 <1.3.0 \|\| >=2.0.0 | false | NR-pre | no set has a tagged comparator on 1.2.4, so it is excluded even though it is numerically inside set 1 |
| 9 | 1.2.4-beta.0 | >=1.2.3-beta.1 <2.0.0 \|\| 1.2.4-beta.0 | true | NR-pre | second set matches exactly (same tuple, has tag) |
| 10 | 1.2.4-beta.1 | >=1.2.3-beta.1 <2.0.0 \|\| 1.2.4-beta.0 | false | NR-pre | NR-pre is checked per comparator set: set 2 has the 1.2.4 tag but fails `=`; set 1 is numerically fine but has no 1.2.4 tag |

## 5 | Pre-release (fill on 10/21)

| # | version | range | expected | source | rule under test |
|---|---------|-------|----------|--------|-----------------|
| 1 | 1.0.0-alpha | <1.0.0-alpha.1 | true | S11 | 11.4.4 |
| 2 | 1.0.0-alpha.1 | <1.0.0-alpha.beta | true | S11 | 11.4.3 |
| 3 | 1.0.0-alpha.beta | <1.0.0-beta | true | S11 | 11.4.2 |
| 4 | 1.0.0-beta | >1.0.0-beta.2 | false | S11 | 11.4.4 |
| 5 | 1.0.0-beta.2 | <1.0.0-beta.11 | true | S11 | 11.4.1 |
| 6 | 1.0.0-beta.11 | >1.0.0-rc.1 | false | S11 | 11.4.2 |
| 7 | 1.0.0-rc.1 | <1.0.0 | false | NR-pre | comparator 1.0.0 has no pre-release tag, so excluded; 11.3 alone would give true |

## 6 | Questions that came up while reading the spec (note, don't resolve now)

- Decision (2026-10-20): follow node-semver default semantics (NR-pre). A version with a pre-release tag satisfies a range only if at least one comparator in the set has the same [major, minor, patch] and a pre-release tag. Every row in this table is evaluated with `includePrerelease: false`. Rows affected: section 1 rows 5 and 6, section 5 row 7.
- Open: OSV advisory ranges (10/23) use `introduced` / `fixed` events, not npm comparators. Decide then whether `fixed: 1.0.0` should treat `1.0.0-rc.1` as affected; under the rule above it would not.
