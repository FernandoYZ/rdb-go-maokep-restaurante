#!/usr/bin/env bash
set -euo pipefail

# ── Configuración ─────────────────────────────────────────────────────────────
MIGRATIONS_DIR="./database/migrations"

# ── Paleta de colores ─────────────────────────────────────────────────────────
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
_step() {
  local icon="$1" color="$2" label="$3" detail="${4:-}"
  if [[ -n "$detail" ]]; then
    printf "${MUTED}│${RESET}  ${color}${icon}${RESET}  ${WHITE}${label}${RESET}  ${MUTED}${detail}${RESET}\n"
  else
    printf "${MUTED}│${RESET}  ${color}${icon}${RESET}  ${WHITE}${label}${RESET}\n"
  fi
}

_info() {
  printf "${MUTED}│${RESET}  ${MUTED}${1}${RESET}\n"
}

_divider() {
  printf "${MUTED}├──────────────────────────────────────────────────────────────────${RESET}\n"
}

_fail() {
  _divider
  printf "${MUTED}│${RESET}  ${RED}${BOLD}✗ Error${RESET}  ${WHITE}${1}${RESET}\n"
  [[ -n "${2:-}" ]] && printf "${MUTED}│${RESET}  ${MUTED}${2}${RESET}\n"
  printf "${MUTED}└──────────────────────────────────────────────────────────────────${RESET}\n\n"
  exit 1
}

# ── Encabezado ────────────────────────────────────────────────────────────────
printf "\n"
printf "${MUTED}┌──────────────────────────────────────────────────────────────────${RESET}\n"
printf "${MUTED}│${RESET}  ${BOLD}${PURPLE}◆ maokep${RESET}   ${MUTED}database · make migration${RESET}   ${DIM}$(date '+%H:%M:%S')${RESET}\n"
_divider

# ── Validar argumento ─────────────────────────────────────────────────────────
if [[ -z "${1:-}" ]]; then
  _fail "No se proporcionó el nombre de la migración" "Uso: make make-migration NOMBRE_TABLA"
fi

# ── Procesar nombre ───────────────────────────────────────────────────────────
NAME=$(echo "$1" | tr '[:upper:] -' '[:lower:]_')

# Singularizar de forma simple: ies → y, s final
NAME_SINGULAR="$NAME"
NAME_SINGULAR=$(echo "$NAME_SINGULAR" | sed 's/ies$/y/')
NAME_SINGULAR=$(echo "$NAME_SINGULAR" | sed 's/s$//')

_step "✓" "$GREEN" "Nombre procesado" "${NAME} → singular: ${NAME_SINGULAR}"

# ── Preparar directorios ──────────────────────────────────────────────────────
mkdir -p "$MIGRATIONS_DIR/up" "$MIGRATIONS_DIR/down"

# ── Calcular versión ──────────────────────────────────────────────────────────
LAST=$(find "$MIGRATIONS_DIR/up" -type f -name "*.up.sql" | sort | tail -n 1)

if [[ -z "$LAST" ]]; then
  NEXT=1
else
  PREFIX=$(basename "$LAST" | cut -d'_' -f1)
  NEXT=$((10#$PREFIX + 1))
fi

VERSION=$(printf "%03d" "$NEXT")
_step "✓" "$GREEN" "Versión asignada" "${VERSION}"

# ── Definir rutas ─────────────────────────────────────────────────────────────
FILE_UP="$MIGRATIONS_DIR/up/${VERSION}_${NAME}.up.sql"
FILE_DOWN="$MIGRATIONS_DIR/down/${VERSION}_${NAME}.down.sql"

# Evitar sobrescribir archivos existentes
[[ -f "$FILE_UP" || -f "$FILE_DOWN" ]] && _fail "Los archivos de migración ya existen" "${FILE_UP} / ${FILE_DOWN}"

# ── Crear archivo UP ──────────────────────────────────────────────────────────
cat > "$FILE_UP" <<EOF
BEGIN;

-- Migración:  ${NAME}
-- Creado:     $(date '+%Y-%m-%d %H:%M:%S')
-- Versión:    ${VERSION}

CREATE TABLE IF NOT EXISTS ${NAME} (
    -- id_${NAME_SINGULAR}    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
EOF

# ── Crear archivo DOWN ─────────────────────────────────────────────────────────
cat > "$FILE_DOWN" <<EOF
BEGIN;

-- Reversión:  ${NAME}
-- Creado:     $(date '+%Y-%m-%d %H:%M:%S')
-- Versión:    ${VERSION}

DROP TABLE IF EXISTS ${NAME};

COMMIT;
EOF

# ── Footer ────────────────────────────────────────────────────────────────────
_divider
printf "${MUTED}│${RESET}  ${GREEN}${BOLD}✓ Listo${RESET}  ${MUTED}Archivos de migración creados${RESET}\n"
_divider
_step "↑" "$BLUE" "up  " "${FILE_UP}"
_step "↓" "$YELLOW" "down" "${FILE_DOWN}"
printf "${MUTED}└──────────────────────────────────────────────────────────────────${RESET}\n\n"