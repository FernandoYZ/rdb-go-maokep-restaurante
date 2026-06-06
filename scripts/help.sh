#!/usr/bin/env bash

# ── Paleta ────────────────────────────────────────────────────────────────────
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

WHITE='\033[38;2;255;255;255m'
MUTED='\033[38;2;63;63;70m'
GRAY='\033[38;2;113;113;122m'
GREEN='\033[38;2;74;222;128m'
YELLOW='\033[38;2;250;204;21m'
BLUE='\033[38;2;96;165;250m'
PURPLE='\033[38;2;167;139;250m'

# ── Helpers ───────────────────────────────────────────────────────────────────
_divider() {
  printf "${MUTED}├──────────────────────────────────────────────────────────────────${RESET}\n"
}

_gap() {
  printf "${MUTED}│${RESET}\n"
}

_section() {
  printf "${MUTED}│${RESET}  ${DIM}${1}${RESET}\n"
}

_cmd() {
  printf "${MUTED}│${RESET}  ${2}  ${WHITE}${BOLD}%-20s${RESET}  ${MUTED}%s${RESET}\n" "$3" "$4"
}

_example() {
  printf "${MUTED}│${RESET}       ${DIM}%s${RESET}  ${GRAY}%s${RESET}\n" "$1" "$2"
}

# ── Header ────────────────────────────────────────────────────────────────────
printf "\n"
printf "${MUTED}┌──────────────────────────────────────────────────────────────────${RESET}\n"
printf "${MUTED}│${RESET}  ${BOLD}${PURPLE}◆ maokep restaurante${RESET}   ${MUTED}ayuda · comandos del sistema${RESET}\n"
_divider

# ── Entorno ───────────────────────────────────────────────────────────────
_section "ENTORNO"
_gap
_cmd "" "↑" "make up"    "Levanta el entorno y espera PostgreSQL"
_cmd "" "↓" "make reset" "Detiene contenedores y limpia recursos"
_gap

# ── Base de datos ─────────────────────────────────────────────────────────────
_divider
_section "BASE DE DATOS"
_gap
_cmd "" "⊕" "make migration <nombre>" "Crea migración versionada (up/down)"
_example "make migration users" "→ 003_users.up.sql / .down.sql"
_gap

# ── Footer ────────────────────────────────────────────────────────────────────
_divider
printf "${MUTED}│${RESET}  ${MUTED}Tip: ejecuta make sin argumentos para ver ayuda${RESET}\n"
printf "${MUTED}└──────────────────────────────────────────────────────────────────${RESET}\n\n"