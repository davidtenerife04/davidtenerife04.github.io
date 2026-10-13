#!/usr/bin/env python3
"""
Escanea la carpeta guias/ y genera/actualiza guias.json para guias.html.

- Añade los PDFs nuevos (título sacado del nombre del archivo).
- Conserva el título y las etiquetas que ya hayas editado a mano.
- Elimina entradas cuyo PDF ya no exista.

Uso:  python generar_guias.py
Etiquetas: edita guias.json y rellena "tags": ["linux", "redes"]
"""
import json
import re
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).resolve().parent
CARPETA = BASE / "guias"
MANIFEST = BASE / "guias.json"


def titulo_desde_nombre(stem: str) -> str:
    t = re.sub(r"[_\-]+", " ", stem).strip()
    return t[:1].upper() + t[1:]


def main():
    CARPETA.mkdir(exist_ok=True)

    previas = {}
    if MANIFEST.exists():
        try:
            for g in json.loads(MANIFEST.read_text(encoding="utf-8")):
                previas[g["file"]] = g
        except (json.JSONDecodeError, KeyError):
            print("guias.json ilegible, se regenera desde cero.")

    resultado = []
    for pdf in sorted(CARPETA.rglob("*.pdf")):
        rel = pdf.relative_to(BASE).as_posix()
        st = pdf.stat()
        antigua = previas.get(rel, {})
        resultado.append({
            "file": rel,
            "title": antigua.get("title") or titulo_desde_nombre(pdf.stem),
            "tags": antigua.get("tags", []),
            "date": antigua.get("date") or datetime.fromtimestamp(st.st_mtime).strftime("%Y-%m-%d"),
            "size": st.st_size,
        })

    nuevas = [g for g in resultado if g["file"] not in previas]
    borradas = [f for f in previas if f not in {g["file"] for g in resultado}]

    MANIFEST.write_text(json.dumps(resultado, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{len(resultado)} guías en total | +{len(nuevas)} nuevas | -{len(borradas)} eliminadas")
    for g in nuevas:
        print(f"  + {g['file']}")


if __name__ == "__main__":
    main()
