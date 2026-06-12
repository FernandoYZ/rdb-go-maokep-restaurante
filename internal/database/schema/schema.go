package schema

import (
	"database/sql"
	"fmt"
	"time"
)

// RegistroMigracion representa una migración aplicada.
type RegistroMigracion struct {
	Version     string
	Nombre      string
	EjecutadoEn time.Time
}

// Bootstrap crea la tabla de migraciones.
func Bootstrap(db *sql.DB) error {
	const ddl = `
CREATE TABLE IF NOT EXISTS schema_migrations (
    version      TEXT        PRIMARY KEY,
    name         TEXT        NOT NULL,
    executed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
)`

	if _, err := db.Exec(ddl); err != nil {
		return fmt.Errorf(
			"bootstrap schema_migrations: %w",
			err,
		)
	}

	return nil
}

// Aplicadas devuelve las migraciones ejecutadas.
func Aplicadas(db *sql.DB) (map[string]bool, error) {
	rows, err := db.Query(`
SELECT version
FROM schema_migrations
ORDER BY executed_at`,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"consultando migraciones aplicadas: %w",
			err,
		)
	}

	defer rows.Close()

	resultado := make(map[string]bool)

	for rows.Next() {
		var version string

		if err := rows.Scan(&version); err != nil {
			return nil, fmt.Errorf(
				"leyendo versión: %w",
				err,
			)
		}

		resultado[version] = true
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterando migraciones: %w",
			err,
		)
	}

	return resultado, nil
}

// TodosLosRegistros devuelve todas las migraciones.
func TodosLosRegistros(
	db *sql.DB,
) ([]RegistroMigracion, error) {

	const q = `
SELECT version, name, executed_at
FROM schema_migrations
ORDER BY executed_at ASC`

	rows, err := db.Query(q)
	if err != nil {
		return nil, fmt.Errorf(
			"consultando schema_migrations: %w",
			err,
		)
	}

	defer rows.Close()

	var registros []RegistroMigracion

	for rows.Next() {
		var registro RegistroMigracion

		if err := rows.Scan(
			&registro.Version,
			&registro.Nombre,
			&registro.EjecutadoEn,
		); err != nil {
			return nil, fmt.Errorf(
				"leyendo registro de migración: %w",
				err,
			)
		}

		registros = append(registros, registro)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf(
			"iterando schema_migrations: %w",
			err,
		)
	}

	return registros, nil
}

// UltimaAplicada devuelve la última migración.
func UltimaAplicada(
	db *sql.DB,
) (RegistroMigracion, bool, error) {

	const q = `
SELECT version, name, executed_at
FROM schema_migrations
ORDER BY executed_at DESC
LIMIT 1`

	var registro RegistroMigracion

	err := db.QueryRow(q).Scan(
		&registro.Version,
		&registro.Nombre,
		&registro.EjecutadoEn,
	)

	if err == sql.ErrNoRows {
		return RegistroMigracion{}, false, nil
	}

	if err != nil {
		return RegistroMigracion{}, false, fmt.Errorf(
			"consultando última migración: %w",
			err,
		)
	}

	return registro, true, nil
}

// RegistrarTX guarda una migración dentro de una transacción.
func RegistrarTX(
	tx *sql.Tx,
	version,
	nombre string,
) error {

	const q = `
INSERT INTO schema_migrations (version, name)
VALUES ($1, $2)`

	if _, err := tx.Exec(q, version, nombre); err != nil {
		return fmt.Errorf(
			"registrando migración %q en tx: %w",
			version,
			err,
		)
	}

	return nil
}

// Registrar guarda una migración.
func Registrar(
	db *sql.DB,
	version,
	nombre string,
) error {

	const q = `
INSERT INTO schema_migrations (version, name)
VALUES ($1, $2)`

	if _, err := db.Exec(q, version, nombre); err != nil {
		return fmt.Errorf(
			"registrando migración %q: %w",
			version,
			err,
		)
	}

	return nil
}

// EliminarTX borra una migración dentro de una transacción.
func EliminarTX(
	tx *sql.Tx,
	version string,
) error {

	const q = `
DELETE FROM schema_migrations
WHERE version = $1`

	if _, err := tx.Exec(q, version); err != nil {
		return fmt.Errorf(
			"eliminando migración %q en tx: %w",
			version,
			err,
		)
	}

	return nil
}

// Eliminar borra una migración.
func Eliminar(
	db *sql.DB,
	version string,
) error {

	const q = `
DELETE FROM schema_migrations
WHERE version = $1`

	if _, err := db.Exec(q, version); err != nil {
		return fmt.Errorf(
			"eliminando migración %q: %w",
			version,
			err,
		)
	}

	return nil
}