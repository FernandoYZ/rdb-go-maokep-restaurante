package schema

import (
	"database/sql"
	"fmt"
)

// AllTables obtiene los nombres de todas las tablas del esquema public.
func AllTables(db *sql.DB) ([]string, error) {
	rows, err := db.Query(`SELECT tablename FROM pg_tables WHERE schemaname = 'public'`)
	if err != nil {
		return nil, fmt.Errorf("querying pg_tables: %w", err)
	}
	defer rows.Close()

	var tables []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return nil, fmt.Errorf("scanning table name: %w", err)
		}
		tables = append(tables, name)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterating pg_tables rows: %w", err)
	}

	return tables, nil
}

// DropAll elimina las tablas indicadas.
func DropAll(db *sql.DB, tables []string) error {
	for _, name := range tables {
		stmt := fmt.Sprintf(`DROP TABLE IF EXISTS %q CASCADE`, name)
		if _, err := db.Exec(stmt); err != nil {
			return fmt.Errorf("dropping table %q: %w", name, err)
		}
	}
	return nil
}
