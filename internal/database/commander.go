package database

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/console"
	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/database/migrate"
	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/database/schema"
)

const (
	defaultDirUp   = "database/migrations/up"
	defaultDirDown = "database/migrations/down"
)

// Commander encapsulates database CLI operations.
type Commander struct {
	db        *sql.DB
	reporter  console.Reporter
	ownerPass string
	appPass   string
	dirUp     string
	dirDown   string
}

// NewCommander creates a new database commander.
func NewCommander(db *sql.DB, reporter console.Reporter, ownerPass, appPass string) *Commander {
	return &Commander{
		db:        db,
		reporter:  reporter,
		ownerPass: ownerPass,
		appPass:   appPass,
		dirUp:     defaultDirUp,
		dirDown:   defaultDirDown,
	}
}

// Migrate runs pending migrations.
func (c *Commander) Migrate() error {
	start := time.Now()
	c.reporter.Section("migrate")

	if err := schema.Bootstrap(c.db); err != nil {
		return fmt.Errorf("bootstrap: %w", err)
	}

	if err := migrate.Run(c.db, c.dirUp, c.ownerPass, c.appPass, c.reporter); err != nil {
		return fmt.Errorf("migraciones: %w", err)
	}

	c.reporter.Success("Migraciones completadas en %s", time.Since(start).Round(time.Millisecond))
	return nil
}

// Rollback reverts the last migration.
func (c *Commander) Rollback() error {
	start := time.Now()
	c.reporter.Section("rollback")

	if err := migrate.Rollback(c.db, c.dirDown, c.reporter); err != nil {
		return fmt.Errorf("rollback: %w", err)
	}

	c.reporter.Success("Rollback completed   %s", time.Since(start).Round(time.Millisecond))
	return nil
}

// Fresh resets the database.
func (c *Commander) Fresh() error {
	start := time.Now()
	c.reporter.Section("fresh")
	c.reporter.Info("Reiniciando base de datos")

	tablas, err := schema.AllTables(c.db)
	if err != nil {
		return fmt.Errorf("listando tablas: %w", err)
	}

	if err := schema.DropAll(c.db, tablas); err != nil {
		return fmt.Errorf("eliminando tablas: %w", err)
	}
	c.reporter.Success("Tablas eliminadas (%d tablas)", len(tablas))

	if err := schema.Bootstrap(c.db); err != nil {
		return fmt.Errorf("bootstrap: %w", err)
	}

	if err := migrate.Run(c.db, c.dirUp, c.ownerPass, c.appPass, c.reporter); err != nil {
		return fmt.Errorf("migraciones: %w", err)
	}

	c.reporter.Success("Database restarted   %s", time.Since(start).Round(time.Millisecond))
	return nil
}

// Status shows the migration status.
func (c *Commander) Status() error {
	start := time.Now()
	c.reporter.Section("status")

	if err := schema.Bootstrap(c.db); err != nil {
		return fmt.Errorf("bootstrap: %w", err)
	}

	archivos, err := migrate.Discover(c.dirUp)
	if err != nil {
		return fmt.Errorf("descubriendo migraciones: %w", err)
	}

	registros, err := schema.TodosLosRegistros(c.db)
	if err != nil {
		return fmt.Errorf("leyendo registros: %w", err)
	}

	mapaAplicadas := make(map[string]string)
	for _, r := range registros {
		mapaAplicadas[r.Version] = r.EjecutadoEn.Format("2006-01-02 15:04:05")
	}

	header := []string{"VERSION", "NOMBRE", "ESTADO", "FECHA"}
	var rows [][]string

	pendientes := 0
	for _, a := range archivos {
		estado := "pendiente"
		fecha := "-"

		if f, ok := mapaAplicadas[a.Version]; ok {
			estado = "aplicada"
			fecha = f
		} else {
			pendientes++
		}

		rows = append(rows, []string{a.Version, a.Nombre, estado, fecha})
	}

	fmt.Println() // Space before table
	c.reporter.Table(header, rows)
	fmt.Println() // Space after table

	c.reporter.Field("Pending Migrations", fmt.Sprintf("%d de %d", pendientes, len(archivos)))
	c.reporter.Success("Query completed   %s", time.Since(start).Round(time.Millisecond))
	return nil
}
