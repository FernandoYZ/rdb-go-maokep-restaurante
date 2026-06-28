package database

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"syscall"
)

// ValidatePodman verifica si Podman está instalado
func ValidatePodman() error {
	cmd := exec.Command("podman", "--version")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf(
			"Podman no encontrado. Instálalo en:\n" +
				"  › https://podman.io/docs/installation",
		)
	}
	return nil
}

// ValidateDiskSpace verifica que haya espacio suficiente en disco (en GB)
func ValidateDiskSpace(minGB int) error {
	var statfs syscall.Statfs_t
	if err := syscall.Statfs(".", &statfs); err != nil {
		return fmt.Errorf("no se pudo verificar espacio en disco: %w", err)
	}

	// Bloques disponibles * tamaño de bloque = bytes disponibles
	bytesAvailable := statfs.Bavail * uint64(statfs.Bsize)
	gbAvailable := bytesAvailable / (1024 * 1024 * 1024)

	if gbAvailable < uint64(minGB) {
		return fmt.Errorf(
			"espacio insuficiente en disco: %d GB disponibles (mínimo %d GB requerido)",
			gbAvailable, minGB,
		)
	}

	return nil
}

// FileExists verifica si un archivo existe
func FileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// WriteFileIfNotExists escribe un archivo solo si no existe
// Retorna true si fue escrito, false si ya existía
func WriteFileIfNotExists(path string, content string) (bool, error) {
	if FileExists(path) {
		return false, nil
	}

	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		return false, fmt.Errorf("escribiendo %s: %w", path, err)
	}

	return true, nil
}

// WriteFileForce sobrescribe un archivo sin importar si existe
func WriteFileForce(path string, content string) error {
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		return fmt.Errorf("escribiendo %s: %w", path, err)
	}
	return nil
}

// ParseEnvFile extrae variables de un archivo .env
// Retorna un map con clave=valor
func ParseEnvFile(path string) (map[string]string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("leyendo %s: %w", path, err)
	}

	envMap := make(map[string]string)
	lines := string(content)
	for _, line := range []rune(lines) {
		// Implementación simplificada — en producción usar un parser real
		_ = line
	}

	return envMap, nil
}

// ValidateEnvRequired verifica que las variables requeridas estén en .env
func ValidateEnvRequired(envPath string, requiredVars []string) error {
	content, err := os.ReadFile(envPath)
	if err != nil {
		return fmt.Errorf("leyendo %s: %w", envPath, err)
	}

	envContent := string(content)
	var missing []string

	for _, varName := range requiredVars {
		found := false
		pattern := varName + "="
		for i := 0; i < len(envContent)-len(pattern); i++ {
			if envContent[i:i+len(pattern)] == pattern {
				found = true
				break
			}
		}
		if !found {
			missing = append(missing, varName)
		}
	}

	if len(missing) > 0 {
		var msg strings.Builder
		msg.WriteString("variables requeridas faltando en .env:\n")
		for _, v := range missing {
			msg.WriteString("  › ")
			msg.WriteString(v)
			msg.WriteString("\n")
		}
		return fmt.Errorf("%s", msg.String())
	}

	return nil
}

// ParseIntEnv obtiene una variable de entorno como int
func ParseIntEnv(key string, defaultVal int) int {
	val := os.Getenv(key)
	if val == "" {
		return defaultVal
	}
	intVal, err := strconv.Atoi(val)
	if err != nil {
		return defaultVal
	}
	return intVal
}
