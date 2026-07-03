#!/usr/bin/env bash
# Moderate real dataset: ~60/source, ~100/class cap, no synthetic placeholders.
# Requires HF_TOKEN + KAGGLE_USERNAME/KAGGLE_KEY in backend/.env
set -euo pipefail
cd "$(dirname "$0")/.."

CLASS_CAP="${CLASS_CAP:-100}"
LIMIT="${LIMIT:-50}"
EPOCHS="${EPOCHS:-25}"

echo "==> Prepare moderate real dataset (cap=${CLASS_CAP}, limit=${LIMIT}/source)"
.venv/bin/python scripts/prepare_data.py \
  --moderate \
  --skip-expand \
  --class-cap "${CLASS_CAP}" \
  --limit "${LIMIT}"

echo "==> Train location-invariant model (epochs=${EPOCHS})"
.venv/bin/python -m app.ml.train_robust \
  --data_dir data \
  --epochs "${EPOCHS}" \
  --batch_size 32

echo "==> Done."
