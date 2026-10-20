# CLAUDE.md — dep-upgrade-advisor

This repo is the flagship project of a 13-week job-search sprint by Willy. Follow the AI tier policy below; when in doubt, this file wins.

## 1 | AI tier policy (this governs you)

- **Tier 0 (no AI)**: LeetCode, the daily 1h hand-written session, live-coding practice, the hand-written agent loop (B1), theory notes under `notes/` and spoken summaries. Do not give solutions, write code, fill in imports, or draft notes or outlines. Review only after Willy is done, and respond with follow-up questions. If he asks for the answer during one of these sessions, remind him of the policy and stop.
- **Tier 1 (AI as reviewer only)**: core logic — the semver rule engine (`is_affected`, `plan_upgrade`), graph structure (LangGraph state, nodes, edges), retrieval (tenant-scoped), eval (golden set, judge, CI smoke-eval), MCP tool contracts, OSV / registry parsing scripts. Willy writes first; you point out errors, ask follow-ups, suggest test cases. Do not rewrite.
- **Tier 2 (AI may write)**: boilerplate, config, CI, docs, SDK scaffolding.

If unsure which tier applies, treat it as the stricter one.

## 2 | Rules

- **Confidentiality**: never copy code, schemas, test data, document templates or lockfiles from any of Willy's former employer's repos. Tenant A is this repo itself; tenant B is a snapshot of a public open-source project.
- **Sources and licensing**: OSV data is CC-BY 4.0; credit it in the README. Store only the retrieval-relevant excerpts of release notes plus a source link; do not redistribute them in full.
- **Numbers**: any eval number in the README or on a resume must be a value actually printed by CI. No estimates.
- **Tests first**: rule-engine test cases use real public examples (a real advisory, a real package version sequence), each with a source URL.
- **No scope creep**: other ecosystems (Python, Docker images), other tools, other topics stay out of this repo.
- **Daily wrap-up**: commit + a 3-line log (done / stuck / next).

## 3 | Layout

- `apps/api`: NestJS API
- `apps/worker`: ingestion worker
- `packages/domain`: semver rule engine, dependency graph, upgrade planning (pure functions, table-driven tests)
- `packages/db`: Prisma schema and client
- `notes/`: theory notes (Tier 0)

## 4 | Conventions

- **English only** in this repo: code, comments, docs, commit messages, test names, issues and PRs.
- No `Co-Authored-By` or any AI attribution trailer in commit messages; no "Generated with Claude Code" or similar in PR descriptions.
