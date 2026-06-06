.PHONY: up reset migration help

up:
	./scripts/up.sh

reset:
	./scripts/reset.sh

migration:
	./scripts/migration.sh $(filter-out $@,$(MAKECMDGOALS))

help:
	./scripts/help.sh

ifneq ($(filter migration,$(MAKECMDGOALS)),)
%:
	@:
else
%:
	@./scripts/help.sh
endif