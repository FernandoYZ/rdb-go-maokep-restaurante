#!/usr/bin/env bash
set -euo pipefail

NETWORK="per-ssr-go-restaurante-maokep_backend"

# ── Paleta ────────────────────────────────────────────────────────────────────
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

WHITE='\033[38;2;255;255;255m'
GRAY='\033[38;2;113;113;122m'
MUTED='\033[38;2;63;63;70m'
GREEN='\033[38;2;74;222;128m'
YELLOW='\033[38;2;250;204;21m'
RED='\033[38;2;248;113;113m'
BLUE='\033[38;2;96;165;250m'
PURPLE='\033[38;2;167;139;250m'

# ── Helpers ───────────────────────────────────────────────────────────────────
_line() {
  printf "${MUTED}│${RESET}  %s\n" "$1"
}

_step() {
  local icon="$1" color="$2" label="$3" detail="${4:-}"
  if [[ -n "$detail" ]]; then
    printf "${MUTED}│${RESET}  ${color}${icon}${RESET}  ${WHITE}${label}${RESET}  ${MUTED}${detail}${RESET}\n"
  else
    printf "${MUTED}│${RESET}  ${color}${icon}${RESET}  ${WHITE}${label}${RESET}\n"
  fi
}

_divider() {
  printf "${MUTED}├─────────────────────────────────────────${RESET}\n"
}

_duration() {
  local ms=$1
  printf "%.2fs" "$(awk "BEGIN { printf \"%.2f\", $ms/1000 }")"
}

# ── Encabezado ────────────────────────────────────────────────────────────────
printf "\n"
printf "${MUTED}┌─────────────────────────────────────────${RESET}\n"
printf "${MUTED}│${RESET}  ${BOLD}${PURPLE}◆ maokep${RESET}   ${MUTED}make reset${RESET}   ${DIM}$(date '+%H:%M:%S')${RESET}\n"
_divider

# ── Ejecución ─────────────────────────────────────────────────────────────────
start_ms=$(date +%s%3N)

_step "○" "$GRAY"   "Deteniendo contenedores"
podman-compose down -v --remove-orphans >/dev/null 2>&1 || true
_step "✓" "$GREEN"  "Contenedores detenidos"

_line ""

_step "○" "$GRAY"   "Comprobando redes huérfanas"
if podman network exists "$NETWORK" 2>/dev/null; then
  _step "⚠" "$YELLOW" "Red encontrada" "$NETWORK"
  podman network rm --force "$NETWORK" >/dev/null 2>&1
  _step "✓" "$GREEN"  "Red eliminada"
else
  _step "–" "$MUTED"  "No se encontraron redes huérfanas"
fi

# ── Pie ───────────────────────────────────────────────────────────────────────
end_ms=$(date +%s%3N)
elapsed=$(( end_ms - start_ms ))

_divider
printf "${MUTED}│${RESET}  ${GREEN}${BOLD}✓ Listo${RESET}  ${MUTED}Entorno eliminado${RESET}  ${DIM}$(_duration "$elapsed")${RESET}\n"
printf "${MUTED}└─────────────────────────────────────────${RESET}\n"
printf "\n"