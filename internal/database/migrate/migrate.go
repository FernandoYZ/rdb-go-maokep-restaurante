package migrate

import (
	"context"
	"database/sql"
	"fmt"
	"io/fs"
	"path/filepath"
	"sort"
	"strings"

	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/console"
	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/database/schema"
)

// ArchivoMigracion representa un archivo de migración en un sistema de archivos.
type ArchivoMigracion struct {
	Version string
	Nombre  string
}

// Discover busca archivos de migración en el sistema de archivos provisto.
func Discover(fsys fs.FS) ([]ArchivoMigracion, error) {
	files, err := fs.Glob(fsys, "*.sql")
	if err != nil {
		return nil, fmt.Errorf("buscando archivos de migración: %w", err)
	}

	sort.Strings(files)

	var migraciones []ArchivoMigracion
	for _, file := range files {
		base := filepath.Base(file)
		if len(base) < 4 {
			continue
		}
		migraciones = append(migraciones, ArchivoMigracion{
			Version: base[:3],
			Nombre:  base,
		})
	}

	return migraciones, nil
}

// Run ejecuta las migraciones pendientes desde el fsys provisto.
func Run(db *sql.DB, fsys fs.FS, ownerPass, appPass string, reporter console.Reporter) error {
	aplicadas, err := schema.Aplicadas(db)
	if err != nil {
		return err
	}

	archivos, err := Discover(fsys)
	if err != nil {
		return err
	}

	for _, archivo := range archivos {
		if aplicadas[archivo.Version] {
			continue
		}

		reporter.Step("DONE   %s", archivo.Nombre)

		content, err := fs.ReadFile(fsys, archivo.Nombre)
		if err != nil {
			return fmt.Errorf("leyendo archivo %s: %w", archivo.Nombre, err)
		}

		query := string(content)
		// Inyección de contraseñas (Estrategia DBA)
		query = strings.ReplaceAll(query, "{OWNER_PASS}", ownerPass)
		query = strings.ReplaceAll(query, "{APP_PASS}", appPass)

		tx, err := db.BeginTx(context.Background(), nil)
		if err != nil {
			return err
		}

		if _, err := tx.Exec(query); err != nil {
			tx.Rollback()
			return fmt.Errorf("ejecutando %s: %w", archivo.Nombre, err)
		}

		if err := schema.RegistrarTX(tx, archivo.Version, archivo.Nombre); err != nil {
			tx.Rollback()
			return err
		}

		if err := tx.Commit(); err != nil {
			return err
		}
	}

	return nil
}

// Rollback revierte la última migración aplicada usando el fsys provisto.
func Rollback(db *sql.DB, fsys fs.FS, reporter console.Reporter) error {
	ultima, existe, err := schema.UltimaAplicada(db)
	if err != nil {
		return err
	}

	if !existe {
		reporter.Info("No migrations to rollback")
		return nil
	}

	filename := fmt.Sprintf("%s_%s", ultima.Version, strings.TrimPrefix(ultima.Nombre, ultima.Version+"_"))
	filename = strings.TrimSuffix(filename, ".up.sql")
	if !strings.HasSuffix(filename, ".down.sql") {
		filename += ".down.sql"
	}

	reporter.Step("Rolling back %s", filename)

	content, err := fs.ReadFile(fsys, filename)
	if err != nil {
		return fmt.Errorf("rollback file not found: %s", filename)
	}

	tx, err := db.BeginTx(context.Background(), nil)
	if err != nil {
		return err
	}

	if _, err := tx.Exec(string(content)); err != nil {
		tx.Rollback()
		return fmt.Errorf("error rolling back %s: %w", filename, err)
	}

	if err := schema.EliminarTX(tx, ultima.Version); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit()
}
