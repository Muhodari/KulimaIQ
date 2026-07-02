#!/usr/bin/env bash
# Launch the model notebook with the correct backend virtualenv.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source .venv/bin/activate
python -m ipykernel install --prefix "$ROOT/.venv" --name=kulimaiq --display-name="KulimaIQ (backend .venv)" >/dev/null 2>&1 || true
exec jupyter notebook notebooks/KulimaIQ_Model_Notebook.ipynb
