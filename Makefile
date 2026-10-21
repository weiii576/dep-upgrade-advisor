ifeq ($(wildcard .env),)
$(error .env not found. Copy .env.example to .env and fill it in)
endif
include .env
export

export DATABASE_URL := postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@localhost:$(POSTGRES_PORT)/$(POSTGRES_DB)

COMPOSE := docker compose
PRISMA := pnpm --filter @dua/db exec prisma
PSQL := $(COMPOSE) exec -T db psql -U $(POSTGRES_USER) -d $(POSTGRES_DB) -v ON_ERROR_STOP=1 -tA
DB_WAIT_SECONDS ?= 60

.DEFAULT_GOAL := help
.PHONY: help db-up db-down db-reset db-logs db-psql db-check generate migrate migrate-deploy migrate-reset studio test

help: ## list targets
	@grep -E '^[a-z-]+: ## ' $(firstword $(MAKEFILE_LIST)) | awk -F ': ## ' '{ printf "  %-14s %s\n", $$1, $$2 }'

db-up: ## start Postgres with pgvector and wait until healthy
	$(COMPOSE) up -d --wait --wait-timeout $(DB_WAIT_SECONDS) db || { echo "db not healthy after $(DB_WAIT_SECONDS)s, see: make db-logs"; exit 1; }
	@echo "db ready on localhost:$(POSTGRES_PORT)"

db-down: ## stop Postgres, keep data
	$(COMPOSE) down

db-reset: ## stop Postgres and destroy its data volume (requires CONFIRM=yes)
	@test "$(CONFIRM)" = yes || { echo "db-reset destroys the data volume. Run: make db-reset CONFIRM=yes"; exit 1; }
	$(COMPOSE) down --volumes

db-logs: ## follow Postgres logs
	$(COMPOSE) logs -f db

db-psql: ## open an interactive psql inside the container
	$(COMPOSE) exec db psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

db-check: ## prove the db answers and the vector extension is available
	@echo "SELECT 1 -> $$($(PSQL) -c 'SELECT 1')"
	@v=$$($(PSQL) -c "SELECT default_version FROM pg_available_extensions WHERE name = 'vector'"); \
	test -n "$$v" || { echo "vector extension not available in this image"; exit 1; }; \
	echo "vector extension available, default_version $$v"

generate: ## generate the Prisma client into packages/db/src/generated
	$(PRISMA) generate

migrate: ## create and apply a dev migration (NAME=<migration_name>)
	@test -n "$(NAME)" || { echo "Run: make migrate NAME=<migration_name>"; exit 1; }
	$(PRISMA) migrate dev --name $(NAME) $(ARGS)

migrate-deploy: ## apply pending migrations without creating new ones (CI)
	$(PRISMA) migrate deploy

migrate-reset: ## drop the database, re-apply every migration, regenerate (requires CONFIRM=yes)
	@test "$(CONFIRM)" = yes || { echo "migrate-reset drops the database. Run: make migrate-reset CONFIRM=yes"; exit 1; }
	$(PRISMA) migrate reset --force

studio: ## open Prisma Studio
	$(PRISMA) studio

test: ## run every test with DATABASE_URL set
	pnpm test
