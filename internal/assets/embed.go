package assets

// ComposeYML contiene el docker-compose.yml embebido
const ComposeYML = `services:
  postgres:
    image: docker.io/postgres:17
    container_name: maokep-restaurante

    restart: unless-stopped

    env_file:
      - .env

    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}

    ports:
      - "127.0.0.1:${DB_PORT}:5432"

    command: >
      postgres
      -c shared_buffers=3GB
      -c effective_cache_size=9GB
      -c work_mem=32MB
      -c maintenance_work_mem=512MB

    volumes:
      - postgres_data:/var/lib/postgresql/data:Z

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 5s

volumes:
  postgres_data:
`

// EnvExample contiene el .env.example embebido
const EnvExample = `# Base de datos
DB_NAME=maokep-restaurante
DB_PORT=5432
DB_HOST=localhost
DB_SSLMODE=disable

# Superusuario (Solo para mantenimiento inicial y creación de roles)
DB_USER=postgres
DB_PASSWORD=contraseña_ultra_segura

# Rol de Migraciones (Owner - DDL)
DB_OWNER_USER=maokep_dueno_esquema
DB_OWNER_PASSWORD=contraseña_ultra_segura

# Rol de Aplicación (App User - DML)
DB_APP_USER=maokep_usuario_app
DB_APP_PASSWORD=contraseña_ultra_segura

# Entorno de la aplicación
APP_ENV=production
`
