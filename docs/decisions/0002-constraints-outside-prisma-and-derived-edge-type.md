# 0002. Constraints Prisma cannot express, and edge type derived instead of stored

Status: accepted, 2026-10-21.

## 1. document kind must match exactly one back-reference

Each `document` row points back to its source through one of three nullable columns, chosen by `kind`:

| kind | required column | the other two |
|---|---|---|
| `advisory_description` | `advisoryId` | NULL |
| `release_notes` | `packageVersionId` | NULL |
| `upgrade_policy` | `repositoryId` | NULL |

Prisma's schema language has no CHECK constraints, so this rule is not enforced by `schema.prisma`. It is enforced by a hand-written `CHECK` added to the migration that creates `document`. The ingestion code must not be the only guard: a row that breaks this rule would make `repositoryId IS NULL` true for a private upgrade policy, which is exactly the leak decision 0001 relies on not happening.

A test inserts one row per kind with the wrong column filled and asserts the database rejects it.

## 2. installation_edge does not store the dependency type

`installation_edge` records which installation a lockfile actually links to, with no `type` column. The type (prod, dev, peer, optional) is already in `package_version_dependency`, keyed by the upstream installation's `packageVersionId` and the downstream installation's package. Storing it again would put one fact in two places that can disagree.

When a query needs the type of a resolved edge, it joins:

installation_edge, then the upstream installation, then `package_version_dependency` on (`packageVersionId`, `dependsOnPackageId` = downstream installation's package).

Revisit if that join shows up as a measured cost in `plan_upgrade`, or if a lockfile edge is found with no matching declared dependency.

## 3. If chunk ever carries repositoryId, it must equal its document's

Deferred, 2026-10-21. `chunk` does not carry `repositoryId` for now; search joins `document` to filter. The copy is kept as a candidate retrieval improvement for A13, measured before and after. If it is added, the rule below applies.

`chunk` carries a copy of its document's `repositoryId` so vector search can filter on the same table it ranks, without a join. The copy is a second place for one fact, so it must be kept equal to `document.repositoryId`.

A composite foreign key `chunk(documentId, repositoryId)` to `document(id, repositoryId)` does not fully enforce this. Postgres foreign keys default to `MATCH SIMPLE`, which skips the check when any referencing column is NULL. The dangerous case is exactly that one: a chunk of a private upgrade policy stored with `repositoryId` NULL would pass the foreign key and become visible to every tenant under decision 0001's filter. `MATCH FULL` does not help, because global chunks legitimately have a NULL `repositoryId` with a non-NULL `documentId`.

So the rule is enforced by a trigger written in the migration: on insert or update of `chunk`, `repositoryId` must be `IS NOT DISTINCT FROM` the parent document's `repositoryId`. A test inserts a policy chunk with `repositoryId` NULL and asserts the database rejects it.
