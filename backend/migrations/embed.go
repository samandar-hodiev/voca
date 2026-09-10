// Package migrations embeds the SQL migration files.
//
// They live here, at the path ARCHITECTURE.md section 28 documents, and are embedded so
// the binary that applies them is the binary that carries them. A deploy can then never
// run one image's code against another image's schema.
package migrations

import "embed"

//go:embed *.sql
var FS embed.FS
