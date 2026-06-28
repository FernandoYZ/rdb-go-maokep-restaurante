package database

import "embed"

//go:embed migrations/up/*.sql
var MigracionesUp embed.FS

//go:embed migrations/down/*.sql
var MigracionesDown embed.FS
