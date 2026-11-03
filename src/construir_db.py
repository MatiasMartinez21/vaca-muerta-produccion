"""Construye la base analítica de Vaca Muerta en DuckDB a partir de los CSV
crudos y exporta el modelo estrella (dim_pozo, dim_calendario, fact_produccion)
en CSV y Parquet para consumir desde Power BI.

Uso:
    python src/construir_db.py
"""
from __future__ import annotations

import sys
from pathlib import Path

import duckdb

RAIZ = Path(__file__).resolve().parents[1]
RAW = RAIZ / "data" / "raw"
PROC = RAIZ / "data" / "processed"
SQL = RAIZ / "sql"
DB = RAIZ / "data" / "vaca_muerta.duckdb"

TABLAS_EXPORT = ["dim_pozo", "dim_calendario", "fact_produccion"]


def main() -> None:
    if not (RAW / "produccion_no_convencional.csv").exists():
        print(
            "No encuentro los CSV crudos. Corré primero:\n"
            "    python src/descargar_datos.py",
            file=sys.stderr,
        )
        sys.exit(1)

    PROC.mkdir(parents=True, exist_ok=True)
    DB.unlink(missing_ok=True)

    con = duckdb.connect(str(DB))
    # Las rutas de los CSV quedan disponibles como variables dentro del SQL.
    con.execute(f"SET VARIABLE ruta_prod = '{(RAW / 'produccion_no_convencional.csv').as_posix()}';")
    con.execute(f"SET VARIABLE ruta_padron = '{(RAW / 'padron_pozos.csv').as_posix()}';")

    for archivo in sorted(SQL.glob("*.sql")):
        print(f"Ejecutando {archivo.name} ...")
        con.execute(archivo.read_text(encoding="utf-8"))

    print("\nResumen del modelo estrella:")
    for t in TABLAS_EXPORT:
        n = con.execute(f"SELECT count(*) FROM {t}").fetchone()[0]
        print(f"  {t:<18} {n:>10,} filas")
        con.execute(f"COPY {t} TO '{(PROC / (t + '.csv')).as_posix()}' (HEADER, DELIMITER ',');")
        con.execute(f"COPY {t} TO '{(PROC / (t + '.parquet')).as_posix()}' (FORMAT PARQUET);")

    con.close()
    print(f"\nListo.\n  Base DuckDB:        {DB}\n  Export CSV/Parquet: {PROC}")


if __name__ == "__main__":
    main()
