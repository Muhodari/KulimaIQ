# KulimaIQ

**Machine learning-powered mobile agricultural intelligence for crop disease detection among smallholder farmers in Eastern Africa.**

KulimaIQ combines a **Flutter mobile app**, a **FastAPI + MongoDB backend**, and a **MobileNetV2 (PyTorch) CNN** to scan leaf photos, detect diseases across 20+ crop classes, manage farms with GPS locations, and deliver **location-aware weather advisories**.

Capstone project — African Leadership University, BSc Software Engineering  
Author: **Sage Muhodari** · Supervisor: Emmanuel Adjei

---

## Demo video (YouTube)

Watch the project demo and walkthrough:

**[KulimaIQ Demo on YouTube](https://youtu.be/YOUR_VIDEO_ID)**

> Replace `YOUR_VIDEO_ID` in this README with your published demo link when ready.

---

## Repository structure

| Path | What it is |
|------|------------|
| [`README.md`](README.md) | This file — project overview |
| [`document.md`](document.md) | Capstone research proposal (full document) |
| [`backend/`](backend/) | FastAPI API, ML training, MongoDB, Docker |
| [`backend/notebooks/KulimaIQ_Model_Notebook.ipynb`](backend/notebooks/KulimaIQ_Model_Notebook.ipynb) | **Model notebook** (EDA, architecture, metrics, deployment) |
| [`backend/README.md`](backend/README.md) | Backend setup, training, API docs |
| [`kulimaiq_app/`](kulimaiq_app/) | Flutter mobile application |
| [`kulimaiq_app/README.md`](kulimaiq_app/README.md) | Flutter run instructions |

---

## Model notebook

The Jupyter notebook documents the full ML pipeline for reviewers and examiners:

**Location:** `backend/notebooks/KulimaIQ_Model_Notebook.ipynb`

**Contents:**
- Data visualization & data engineering (class distributions, sample images, crop×disease matrix)
- Model architecture (MobileNetV2 + custom classifier head)
- Performance metrics (accuracy, precision, recall, F1, confusion matrix)
- Location-aware disease detection (farm GPS + climate context)
- Deployment MVP (mobile app, Swagger UI, Postman)

### Run the notebook

```bash
cd backend
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
pip install matplotlib seaborn scikit-learn jupyter ipykernel

# Register this venv as a Jupyter kernel (fixes "No module named torchvision")
python -m ipykernel install --user --name kulimaiq-backend --display-name "KulimaIQ Backend (.venv)"

jupyter notebook notebooks/KulimaIQ_Model_Notebook.ipynb
```

In Jupyter / VS Code / Cursor: select kernel **"KulimaIQ Backend (.venv)"** before running cells.

Pre-computed evaluation metrics (optional reference): `backend/notebooks/eval_metrics.json`

---

## Quick start

### 1. Backend (API + ML + MongoDB)

```bash
cd backend
cp .env.example .env               # edit SECRET_KEY and MONGODB_URI if needed
docker compose up -d               # MongoDB + API

# Or local dev:
source .venv/bin/activate
uvicorn app.main:app --reload --port 8001
```

| Resource | URL |
|----------|-----|
| Swagger UI (API docs) | http://localhost:8001/docs |
| ReDoc | http://localhost:8001/redoc |
| Health check | http://localhost:8001/health |

See [`backend/README.md`](backend/README.md) for training the model and dataset preparation.

### 2. Mobile app (Flutter)

```bash
cd kulimaiq_app
flutter pub get
flutter run
```

**Backend URL (Profile → Backend server):**
- Android emulator → `http://10.0.2.2:8001`
- iOS simulator → `http://localhost:8001`
- Physical device → `http://<your-computer-ip>:8001`

### 3. Demo account

| Field | Value |
|-------|-------|
| Phone | `+250788000000` |
| Password | `farmer123` |

You can also register a new account from the app.

---

## System architecture

```
┌─────────────────────┐     ┌──────────────────────────┐
│  Flutter mobile app │────►│  FastAPI backend :8001    │
│  Scan · Farms ·     │     │  Auth · Farms · Diagnoses │
│  Weather · Profile  │     │  POST /analyze/image      │
└─────────────────────┘     └────────────┬─────────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    ▼                    ▼                    ▼
              MongoDB            MobileNetV2           Open-Meteo
           users · farms         PyTorch CNN           (farm weather)
           diagnoses            20 disease classes
```

**Location-aware detection:** Each farm stores GPS coordinates and region. Weather advisories and scan history are tied to farm location, because the same disease can present different leaf symptoms across climates and geographies.

---

## Key features

- **Disease scan** — Camera/gallery leaf photo → CNN inference → treatment recommendations
- **20+ disease classes** — Cassava, maize, banana, tomato, potato, rice, coffee, bean, and more
- **Farm management** — Multiple farms, map-based GPS picker, per-farm health score
- **Weather advisories** — 7-day Open-Meteo forecast per farm location
- **Offline support** — SQLite cache; syncs to MongoDB when backend is online
- **Languages** — English and Kinyarwanda

---

## API testing (Postman / Swagger)

1. Open http://localhost:8001/docs
2. `POST /auth/login` or `POST /auth/register` → copy `access_token`
3. Click **Authorize** → `Bearer <token>`
4. `POST /analyze/image` — upload a leaf image, set `crop` (e.g. `tomato`)
5. `GET /diagnoses/` — view saved scan history
6. `GET /farms/` — list farms

---

## Train the ML model

```bash
cd backend
source .venv/bin/activate
python scripts/bootstrap_data.py          # quick start data
python -m app.ml.train --data_dir data --epochs 30 --batch_size 32
```

Weights saved to `backend/model_weights/kulimaiq_mobilenet.pth`

Full dataset guide: [`backend/README.md`](backend/README.md#training-the-ml-model)

---

## Tech stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter, Provider, SQLite |
| Backend | FastAPI, Motor (MongoDB), JWT |
| ML | PyTorch, MobileNetV2, torchvision |
| Weather | Open-Meteo API |
| Maps | flutter_map, OpenStreetMap, Nominatim |
| Notebook | Jupyter, matplotlib, seaborn, scikit-learn |

---

## License & datasets

Training data sources include open-access datasets (PlantVillage, Kaggle Cassava, Mendeley). See [`backend/README.md`](backend/README.md) for licences and download instructions.
