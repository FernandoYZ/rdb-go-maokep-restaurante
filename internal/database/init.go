package database

import (
	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/assets"
	"github.com/FernandoYZ/rdb-go-maokep-restaurante/internal/console"
)

type InitCommand struct {
	Reporter console.Reporter
}

func (cmd *InitCommand) Execute(force bool) error {
	cmd.Reporter.Section("init")

	cmd.Reporter.Step("Verificando requisitos previos")

	if err := ValidatePodman(); err != nil {
		return err
	}
	cmd.Reporter.Step("Podman: OK")

	if err := ValidateDiskSpace(2); err != nil {
		return err
	}
	cmd.Reporter.Step("Espacio en disco: OK (mínimo 2 GB)")

	if !force && FileExists("compose.yml") {
		cmd.Reporter.Info("compose.yml ya existe (usa --force para regenerar)")
	} else {
		if force && FileExists("compose.yml") {
			cmd.Reporter.Step("Regenerando compose.yml")
		} else {
			cmd.Reporter.Step("Generando compose.yml")
		}
		if err := WriteFileForce("compose.yml", assets.ComposeYML); err != nil {
			return err
		}
	}

	if !force && FileExists(".env.example") {
		cmd.Reporter.Info(".env.example ya existe (usa --force para regenerar)")
	} else {
		if force && FileExists(".env.example") {
			cmd.Reporter.Step("Regenerando .env.example")
		} else {
			cmd.Reporter.Step("Generando .env.example")
		}
		if err := WriteFileForce(".env.example", assets.EnvExample); err != nil {
			return err
		}
	}

	cmd.Reporter.Success("Inicialización completada")
	cmd.Reporter.Info("")
	cmd.Reporter.Info("Próximos pasos:")
	cmd.Reporter.Info("  1. cp .env.example .env")
	cmd.Reporter.Info("  2. edita .env con tus credenciales")
	cmd.Reporter.Info("  3. podman-compose up -d")
	cmd.Reporter.Info("  4. ./database migrate")
	cmd.Reporter.Info("")

	return nil
}
