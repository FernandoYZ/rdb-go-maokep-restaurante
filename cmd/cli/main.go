package main

import (
	"os"

	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/config"
	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/console"
	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/database"
)

func main() {
	reporter := console.NewDefaultReporter()

	if len(os.Args) < 2 {
		reporter.Help()
	}

	comando := os.Args[1]

	cfg, err := config.CargarConfiguracionDatabase()
	if err != nil {
		reporter.Fatal("Error configurando base de datos", err, "")
	}

	db, err := database.NuevoPool(cfg)
	if err != nil {
		reporter.Fatal("Error de conexión", err, "Ejecuta 'make up' para levantar el entorno")
	}
	defer db.Close()

	commander := database.NewCommander(
		db,
		reporter,
		os.Getenv("DB_OWNER_PASSWORD"),
		os.Getenv("DB_APP_PASSWORD"),
	)

	switch comando {
	case "migrate":
		err = commander.Migrate()
	case "rollback":
		err = commander.Rollback()
	case "fresh":
		err = commander.Fresh()
	case "status":
		err = commander.Status()
	default:
		reporter.Error("Comando desconocido %q", nil, "", comando)
		reporter.Help()
	}

	if err != nil {
		reporter.Fatal("Error ejecutando comando", err, "")
	}
}
