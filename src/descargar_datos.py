"""Descarga los datos abiertos de producción NO CONVENCIONAL (Capítulo IV)
de la Secretaría de Energía de la Nación (datos.energia.gob.ar).

Fuentes (datos públicos, licencia abierta):
  - Producción de pozos de gas y petróleo NO CONVENCIONAL (histórico completo).
  - Padrón de pozos de Capítulo IV con fecha de primera producción.

Uso:
    python src/descargar_datos.py
"""
from __future__ import annotations

import sys
import time
import urllib.request
from pathlib import Path

RAW = Path(__file__).resolve().parents[1] / "data" / "raw"

# Recursos del dataset "Producción de petróleo y gas por pozo (Capítulo IV)".
FUENTES: dict[str, str] = {
    "produccion_no_convencional.csv": (
        "http://datos.energia.gob.ar/dataset/c846e79c-026c-4040-897f-1ad3543b407c/"
        "resource/b5b58cdc-9e07-41f9-b392-fb9ec68b0725/download/"
        "produccin-de-pozos-de-gas-y-petrleo-no-convencional.csv"
    ),
    "padron_pozos.csv": (
        "http://datos.energia.gob.ar/dataset/c846e79c-026c-4040-897f-1ad3543b407c/"
        "resource/5578dd48-d0dd-487e-8ddc-bd3ebb1afef0/download/"
        "padrn-de-pozos-de-captulo-iv-con-fecha-de-primera-produccin.csv"
    ),
}


def _progreso(bloque: int, tam_bloque: int, tam_total: int) -> None:
    if tam_total > 0:
        pct = min(100, bloque * tam_bloque * 100 // tam_total)
        print(f"\r    {pct:3d}%", end="", flush=True)


def descargar() -> None:
    RAW.mkdir(parents=True, exist_ok=True)
    for nombre, url in FUENTES.items():
        destino = RAW / nombre
        print(f"Descargando {nombre} ...")
        t0 = time.time()
        urllib.request.urlretrieve(url, destino, _progreso)
        mb = destino.stat().st_size / 1_048_576
        print(f"\r    OK  {mb:,.1f} MB en {time.time() - t0:,.0f} s  ->  {destino}")


if __name__ == "__main__":
    try:
        descargar()
    except Exception as e:  # noqa: BLE001
        print(f"\nERROR al descargar: {e}", file=sys.stderr)
        sys.exit(1)
