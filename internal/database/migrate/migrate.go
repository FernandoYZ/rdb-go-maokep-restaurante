package migrate

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/console"
	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/database/schema"
)

// ArchivoMigracion representa un archivo de migración en disco.
type ArchivoMigracion struct {
	Version string
	Nombre  string
	Ruta    string
}

// Discover busca archivos de migración en el directorio especificado.
func Discover(directorio string) ([]ArchivoMigracion, error) {
	files, err := filepath.Glob(filepath.Join(directorio, "*.sql"))
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
			Ruta:    file,
		})
	}

	return migraciones, nil
}

// Run ejecuta las migraciones pendientes.
func Run(db *sql.DB, directorio string, ownerPass, appPass string, reporter console.Reporter) error {
	aplicadas, err := schema.Aplicadas(db)
	if err != nil {
		return err
	}

	archivos, err := Discover(directorio)
	if err != nil {
		return err
	}

	for _, archivo := range archivos {
		if aplicadas[archivo.Version] {
			continue
		}

		reporter.Step("DONE   %s", archivo.Nombre)

		content, err := os.ReadFile(archivo.Ruta)
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

// Rollback revierte la última migración aplicada.
func Rollback(db *sql.DB, directorioDown string, reporter console.Reporter) error {
	ultima, existe, err := schema.UltimaAplicada(db)
	if err != nil {
		return err
	}

	if !existe {
		reporter.Info("No hay migraciones para revertir")
		return nil
	}

	filename := fmt.Sprintf("%s_%s", ultima.Version, strings.TrimPrefix(ultima.Nombre, ultima.Version+"_"))
	filename = strings.TrimSuffix(filename, ".up.sql")
	if !strings.HasSuffix(filename, ".down.sql") {
		filename += ".down.sql"
	}

	path := filepath.Join(directorioDown, filename)
	reporter.Step("Revirtiendo %s", filename)

	content, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("no se encontró el archivo de reversión: %s", path)
	}

	tx, err := db.BeginTx(context.Background(), nil)
	if err != nil {
		return err
	}

	if _, err := tx.Exec(string(content)); err != nil {
		tx.Rollback()
		return fmt.Errorf("error revirtiendo %s: %w", filename, err)
	}

	if err := schema.EliminarTX(tx, ultima.Version); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit()
}

