# KulimaIQ

> **Machine-learning crop disease detection for smallholder farmers in Eastern Africa**  
> Flutter mobile app · FastAPI backend · MobileNetV2 (PyTorch) · MongoDB Atlas

---

## Overview

**KulimaIQ** helps farmers scan crop leaves with a phone camera, detect diseases, and receive treatment guidance. The system combines:

| Component | Role |
|-----------|------|
| **Mobile app** (`kulimaiq_app/`) | Scan, farms, history, profile — English & Kinyarwanda |
| **Backend API** (`backend/`) | Auth, ML inference, farms, diagnoses |
| **ML model** | Location-invariant MobileNetV2 trained on real leaf images |
| **Database** | MongoDB Atlas — users, farms, scan history |

**Live API:** [https://kulimaiq.onrender.com](https://kulimaiq.onrender.com)  
**Health check:** [https://kulimaiq.onrender.com/health](https://kulimaiq.onrender.com/health)  
**Demo video:** [Watch on YouTube](https://youtu.be/aws6PzC_dQk)

**Capstone project** — African Leadership University, BSc Software Engineering  
**Author:** Sage Muhodari · **Supervisor:** Emmanuel Adjei

---

## Table of contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Quick start — use the app today](#quick-start--use-the-app-today)
5. [Download Android APK](#download-android-apk)
6. [Install & run — step by step](#install--run--step-by-step)
7. [Demo account](#demo-account)
8. [Using the app](#using-the-app)
9. [Build release APK (Android)](#build-release-apk-android)
10. [Backend (local development)](#backend-local-development)
11. [Deploy backend to Render](#deploy-backend-to-render)
12. [Train the ML model](#train-the-ml-model)
13. [Repository structure](#repository-structure)
14. [Tech stack](#tech-stack)
15. [API reference](#api-reference)
16. [Troubleshooting](#troubleshooting)
17. [Further reading](#further-reading)

---

## Features

### Mobile app

- **Leaf scan** — Camera or gallery → disease name + treatment advice
- **Crop selection** — Pick crop before scan (tomato, potato, maize, bean, etc.)
- **Farm management** — Multiple farms, crops, health score from scan history
- **Scan history** — Past diagnoses stored locally and on the server
- **Offline fallback** — Local SQLite when the API is unreachable
- **Server warm-up** — On launch, calls `/health` to wake Render if idle
- **Languages** — English and Kinyarwanda

### Backend & ML

- **JWT authentication** — Register / login with phone number
- **Image analysis** — `POST /analyze/image` with crop + leaf photo
- **Location-invariant model** — MixStyle + agro-style augmentation for different field conditions
- **MongoDB Atlas** — Persistent users, farms, diagnoses

### Currently supported ML classes (11)

`healthy`, `bean_angular_spot`, `bean_rust`, `maize_common_rust`, `maize_gray_leaf_spot`, `potato_early_blight`, `potato_late_blight`, `tomato_early_blight`, `tomato_late_blight`, `tomato_leaf_mold`, `tomato_yellow_leaf_curl_virus`

> Additional crops (cassava, rice, banana, coffee) are in the roadmap — training data is being expanded.

---

## Architecture

```
┌─────────────────────────┐
│   Flutter mobile app    │
│   Home · Scan · Farms   │
│   Profile               │
└───────────┬─────────────┘
            │  HTTPS (JWT)
            ▼
┌─────────────────────────┐       ┌─────────────────────┐
│  FastAPI  (Render)      │──────►│  MongoDB Atlas      │
│  kulimaiq.onrender.com  │       │  users · farms ·    │
│  /auth /analyze /farms  │       │  diagnoses          │
└───────────┬─────────────┘       └─────────────────────┘
            │
            ▼
   MobileNetV2 (PyTorch)
   model_weights/kulimaiq_mobilenet.pth
```

**Scan flow:** User selects crop → takes photo → app sends image to API → model returns disease label → result saved to MongoDB and shown in the app.

---

## Prerequisites

### To run the mobile app

| Tool | Version | Install |
|------|---------|---------|
| **Flutter** | 3.8+ | [flutter.dev/docs/get-started](https://docs.flutter.dev/get-started/install) |
| **Android Studio** or **Xcode** | Latest | For emulator / device |
| **Git** | Any recent | Clone this repo |

Check your setup:

```bash
flutter doctor
```

### To run the backend locally (optional)

| Tool | Version |
|------|---------|
| **Python** | 3.11+ |
| **MongoDB Atlas** account | Free tier OK |
| **Docker** | Optional (local MongoDB) |

---

## Quick start — use the app today

If you only want to **try KulimaIQ** without building from source:

1. **[Download the Android APK](#download-android-apk)** (easiest — no build required), **or** build from source (see below).
2. Open the app — it connects to **https://kulimaiq.onrender.com** automatically.
3. Wait on the splash screen if the server was sleeping (first request can take **up to 60 seconds**).
4. Log in with the [demo account](#demo-account) or register.
5. **Scan** tab → select **Tomato** (best tested crop) → take a leaf photo → **Analyze**.

---

## Download Android APK

Pre-built release for Android (no Flutter or Android Studio required):

**[Download KulimaIQ APK (Google Drive)](https://drive.google.com/file/d/1IL1H0MbSEHzEMC1JyYtnmQVA7mYf5NzX/view?usp=sharing)**

### Install on your phone

1. Open the link on your Android device (or download on a computer and transfer the file).
2. Tap **Download** in Google Drive, then open `app-release.apk`.
3. If prompted, allow **Install unknown apps** for your browser or file manager.
4. Open **KulimaIQ** → wait for **“Connecting to server…”** (first launch may take up to a minute).
5. Sign in with the [demo account](#demo-account) (`0780000000` / `farmer123`) or register.

> The app uses the live backend at [kulimaiq.onrender.com](https://kulimaiq.onrender.com). An internet connection is required for login and disease scans.

---

## Install & run — step by step

### Step 1 — Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/KulimaIQ.git
cd KulimaIQ
```

Replace `YOUR_USERNAME` with your GitHub username.

---

### Step 2 — Install Flutter dependencies

```bash
cd kulimaiq_app
flutter pub get
```

---

### Step 3 — Choose how to run

#### Option A — Android emulator (recommended for development)

1. Open **Android Studio** → **Device Manager** → start an emulator.
2. Run:

```bash
flutter devices          # confirm emulator is listed
flutter run
```

The app uses the **hosted API** at `https://kulimaiq.onrender.com` by default — no local backend required.

#### Option B — Physical Android phone

1. Enable **Developer options** → **USB debugging** on the phone.
2. Connect via USB (or use wireless debugging).
3. Run:

```bash
flutter devices
flutter run --release
```

#### Option C — iPhone Simulator (Mac only)

```bash
open -a Simulator
cd kulimaiq_app
flutter run
```

> **Physical iPhone:** Requires Apple Developer signing in Xcode. See [Troubleshooting](#troubleshooting).

---

### Step 4 — First launch

1. App opens → **“Connecting to server…”** (calls `/health` to wake Render).
2. **Sign in** or **Register**.
3. Complete **onboarding** (optional).
4. Go to **Profile** → confirm backend shows **✓ Connected — ML model ready**.

---

### Step 5 — Run your first scan

1. Open the **Scan** tab.
2. **Step 1:** Select crop (e.g. **Tomato**).
3. **Step 2:** Take or pick a leaf photo.
4. Tap **Analyze**.
5. Read the disease result and treatment suggestions.

> **Important:** Always select the **correct crop** before scanning. The model filters predictions by crop type.

---

## Demo account

| Field | Value |
|-------|-------|
| **Phone** | `0780000000` |
| **Password** | `farmer123` |

You can also tap **Register** to create a new account — data is stored in MongoDB Atlas.

---

## Using the app

| Tab | Purpose |
|-----|---------|
| **Home** | Recent scans and summary |
| **Scan** | Detect disease from a leaf photo |
| **Farms** | Add/edit farms, crops, health score |
| **Profile** | Language, backend status, account, logout |

### Backend URL (Profile)

Default production URL:

```text
https://kulimaiq.onrender.com
```

The app sets this automatically. Use **Test connection** in Profile to verify the server and ML model are ready.

### Best crops to test today

| Crop | Reliability |
|------|-------------|
| Tomato | ✅ Best — 4 diseases trained |
| Potato | ✅ Good |
| Maize | ✅ Good |
| Bean | ✅ Good (field photos) |
| Cassava, rice, banana, coffee | ⚠️ Not yet in current model |

---

## Build release APK (Android)

To build the APK yourself from source:

```bash
cd kulimaiq_app
flutter build apk --release
```

Output file:

```text
kulimaiq_app/build/app/outputs/flutter-apk/app-release.apk
```

**Pre-built download:** [Google Drive APK](https://drive.google.com/file/d/1IL1H0MbSEHzEMC1JyYtnmQVA7mYf5NzX/view?usp=sharing)

**Install on a phone:**

1. Copy `app-release.apk` to the device (USB, Drive, WhatsApp, etc.).
2. Open the file → allow install from unknown sources if prompted.
3. Open **KulimaIQ** → sign in → scan.

---

## Backend (local development)

Only needed if you want to change the API or ML model locally.

### Step 1 — Python environment

```bash
cd backend
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### Step 2 — Environment variables

```bash
cp .env.example .env
```

Edit `backend/.env`:

```env
MONGO_URL=mongodb+srv://<user>:<password>@cluster0.xxxxx.mongodb.net/kulimaiq?retryWrites=true&w=majority
MONGO_DB=kulimaiq
SECRET_KEY=your-long-random-secret
MODEL_WEIGHTS_PATH=model_weights/kulimaiq_mobilenet.pth
```

### Step 3 — Start the API

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

### Step 4 — Verify

| URL | Purpose |
|-----|---------|
| http://localhost:8001/health | Server + ML status |
| http://localhost:8001/docs | Swagger UI |

### Step 5 — Point the app at local backend (optional)

In the app **Profile** → Backend URL:

| Device | URL |
|--------|-----|
| Android emulator | `http://10.0.2.2:8001` |
| iOS simulator | `http://localhost:8001` |
| Physical phone (same Wi‑Fi) | `http://<your-computer-ip>:8001` |

Full backend docs: [`backend/README.md`](backend/README.md)

---

## Deploy backend to Render

Production is already hosted at **https://kulimaiq.onrender.com**.

To redeploy or set up your own instance:

1. Push code to GitHub (include `backend/model_weights/kulimaiq_mobilenet.pth`).
2. MongoDB Atlas → **Network Access** → allow `0.0.0.0/0`.
3. [render.com](https://render.com) → **New** → **Blueprint** → connect repo.
4. Set secrets: `MONGO_URL`, `SECRET_KEY`.
5. Deploy → test `https://<your-app>.onrender.com/health`.

Details: [`backend/README.md`](backend/README.md#deploy-to-render-free)

---

## Train the ML model

```bash
cd backend
source .venv/bin/activate

# Prepare real training data (moderate dataset)
python scripts/prepare_data.py --moderate --skip-expand --class-cap 120 --limit 60

# Train location-invariant model
python -m app.ml.train_robust --data_dir data --epochs 30 --batch_size 32
```

Weights saved to:

```text
backend/model_weights/kulimaiq_mobilenet.pth
```

**Model notebook** (EDA, metrics, architecture):  
[`backend/notebooks/KulimaIQ_Model_Notebook.ipynb`](backend/notebooks/KulimaIQ_Model_Notebook.ipynb)

---

## Repository structure

```text
KulimaIQ/
├── README.md                 ← You are here
├── document.md               ← Capstone research proposal
├── render.yaml               ← Render deployment blueprint
├── Dockerfile                ← Production container (API)
├── backend/
│   ├── app/                  ← FastAPI application
│   ├── model_weights/        ← Trained PyTorch weights
│   ├── scripts/              ← Data prep & evaluation
│   ├── notebooks/            ← Jupyter model notebook
│   └── README.md             ← Backend setup & training
└── kulimaiq_app/
    ├── lib/                  ← Flutter source (MVVM)
    ├── assets/               ← Icons & images
    └── README.md             ← App-specific notes
```

---

## Tech stack

| Layer | Technology |
|-------|------------|
| **Mobile** | Flutter, Provider, SQLite, SharedPreferences |
| **Backend** | FastAPI, Uvicorn, Motor (async MongoDB) |
| **Auth** | JWT (python-jose), bcrypt passwords |
| **ML** | PyTorch, MobileNetV2, MixStyle, torchvision |
| **Database** | MongoDB Atlas |
| **Hosting** | Render (free tier), Docker |
| **Notebook** | Jupyter, matplotlib, seaborn, scikit-learn |

---

## API reference

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Server, MongoDB, and ML model status |
| `POST` | `/auth/register` | Create account |
| `POST` | `/auth/login` | Login → JWT token |
| `GET` | `/farms/` | List farms |
| `POST` | `/farms/` | Create farm |
| `POST` | `/analyze/image` | Analyze leaf photo (multipart) |
| `GET` | `/diagnoses/` | Scan history |

**Interactive docs:** [https://kulimaiq.onrender.com/docs](https://kulimaiq.onrender.com/docs)

**Test with Swagger:**

1. `POST /auth/login` → copy `access_token`
2. Click **Authorize** → `Bearer <token>`
3. `POST /analyze/image` → upload image, set `crop=tomato`

---

## Troubleshooting

### App stuck on “Connecting to server…”

Render free tier **sleeps after ~15 minutes** of inactivity. Wait up to **60 seconds** on first open. Check [health endpoint](https://kulimaiq.onrender.com/health) in a browser.

### Scan always wrong crop / wrong disease

- Select the **correct crop** before scanning.
- Use **tomato, potato, maize, or bean** for best results today.
- Use a **clear, close-up leaf photo** in good light.

### Cannot log in

- Confirm internet connection.
- Profile → **Test connection** must show model ready.
- Try demo account: `0780000000` / `farmer123`.

### Local backend not reachable from phone

- Phone and laptop must be on the **same Wi‑Fi**.
- Use laptop IP, not `localhost`.
- Allow port **8001** through firewall.

### iPhone not showing in Xcode

1. Trust the Mac on iPhone when prompted.
2. Enable **Developer Mode** (Settings → Privacy & Security — appears after running from Xcode once).
3. Xcode → **Window → Devices and Simulators**.

### APK install blocked

Android → Settings → Security → allow install from unknown sources for your file manager.

---

## Demo video

Watch the full project walkthrough:

**[KulimaIQ Demo on YouTube](https://youtu.be/aws6PzC_dQk)**

---

## Further reading

| Document | Description |
|----------|-------------|
| [`backend/README.md`](backend/README.md) | API, MongoDB Atlas, training, Render deploy |
| [`kulimaiq_app/README.md`](kulimaiq_app/README.md) | Flutter app structure |
| [`document.md`](document.md) | Full capstone research proposal |
| [`backend/notebooks/KulimaIQ_Model_Notebook.ipynb`](backend/notebooks/KulimaIQ_Model_Notebook.ipynb) | ML pipeline & metrics |

---

## License & datasets

Training data uses open-access sources (PlantVillage, Kaggle iBean, etc.). See [`backend/README.md`](backend/README.md) for dataset licences and download instructions.

---

<p align="center">
  <strong>KulimaIQ</strong> — Smart farming for Eastern Africa 🌱
</p>
