package console

import (
	"fmt"
	"io"
	"os"
	"strings"
	"text/tabwriter"
	"time"
)

const (
	width = 56
)

// Reporter defines the interface for progress and status updates.
type Reporter interface {
	Heading(title string)
	Info(msg string, args ...any)
	Step(msg string, args ...any)
	Field(label, value string)
	Success(msg string, args ...any)
	Error(msg string, err error, hint string, args ...any)
	Fatal(msg string, err error, hint string, args ...any)
	Help()
	Table(header []string, rows [][]string)
	Section(name string)
}

// DefaultReporter implementa Reporter sin colores y con un estilo minimalista.
type DefaultReporter struct {
	output io.Writer
}

// NewDefaultReporter crea un nuevo DefaultReporter que escribe en os.Stdout.
func NewDefaultReporter() *DefaultReporter {
	return &DefaultReporter{
		output: os.Stdout,
	}
}

func (r *DefaultReporter) line() string {
	return strings.Repeat("─", width)
}

func (r *DefaultReporter) Heading(title string) {
	titleStr := fmt.Sprintf(" %s ", title)
	rem := width - 2 - len(titleStr)
	if rem < 0 {
		rem = 0
	}
	fmt.Fprintf(r.output, "\n──%s%s\n\n", titleStr, strings.Repeat("─", rem))
}

func (r *DefaultReporter) Info(msg string, args ...any) {
	fmt.Fprintf(r.output, "  › %s\n", fmt.Sprintf(msg, args...))
}

func (r *DefaultReporter) Step(msg string, args ...any) {
	fmt.Fprintf(r.output, "  › %s\n", fmt.Sprintf(msg, args...))
}

func (r *DefaultReporter) Field(label, value string) {
	dotsLen := width - 6 - len(label) - len(value)
	dots := ""
	if dotsLen > 0 {
		dots = strings.Repeat(".", dotsLen)
	}
	fmt.Fprintf(r.output, "  › %s %s %s\n", label, dots, value)
}

func (r *DefaultReporter) Success(msg string, args ...any) {
	currentHour := time.Now().Format("15:04:05")
	fmt.Fprintf(r.output, "\n%s\n", r.line())
	fmt.Fprintf(r.output, "  ✓ SUCCESS   %s   %s\n", fmt.Sprintf(msg, args...), currentHour)
	fmt.Fprintf(r.output, "%s\n\n", r.line())
}

func (r *DefaultReporter) Error(msg string, err error, hint string, args ...any) {
	m := fmt.Sprintf(msg, args...)
	
	fmt.Fprintf(r.output, "\n╭─ ERROR %s\n", strings.Repeat("─", width-10))
	if err != nil && os.Getenv("DEBUG") == "true" {
		fmt.Fprintf(r.output, "│ %s: %v\n", m, err)
	} else {
		fmt.Fprintf(r.output, "│ %s\n", m)
	}

	if hint != "" {
		fmt.Fprintf(r.output, "│ Sugerencia: %s\n", hint)
	}

	fmt.Fprintf(r.output, "╰%s\n", strings.Repeat("─", width-1))

	fmt.Fprintf(r.output, "%s\n", r.line())
	fmt.Fprintf(r.output, "  × FAILED    \n")
	fmt.Fprintf(r.output, "%s\n\n", r.line())
}

func (r *DefaultReporter) Fatal(msg string, err error, hint string, args ...any) {
	r.Error(msg, err, hint, args...)
	os.Exit(1)
}

func (r *DefaultReporter) Help() {
	fmt.Printf("\n  ── maokep restaurante · help ─────────────────────────\n\n")

	fmt.Printf("  Inicialización\n")
	fmt.Printf("  › init       Genera compose.yml y .env.example\n")
	fmt.Printf("  › init --force  Regenera los archivos\n\n")

	fmt.Printf("  Database\n")
	fmt.Printf("  › migrate    Ejecuta migraciones pendientes\n")
	fmt.Printf("  › rollback   Revierte la última migración\n")
	fmt.Printf("  › fresh      Reinicia la base de datos\n")
	fmt.Printf("  › status     Muestra el estado actual\n\n")

	fmt.Printf("────────────────────────────────────────────────────────\n")
	fmt.Printf("  Tip: usa make <comando> para mayor rapidez\n")
	fmt.Printf("────────────────────────────────────────────────────────\n\n")
	os.Exit(0)
}

// Section se mantiene para garantizar la compatibilidad con Commander, pero utiliza el estilo Heading.
func (r *DefaultReporter) Section(name string) {
	r.Heading("maokep database · " + name)
}

func (r *DefaultReporter) Table(header []string, rows [][]string) {
	w := tabwriter.NewWriter(r.output, 0, 0, 3, ' ', 0)
	
	// mostrar encabezado
	if len(header) > 0 {
		for i, h := range header {
			fmt.Fprint(w, h)
			if i < len(header)-1 {
				fmt.Fprint(w, "\t")
			}
		}
		fmt.Fprint(w, "\n")
	}

	// mostrar filas
	for _, row := range rows {
		for i, col := range row {
			fmt.Fprint(w, col)
			if i < len(row)-1 {
				fmt.Fprint(w, "\t")
			}
		}
		fmt.Fprint(w, "\n")
	}
	
	w.Flush()
}
