package main

import (
	"io/fs"
	"os"

	embeddb "github.com/FernandoYZ/rdb-go-maokep-restaurante/database"
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

	if comando == "init" {
		force := len(os.Args) > 2 && os.Args[2] == "--force"
		cmdInit := &database.InitCommand{Reporter: reporter}
		if err := cmdInit.Execute(force); err != nil {
			reporter.Fatal("Error ejecutando init", err, "")
		}
		return
	}

	cfg, err := config.CargarConfiguracionDatabase()
	if err != nil {
		reporter.Fatal("Error configurando base de datos", err, "")
	}

	db, err := database.NuevoPool(cfg)
	if err != nil {
		reporter.Fatal("Error de conexión", err, "Ejecuta 'make up' para levantar el entorno")
	}
	defer db.Close()

	// Configurar sistema de archivos virtual para las migraciones
	var fsysUp, fsysDown fs.FS
	var errSub error

	if os.Getenv("APP_ENV") == "production" || os.Getenv("APP_ENV") == "prod" {
		fsysUp, errSub = fs.Sub(embeddb.MigracionesUp, "migrations/up")
		if errSub != nil {
			reporter.Fatal("Error inicializando sistema de archivos embebido de migraciones up", errSub, "")
		}
		fsysDown, errSub = fs.Sub(embeddb.MigracionesDown, "migrations/down")
		if errSub != nil {
			reporter.Fatal("Error inicializando sistema de archivos embebido de migraciones down", errSub, "")
		}
	} else {
		fsysUp = os.DirFS("database/migrations/up")
		fsysDown = os.DirFS("database/migrations/down")
	}

	commander := database.NewCommander(
		db,
		reporter,
		os.Getenv("DB_OWNER_PASSWORD"),
		os.Getenv("DB_APP_PASSWORD"),
		fsysUp,
		fsysDown,
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
