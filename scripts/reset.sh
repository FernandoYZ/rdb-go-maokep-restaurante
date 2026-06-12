#!/usr/bin/env bash
set -uo pipefail

NETWORK="$(basename "$PWD")_backend"
STATUS=0

printf "\n"
printf "── maokep entorno · make reset ─────────────────────────\n\n"

printf "  › Stop containers ...................... "
if podman-compose down -v --remove-orphans >/dev/null 2>&1; then
  printf "%s\n" "✓"
else
  printf "%s\n" "× failed"
  STATUS=1
fi

printf "  › Remove orphan network ................ "
if podman network exists "$NETWORK" 2>/dev/null; then
  if podman network rm --force "$NETWORK" >/dev/null 2>&1; then
    printf "%s\n" "✓"
  else
    printf "%s\n" "× failed"
    STATUS=1
  fi
else
  printf "%s\n" "- skipped"
fi

printf "\n"
printf "────────────────────────────────────────────────────────\n"
if [ "$STATUS" -eq 0 ]; then
  printf "  ✓ SUCCESS   reset complete\n"
else
  printf "  × FAILED    reset incomplete\n"
fi
printf "────────────────────────────────────────────────────────\n\n"

exit "$STATUS"