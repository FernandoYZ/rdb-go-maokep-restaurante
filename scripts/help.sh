#!/usr/bin/env bash
set -uo pipefail

printf "\n  ── maokep restaurante · help ─────────────────────────\n\n"

printf "  Entorno\n"
printf "  › make up     Levanta el entorno y ejecuta migraciones\n"
printf "  › make reset  Limpia contenedores, redes y reinicia\n\n"

printf "  Database\n"
printf "  › make status     Muestra el estado de las migraciones\n"
printf "  › make migrate    Ejecuta migraciones pendientes\n"
printf "  › make rollback   Revierte la última migración\n"
printf "  › make fresh      Borra tablas y re-ejecuta todo\n"
printf "  › make migration  Crea una migración (up/down)\n"

printf "\n────────────────────────────────────────────────────────\n"
printf "  Tip: usa make <comando> para mayor rapidez\n"
printf "────────────────────────────────────────────────────────\n"
