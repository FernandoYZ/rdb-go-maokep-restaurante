#!/usr/bin/env bash
set -uo pipefail

# Intentar cargar .env de forma segura
if [[ -f .env ]]; then
  # shellcheck source=/dev/null
  source .env
else
  printf "Error: Archivo .env no encontrado.\n"
  exit 1
fi

CONTAINER="maokep-restaurante"
MAX_WAIT=60
WIDTH=56  # Ancho estándar de la interfaz de consola

# ── FUNCIONES DE DISEÑO Y CONTROL ───────────────────────

_line() {
  printf '─%.0s' $(seq 1 "$1")
}

_heading() {
  local title=" $1 "
  local title_len=${#title}
  local rem=$((WIDTH - 4 - title_len))
  printf "\n──%s%s\n\n" "$title" "$(_line $rem)"
}

# Inicia el cronómetro para un paso específico
_step_start() {
  STEP_START_TIME=$SECONDS
  local label="$1"
  # 15 = espacio reservado para " X X.XXs" (icono + espacio + duración)
  local dots_len=$((WIDTH - 15 - ${#label}))
  local dots=""
  [[ $dots_len -gt 0 ]] && dots=$(printf '%*s' "$dots_len" '' | tr ' ' '.')
  printf "  › %s %s " "$label" "$dots"
}

# Finaliza el cronómetro del paso actual e imprime el resultado con su tiempo
_step_end() {
  local status="$1"
  local duration=$((SECONDS - STEP_START_TIME))
  printf "%s %0.2fs\n" "$status" "$duration"
}

_success() {
  local steps="$1"
  local total_time="$2"
  local current_hour
  current_hour=$(date '+%H:%M:%S')

  printf "\n%s\n" "$(_line $WIDTH)"
  printf "  ✓ SUCCESS   %s   %0.2fs   %s\n" "$steps" "$total_time" "$current_hour"
  printf "%s\n\n" "$(_line $WIDTH)"
}

_fail() {
  local error_msg="$1"
  local help_msg="${2:-}"
  local title=" ERROR "
  local title_len=${#title}
  local rem=$((WIDTH - 4 - title_len))

  # 1. Caja de error intermedia
  printf "\n╭─%s%s\n" "$title" "$(_line $rem)"
  printf "│ %s\n" "$error_msg"
  [[ -n "$help_msg" ]] && printf "│ %s\n" "$help_msg"
  printf "╰%s\n" "$(_line $((WIDTH - 1)))"

  # 2. Bloque de cierre FAILED
  printf "%s\n" "$(_line $WIDTH)"
  printf "  × FAILED    up incomplete\n"
  printf "%s\n\n" "$(_line $WIDTH)"
  exit 1
}

# ── INICIO DEL SCRIPT ───────────────────────────────────

# Guardar el inicio absoluto para el reporte final
TOTAL_START_TIME=$SECONDS

_heading "maokep entorno · make up"

# Paso 1
_step_start "Stop previous environment"
podman-compose down -v --remove-orphans >/dev/null 2>&1 || true
_step_end "✓"

# Paso 2
_step_start "Start containers"
if podman-compose up -d >/dev/null 2>&1; then
  _step_end "✓"
else
  _step_end "×"
  _fail "No se pudieron levantar los contenedores con podman-compose" "Verifica que el demonio de Podman esté corriendo."
fi

# Paso 3
_step_start "Wait for container"
elapsed=0
until podman container exists "$CONTAINER" 2>/dev/null; do
  sleep 1
  elapsed=$((elapsed + 1))
  if [[ "$elapsed" -ge "$MAX_WAIT" ]]; then
    _step_end "×"
    _fail "Se superó el tiempo de espera para el contenedor: $CONTAINER" "Aumenta MAX_WAIT o revisa los logs de podman."
  fi
done
_step_end "✓"

# Paso 4
_step_start "Wait for PostgreSQL"
elapsed=0
until podman exec "$CONTAINER" pg_isready -U "${DB_USER:-postgres}" -d "${DB_NAME:-postgres}" >/dev/null 2>&1; do
  sleep 1
  elapsed=$((elapsed + 1))
  if [[ "$elapsed" -ge "$MAX_WAIT" ]]; then
    _step_end "×"
    _fail "PostgreSQL no respondió a tiempo en el contenedor" "Verifica las credenciales DB_USER y DB_NAME en tu archivo .env"
  fi
done
_step_end "✓"

# Paso 5
_step_start "Run migrations"
if go run cmd/cli/main.go migrate >/dev/null 2>&1; then
  _step_end "✓"
else
  _step_end "×"
  _fail "La ejecución de las migraciones de Go falló" "Ejecuta 'go run cmd/cli/main.go migrate' manualmente para ver los errores."
fi

# Cálculo del tiempo total
TOTAL_DURATION=$((SECONDS - TOTAL_START_TIME))

_success "5/5 steps" "$TOTAL_DURATION"