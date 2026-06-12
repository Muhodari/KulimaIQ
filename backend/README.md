# KulimaIQ Backend

FastAPI + MongoDB + PyTorch backend for the KulimaIQ crop-disease detection app.

## Architecture

```
Flutter app  ──►  FastAPI (Python)  ──►  MongoDB
                      │
                      ▼
                  MobileNetV2
                  (PyTorch CNN)
                  trained on leaf
                  disease images
```

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/auth/register` | Create account |
| `POST` | `/auth/login` | Login → JWT token |
| `GET`  | `/farms/` | List user's farms |
| `POST` | `/farms/` | Create farm |
| `PUT`  | `/farms/{id}` | Update farm |
| `DELETE` | `/farms/{id}` | Delete farm |
| `GET`  | `/farms/{id}/health` | Farm health score |
| `GET`  | `/diagnoses/` | Diagnosis history |
| `POST` | `/analyze/image` | **Analyze leaf image (multipart)** |
| `POST` | `/analyze/base64` | Analyze leaf image (base64 JSON) |
| `GET`  | `/health` | Server + ML model status |

Interactive docs: `http://localhost:8001/docs`

---

## Model Notebook

Jupyter notebook for documentation, EDA, architecture, metrics, and deployment:

```bash
cd backend
source .venv/bin/activate
pip install matplotlib seaborn scikit-learn jupyter
jupyter notebook notebooks/KulimaIQ_Model_Notebook.ipynb
```

The notebook covers:
- Data visualizations (class distribution, sample images, crop×disease matrix)
- MobileNetV2 architecture and training configuration
- Validation metrics (accuracy, precision, recall, F1, confusion matrix)
- **Location-aware disease detection** (farm GPS + weather + regional symptom context)
- MVP deployment (Flutter app, FastAPI Swagger UI, Postman)

---

## Quick Start (Docker)

```bash
cd backend

# 1. Copy and edit env file
cp .env.example .env
# Edit .env – at minimum change SECRET_KEY

# 2. Start MongoDB + API
docker compose up -d

# 3. Open interactive API docs
open http://localhost:8001/docs
```

---

## Training the ML model

### Dataset sources (all open-access)

| Source | Dataset | Used for | Images | Licence |
|--------|---------|----------|--------|---------|
| [HuggingFace](https://huggingface.co/datasets/mohanty/PlantVillage) | PlantVillage | `healthy` | ~12 000 | CC BY |
| [Kaggle](https://kaggle.com/c/cassava-leaf-disease-classification) | Cassava Leaf Disease (NaCRRI / Makerere Univ.) | `cassava_mosaic` + `healthy` | ~21 367 | CC BY-SA 4.0 |
| [Mendeley `fkw49mz3xs`](https://data.mendeley.com/datasets/fkw49mz3xs/1) | Tanzania Maize Imagery (NM-AIST, 2023) | `maize_necrosis` (MLN) | ~9 356 | CC BY 4.0 |
| [Mendeley `rjykr62kdh`](https://data.mendeley.com/datasets/rjykr62kdh/1) | Banana Leaf Disease (AASTU, Ethiopia) | `banana_wilt` (BXW) | ~1 288 | CC BY 4.0 |

### 1. Install data-prep dependencies

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
pip install -r scripts/requirements_data.txt
```

### 2. Set up Kaggle API credentials

```bash
# a) Go to kaggle.com → Account → Create New API Token → download kaggle.json
mkdir -p ~/.kaggle
mv ~/Downloads/kaggle.json ~/.kaggle/
chmod 600 ~/.kaggle/kaggle.json

# b) Accept competition rules (one-time, in browser):
#    https://kaggle.com/c/cassava-leaf-disease-classification  → click "Late Submission"
```

### 3. Download Mendeley datasets manually

The two Mendeley datasets require a free account download:

| File to save | URL |
|---|---|
| `backend/raw/maize_tanzania.zip` | https://data.mendeley.com/datasets/fkw49mz3xs/1 → **Download All** |
| `backend/raw/banana_bxw.zip` | https://data.mendeley.com/datasets/rjykr62kdh/1 → **Download All** |

### 4. Run the automated preparation script

```bash
cd backend
python scripts/prepare_data.py
```

This will:
- Download PlantVillage automatically from HuggingFace (no login)
- Download the Kaggle cassava dataset via the Kaggle CLI
- Process the two Mendeley ZIPs you placed in `raw/`
- Organise everything into `data/train/` and `data/val/` with 80/20 split
- Print per-class counts and warn if any class is under-represented

Expected output after all sources are processed:

```
  train/healthy:         ~10 000
  train/cassava_mosaic:  ~4 500
  train/maize_necrosis:  ~2 500
  train/banana_wilt:     ~340
  val/  (same classes, ~20 % of above)
```

### 5. Train

```bash
# Full fine-tuning (recommended)
python -m app.ml.train --data_dir data --epochs 30 --batch_size 32

# GPU (CUDA / Apple MPS)
python -m app.ml.train --data_dir data --device cuda --epochs 40

# Quick head-only run (good baseline, fast)
python -m app.ml.train --data_dir data --epochs 15 --freeze_backbone --batch_size 64
```

Best checkpoint → `model_weights/kulimaiq_mobilenet.pth`
Training log   → `model_weights/training_history.json`

### 6. Reload the API

```bash
docker compose restart api
# or (local dev):
uvicorn app.main:app --reload
```

### 7. Verify

```bash
curl http://localhost:8001/health
# → {"status":"ok","ml_model_ready":true}
```

---

## Development (without Docker)

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Start MongoDB locally or use MongoDB Atlas URI in .env
uvicorn app.main:app --reload --port 8000
```

---

## Connecting the Flutter app

1. Open the app → **Profile** tab → **Backend server** card
2. Enter your server URL:
   - **Android emulator** → `http://10.0.2.2:8001`
   - **iOS simulator** → `http://localhost:8001`
   - **Physical device** → `http://<your-machine-local-IP>:8001`
3. Tap **Test connection** — the dot should turn green when the ML model is ready

When connected:
- Leaf scans are sent to the real MobileNetV2 model instead of the on-device heuristic
- Diagnoses are stored in MongoDB and linked to farms
- The app still works offline (falls back to local heuristics) if the server is unreachable
