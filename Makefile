.DEFAULT_GOAL := help
.PHONY: up reset migrate status rollback fresh migration help

up:
	./scripts/up.sh

reset:
	./scripts/reset.sh

migrate:
	go run cmd/cli/main.go migrate

status:
	go run cmd/cli/main.go status

rollback:
	go run cmd/cli/main.go rollback

fresh:
	go run cmd/cli/main.go fresh

migration:
	@./scripts/migration.sh $(filter-out $@,$(MAKECMDGOALS))

help:
	./scripts/help.sh

ifneq ($(filter migration,$(MAKECMDGOALS)),)
%:
	@:
else
%:
	@./scripts/help.sh
endif