#!/usr/bin/env bash
# Fast pipeline (~1 hour): recover HF cache + train location-invariant model.
# Does NOT delete data/_hf_plantvillage cache. Does NOT use --fresh on train/
# unless you pass --fresh explicitly.
set -euo pipefail
cd "$(dirname "$0")/.."

FRESH=""
SKIP_EXPAND="--skip-expand"
EPOCHS=15
LIMIT=80

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fresh) FRESH="--fresh"; shift ;;
    --expand) SKIP_EXPAND=""; shift ;;
    --epochs) EPOCHS="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

echo "==> Step 1/2: Prepare data (cache-first, limit=${LIMIT})"
.venv/bin/python scripts/prepare_data.py --fast --limit "${LIMIT}" ${FRESH} ${SKIP_EXPAND}

echo "==> Step 2/2: Train (epochs=${EPOCHS})"
.venv/bin/python -m app.ml.train_robust \
  --data_dir data \
  --epochs "${EPOCHS}" \
  --batch_size 32 \
  --init_weights model_weights/kulimaiq_mobilenet_baseline.pth

echo "==> Done. Evaluate with:"
echo "    .venv/bin/python -m scripts.eval_robustness --compare"
