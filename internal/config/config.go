package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

// ConfigBD almacena los parámetros de conexión a la base de datos.
type ConfigBD struct {
	Host     string
	Puerto   string
	Usuario  string
	Password string
	NombreBD string
}

// obtiene la configuración desde las variables de entorno.
func CargarConfiguracionDatabase() (ConfigBD, error) {
	_ = godotenv.Load()

	requeridas := []struct {
		clave string
		campo *string
	}{
		{"DB_HOST", nil},
		{"DB_PORT", nil},
		{"DB_USER", nil},
		{"DB_PASSWORD", nil},
		{"DB_NAME", nil},
	}

	config := ConfigBD{
		Host:     os.Getenv("DB_HOST"),
		Puerto:   os.Getenv("DB_PORT"),
		Usuario:  os.Getenv("DB_USER"),
		Password: os.Getenv("DB_PASSWORD"),
		NombreBD: os.Getenv("DB_NAME"),
	}

	requeridas[0].campo = &config.Host
	requeridas[1].campo = &config.Puerto
	requeridas[2].campo = &config.Usuario
	requeridas[3].campo = &config.Password
	requeridas[4].campo = &config.NombreBD

	for _, requerida := range requeridas {
		if *requerida.campo == "" {
			return ConfigBD{}, fmt.Errorf(
				"falta la variable de entorno: %s",
				requerida.clave,
			)
		}
	}

	return config, nil
}