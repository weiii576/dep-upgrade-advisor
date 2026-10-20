# dep-upgrade-advisor

A multi-tenant agent that answers "can this repo upgrade package X to version Y, and what will it touch?" — reading the lockfile dependency graph, public security advisories (OSV) and release notes, and handing the exact parts (affected ranges, minimal upgrade set) to a tested rule engine instead of the model.

Work in progress. Assists human judgement; does not replace CI or code review.
