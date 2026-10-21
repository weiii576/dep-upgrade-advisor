import pg from 'pg';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

const url = process.env.DATABASE_URL;
if (!url) throw new Error('DATABASE_URL is not set. Run the tests through `make test`.');

const client = new pg.Client({ connectionString: url });

beforeAll(async () => {
  await client.connect();
});

afterAll(async () => {
  await client.end();
});

beforeEach(async () => {
  await client.query('ROLLBACK');
  await client.query('BEGIN');
});

async function rejects(sql: string, params: unknown[]): Promise<string> {
  await client.query('SAVEPOINT attempt');
  try {
    await client.query(sql, params);
  } catch (err) {
    await client.query('ROLLBACK TO SAVEPOINT attempt');
    return (err as { constraint?: string; code?: string }).constraint ?? String((err as { code?: string }).code);
  }
  throw new Error(`expected the database to reject: ${sql}`);
}

async function insertId(sql: string, params: unknown[] = []): Promise<string> {
  const { rows } = await client.query<{ id: string }>(`${sql} RETURNING id`, params);
  return rows[0].id;
}

async function fixtures() {
  const repoA = await insertId(`INSERT INTO repository (id, name) VALUES (gen_random_uuid(), 'repo-a')`);
  const repoB = await insertId(`INSERT INTO repository (id, name) VALUES (gen_random_uuid(), 'repo-b')`);
  const pkg = await insertId(`INSERT INTO package (id, name) VALUES (gen_random_uuid(), 'left-pad')`);
  const pkgDep = await insertId(`INSERT INTO package (id, name) VALUES (gen_random_uuid(), 'right-pad')`);
  const pv = await insertId(
    `INSERT INTO package_version (id, "packageId", version) VALUES (gen_random_uuid(), $1, '1.0.0')`,
    [pkg],
  );
  const pvDep = await insertId(
    `INSERT INTO package_version (id, "packageId", version) VALUES (gen_random_uuid(), $1, '2.0.0')`,
    [pkgDep],
  );
  const advisory = await insertId(
    `INSERT INTO advisory (id, "osvId", "publishedAt", "modifiedAt", "rawJson")
     VALUES (gen_random_uuid(), 'GHSA-test-0000-0000', now(), now(), '{}')`,
  );
  return { repoA, repoB, pv, pvDep, advisory };
}

describe('database', () => {
  it('has the vector extension installed', async () => {
    const { rows } = await client.query(`SELECT extversion FROM pg_extension WHERE extname = 'vector'`);
    expect(rows).toHaveLength(1);
  });
});

describe('document kind must match exactly one back-reference (decision 0002 section 1)', () => {
  const insert = `INSERT INTO document (id, kind, content, "sourceUrl", "advisoryId", "packageVersionId", "repositoryId", "updatedAt")
                  VALUES (gen_random_uuid(), $1, 'text', $2, $3, $4, $5, now())`;

  it('accepts one well-formed row per kind', async () => {
    const f = await fixtures();
    await client.query(insert, ['advisory_description', 'u1', f.advisory, null, null]);
    await client.query(insert, ['release_notes', 'u2', null, f.pv, null]);
    await client.query(insert, ['upgrade_policy', 'repo://repo-a/UPGRADE_POLICY.md', null, null, f.repoA]);
  });

  it('rejects an upgrade policy without a repository, which would make it visible to every tenant', async () => {
    const f = await fixtures();
    expect(await rejects(insert, ['upgrade_policy', 'u3', null, null, null])).toBe('document_kind_matches_reference');
    expect(await rejects(insert, ['upgrade_policy', 'u4', f.advisory, null, null])).toBe('document_kind_matches_reference');
  });

  it('rejects a global document that carries a repository', async () => {
    const f = await fixtures();
    expect(await rejects(insert, ['release_notes', 'u5', null, f.pv, f.repoA])).toBe('document_kind_matches_reference');
    expect(await rejects(insert, ['advisory_description', 'u6', f.advisory, null, f.repoA])).toBe(
      'document_kind_matches_reference',
    );
  });

  it('rejects a document pointing at the wrong kind of source', async () => {
    const f = await fixtures();
    expect(await rejects(insert, ['release_notes', 'u7', f.advisory, null, null])).toBe('document_kind_matches_reference');
  });
});

describe('repository-scoped rows cannot cross repositories', () => {
  async function installs() {
    const f = await fixtures();
    const install = `INSERT INTO installation (id, "repositoryId", "packageVersionId") VALUES (gen_random_uuid(), $1, $2)`;
    return {
      ...f,
      aRoot: await insertId(install, [f.repoA, f.pv]),
      aDep: await insertId(install, [f.repoA, f.pvDep]),
      bDep: await insertId(install, [f.repoB, f.pvDep]),
    };
  }

  const edge = `INSERT INTO installation_edge ("repositoryId", "installationId", "dependsOnInstallationId") VALUES ($1, $2, $3)`;

  it('accepts an edge between two installations of the same repository', async () => {
    const i = await installs();
    await client.query(edge, [i.repoA, i.aRoot, i.aDep]);
  });

  it("rejects an edge from repository A's installation to repository B's", async () => {
    const i = await installs();
    expect(await rejects(edge, [i.repoA, i.aRoot, i.bDep])).toBe('installation_edge_repositoryId_dependsOnInstallationId_fkey');
  });

  it('rejects a root dependency pointing at another repository installation', async () => {
    const i = await installs();
    const root = `INSERT INTO root_dependency ("repositoryId", "installationId", "versionRange", type) VALUES ($1, $2, '^2.0.0', 'prod')`;
    expect(await rejects(root, [i.repoA, i.bDep])).toBe('root_dependency_repositoryId_installationId_fkey');
  });
});
