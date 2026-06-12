package database

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/config"
	_ "github.com/jackc/pgx/v5/stdlib"
)

// NuevoPool abre un pool de conexiones PostgreSQL usando ConfigBD
// y verifica la conectividad mediante Ping.
// El llamador es responsable de ejecutar db.Close().
func NuevoPool(cfg config.ConfigBD) (*sql.DB, error) {
	cadenaConexion := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		cfg.Host,
		cfg.Puerto,
		cfg.Usuario,
		cfg.Password,
		cfg.NombreBD,
	)

	baseDatos, err := sql.Open("pgx", cadenaConexion)
	if err != nil {
		return nil, fmt.Errorf(
			"abriendo pool de conexiones con pgx: %w",
			err,
		)
	}

	ConfigurarPool(baseDatos)

	if err := baseDatos.Ping(); err != nil {
		return nil, fmt.Errorf("error haciendo ping a la base de datos: %w", err)
	}

	return baseDatos, nil
}

// ConfigurarPool establece los límites recomendados para el pool de conexiones
// optimizado para un entorno VPS con recursos limitados (12GB RAM).
func ConfigurarPool(db *sql.DB) {
	// Límites conservadores para evitar agotar conexiones en el servidor
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(15 * time.Minute)
	db.SetConnMaxIdleTime(5 * time.Minute)
}
