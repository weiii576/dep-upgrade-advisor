# 0001. Scope document retrieval by a nullable repositoryId

Status: accepted, 2026-10-21. Revisit after the first A12 eval run.

## Context

`document` holds text the agent retrieves and cites. There are three kinds:

| kind | scope | points back to |
|---|---|---|
| advisory text | global | `advisory` |
| release notes | global | `package_version` |
| upgrade policy | one repository | `repository` |

Only upgrade policies carry a `repositoryId`. Global documents are ingested only for packages that appear in at least one tenant's lockfile (`plan/flagship.md` §2 scope), so the global set is the union of every tenant's packages, not the whole npm ecosystem.

## Decision

Retrieval for repository R filters with:

```sql
repository_id IS NULL OR repository_id = :R
```

This keeps every private document, the upgrade policies, invisible to other tenants.

## Consequences

**Indirect disclosure of another tenant's packages.** Suppose tenant B depends on a package that tenant A does not. That package's release notes exist only because B's lockfile caused them to be ingested. A can retrieve them, so A can infer that some other tenant uses the package. The content is public, but the package set is part of B's lockfile, which A15 says A must never see. Accepted for now: two tenants, both demo data.

**Lower retrieval precision.** Search returns the top K nearest chunks. Chunks from packages A does not use can take some of those K slots, leaving fewer relevant ones for the model. A12's context-precision metric measures exactly this.

## Alternative kept in reserve

Restrict global documents to those relevant to R by joining through R's installations:

- R's own upgrade policies.
- Release notes whose `package_version` is installed in R, or is an upgrade candidate for a package installed in R.
- Advisory text for advisories that affect a package installed in R.

This removes both consequences above at the cost of a more complex query.

## When to switch

The switch changes the retrieval query only. The tables already hold every link the join needs, so no migration is required.

Switch when either holds:

- A12 reports low context-precision and the irrelevant chunks come from packages R does not install.
- A15 is tightened to assert that R cannot retrieve any document tied only to another tenant's packages.

The disclosure consequence does not wait for a number. It exists by design and is recorded here so it can be stated when asked whether tenant isolation has gaps.
