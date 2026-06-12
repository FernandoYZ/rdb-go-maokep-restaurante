#!/usr/bin/env bash
set -euo pipefail

MIGRATIONS_DIR="./database/migrations"
WIDTH=58

_line() { printf '─%.0s' $(seq 1 "$1"); }

_heading() {
  local title=" $1 "
  local rem=$((WIDTH - 2 - ${#title}))
  printf "\n──%s%s\n\n" "$title" "$(_line $rem)"
}

_field() {
  local label="$1" value="$2"
  local dots_len=$((WIDTH - 6 - ${#label} - ${#value}))
  local dots=""
  [[ $dots_len -gt 0 ]] && dots=$(printf '%*s' "$dots_len" '' | tr ' ' '.')
  printf "  › %s %s %s\n" "$label" "$dots" "$value"
}

_success() {
  printf "\n%s\n" "$(_line $WIDTH)"
  printf "  ✓ SUCCESS   %s\n" "$1"
  printf "%s\n\n" "$(_line $WIDTH)"
}

_fail() {
  printf "\n%s\n" "$(_line $WIDTH)"
  printf "  × FAILED    %s\n" "$1"
  [[ -n "${2:-}" ]] && printf "\n  %s\n" "$2"
  printf "\n%s\n\n" "$(_line $WIDTH)"
  exit 1
}

# ── INICIO DEL SCRIPT ───────────────────────────────────

_heading "maokep database · migration"

if [[ -z "${1:-}" ]]; then
  _fail "No se proporcionó el nombre de la migración" "Uso: make migration NOMBRE_TABLA"
fi

NAME=$(echo "$1" | tr '[:upper:] -' '[:lower:]_')

NAME_SINGULAR="$NAME"
[[ "$NAME_SINGULAR" == *ies ]] && NAME_SINGULAR="${NAME_SINGULAR%ies}y" || NAME_SINGULAR="${NAME_SINGULAR%s}"

_field "Tabla" "${NAME}"

mkdir -p "$MIGRATIONS_DIR/up" "$MIGRATIONS_DIR/down"

LAST=$(find "$MIGRATIONS_DIR/up" -type f -name "*.up.sql" 2>/dev/null | sort | tail -n 1)

if [[ -z "$LAST" ]]; then
  NEXT=1
else
  PREFIX=$(basename "$LAST" | cut -d'_' -f1)
  PREFIX_CLEAN=$(echo "$PREFIX" | sed 's/^0*//')
  NEXT=$(( ${PREFIX_CLEAN:-0} + 1 ))
fi

VERSION=$(printf "%03d" "$NEXT")
_field "Versión" "${VERSION}"

FILE_UP="$MIGRATIONS_DIR/up/${VERSION}_${NAME}.up.sql"
FILE_DOWN="$MIGRATIONS_DIR/down/${VERSION}_${NAME}.down.sql"

if [[ -f "$FILE_UP" || -f "$FILE_DOWN" ]]; then
  _fail "Los archivos de migración ya existen" "Elimina o renombra los archivos existentes"
fi

cat > "$FILE_UP" <<EOF
BEGIN;

-- Migración:  ${NAME}
-- Creado:     $(date '+%Y-%m-%d %H:%M:%S')
-- Versión:    ${VERSION}

CREATE TABLE IF NOT EXISTS ${NAME} (
    -- id_${NAME_SINGULAR}    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- creado_en  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMIT;
EOF

cat > "$FILE_DOWN" <<EOF
BEGIN;

-- Reversión:  ${NAME}
-- Creado:     $(date '+%Y-%m-%d %H:%M:%S')
-- Versión:    ${VERSION}

DROP TABLE IF EXISTS ${NAME};

COMMIT;
EOF

_field "up  " "${FILE_UP}"
_field "down" "${FILE_DOWN}"

_success "archivos de migración creados"