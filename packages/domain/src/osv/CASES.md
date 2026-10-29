# OSV ranges to isAffected — test cases

Source: https://api.osv.dev/v1/vulns/GHSA-c2qf-rxjj-qqgw
modified: 2026-09-10T03:50:02.224637541Z
License: CC-BY 4.0

| # | version | expected | basis |
|---|---------|----------|-------|
| 1 | 1.9.0 | false | before all |
| 2 | 2.0.0 | true | range1: >=2.0.0-alpha and <5.7.2 |
| 3 | 5.7.2 | false | <6.0.0 and >=5.7.2|
| 4 | 6.1.1 | true | range2: >=6.0.0 and <6.3.1 |
| 5 | 7.5.3 | false | >=7.5.2 |
| 6 | 7.0.0 | true | range3: introduced 7.0.0 is inclusive |
| 7 | 7.5.2 | false | range3: fixed 7.5.2 is the patched version, so excluded |
| 8 | 3.0.0-beta.1 | true | range1: inside >=2.0.0-alpha <5.7.2 by semver precedence; needs includePrerelease true |
