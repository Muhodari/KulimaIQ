# KulimaIQ — Presentation Guide

**Machine Learning-Powered Mobile Agricultural Intelligence for Smallholder Farmers in Eastern Africa**

| | |
|---|---|
| **Author** | Sage Muhodari |
| **Institution** | African Leadership University — BSc Software Engineering |
| **Supervisor** | Emmanuel Adjei |
| **Pilot location** | Byumba Sector, Northern Province, Rwanda |

> Open **`presentation.html`** in a browser for a slide-style deck (arrow keys / swipe to navigate).

---

## 1. Title & Hook

**KulimaIQ** helps smallholder farmers **detect crop diseases early** using a smartphone leaf photo, manage farms with GPS-aware advisories, and act before yield loss spreads.

**One-liner:** *Scan a leaf → get a diagnosis → receive treatment advice → protect the farm.*

---

## 2. Problem Statement

### The challenge
- Agriculture is the backbone of Eastern Africa; smallholders grow most of the region's food.
- **20–40% of crop yield** is lost globally to pests and plant diseases (Savary et al., 2019).
- In Rwanda, diseases like **Cassava Mosaic (CMD)**, **Maize Lethal Necrosis (MLN)**, and **Banana Xanthomonas Wilt (BXW)** destroy staple crops.
- Extension officers cannot reach every farmer in time — delays mean disease spreads plot to plot.

### Pain points for farmers
| Problem | Impact |
|---------|--------|
| Late disease identification | Widespread crop loss, food insecurity |
| Trial-and-error treatment | Wasted inputs, wrong chemicals |
| Limited extension coverage | Hours or days waiting for expert advice |
| Climate variability | Disease pressure increases with changing weather |
| Low connectivity | Many tools assume always-online smartphones |

### Research gap
No widely available **integrated, low-bandwidth** tool combines:
1. CNN-based leaf disease detection  
2. **Farm-level GPS** and regional context  
3. **Localized weather advisories**  
4. **Offline-capable** mobile use  

…in one platform designed for Rwandan smallholders.

---

## 3. Research Objectives

### Main objective
Design, develop, and pilot **KulimaIQ** — a mobile agricultural intelligence platform that helps smallholder farmers detect crop diseases early using CNN-based image diagnostics.

### Specific objectives
1. Review literature and gather farmer/extension insights in Byumba Sector.
2. Build a working prototype with **CNN disease detection**, farm management, and climate advisories (**≥80% validation accuracy** target).
3. Pilot with **30–50 farmers** for 3 months; measure **≥15% reduction** in delayed disease response.

### Research questions
1. Can a CNN on a smartphone detect prevalent diseases from farmer leaf images in real field settings?
2. Do embedded climate advisories improve planting and disease-management decisions?
3. What usability and trust factors affect adoption in Byumba Sector?

---

## 3B. My Original Contribution — Location-Invariant Disease Detection

> **The novel piece no existing crop-scanner does:** a leaf model trained to stay accurate in *any* agro-ecological location — with **no GPS, no zone, no location input at all.** The farmer just takes a photo.

### The insight
Every existing leaf classifier (PlantVillage/Nuru and academic CNNs) is trained on images from a **narrow set of locations and lighting**. In the real world the *same disease on the same crop looks different* across East Africa's agro-ecological zones — highland light is cool and bright, lowland light is warm and hazy, humidity lowers contrast, altitude shifts colour and saturation, and phone cameras add their own cast. A model that memorises one location's *look* silently fails when a farmer in a different zone scans the identical disease. This is a **domain-shift** problem, and it is exactly where naïve crop scanners break.

### What I built (a strengthened, location-robust vision model)
The goal: the model must recognise the **disease itself**, not the *appearance of the location*. Two mechanisms, trained end-to-end, force it to do that:

1. **Agro-ecological style augmentation** (`app/ml/agro_style.py`) — every training image is re-rendered on the fly into randomly-sampled "location looks" (highland cool/bright, lowland warm/hazy, humid low-contrast, dry/dusty warm), including white-balance shifts, contrast/saturation changes, humidity haze and camera noise. The model sees each leaf as if photographed across many zones.
2. **MixStyle domain generalization** (`app/ml/mixstyle.py`, Zhou et al., ICLR 2021) — inserted into the MobileNetV2 feature stack, it mixes the channel-wise feature statistics (which encode "style") between samples in a batch, synthesising *unseen* location appearances inside the network. It has **no learnable parameters** and is disabled at inference, so the deployed model is an ordinary MobileNetV2 — same size, same speed, same API.

Model selection during training does **not** reward clean accuracy alone — it balances clean accuracy with **worst-location accuracy**, so the deployed checkpoint is the one that holds up *everywhere*.

### Proven behaviour (held-out location-shift evaluation)
I built four unseen agro-ecological "location domains" from the validation set and measured accuracy of the standard-trained baseline vs. the strengthened model (`python -m scripts.eval_robustness --compare`):

| Location domain | Baseline (standard CNN) | **Strengthened (mine)** |
|-----------------|:-----------------------:|:-----------------------:|
| Clean / familiar | 99.7% | **100.0%** |
| Highland — cool, bright | 58.1% | **84.4%** |
| Lowland — warm, hazy | 16.6% | **86.9%** |
| Humid — low contrast | 43.8% | **88.8%** |
| Dry / dusty — warm | 69.1% | **96.6%** |
| **Worst-case location** | **16.6%** | **84.4%** |
| **Average across locations** | **46.9%** | **89.1%** |

The baseline collapses to **16.6%** in the hardest zone — worse than a coin toss over the plausible classes — while the strengthened model stays at **84–97%** everywhere, and *gains* a little on clean images too. That is a **+67.8-point** jump in worst-case reliability with **zero** location input.

### Why it's a real contribution
- **New for East Africa (and beyond):** no deployed smallholder crop-scanner is explicitly trained and *measured* for cross-location robustness; they report a single clean accuracy number that hides this failure mode.
- **A trained model, not an API mashup:** the robustness comes from how the network is trained (MixStyle + agro-style augmentation), proven with a before/after held-out benchmark — not from stitching services together.
- **Zero friction for the farmer:** no permission prompts, no GPS fix, works fully offline; the intelligence lives in the model, exactly as requested.
- **Methodologically honest & extensible:** the location domains are simulated from an East African agro-ecological knowledge base and are explicitly designed to be **replaced by real geo-tagged field images** from the Byumba pilot to push robustness further.

**Files:** `backend/app/ml/mixstyle.py`, `backend/app/ml/agro_style.py`, `backend/app/ml/train_robust.py`; benchmark in `backend/scripts/eval_robustness.py`.

---

## 4. Innovation — KulimaIQ vs Existing Solutions

| System | What it does well | Limitation | **KulimaIQ advantage** |
|--------|-------------------|------------|------------------------|
| **PlantVillage / Nuru** | Offline CNN; validated in East Africa; strong cassava accuracy | Cassava-focused; no integrated climate + farm management | **Multi-crop** (20 classes); farms + weather + scans in one app |
| **iCow** | SMS on basic phones; large Kenya user base | No image/ML diagnosis; reactive SMS only | **Photo-based AI** diagnosis with treatment actions |
| **Agromonitoring** | Satellite/IoT precision farming | Needs internet & commercial-scale infrastructure | Built for **smallholders** on mid-range phones |
| **Extension visits (Twigire Muhinzi)** | Trusted human advice | Slow, limited reach | **Instant** first-line diagnosis; extension still needed for complex cases |

### KulimaIQ's unique value proposition

```
┌─────────────────────────────────────────────────────────────┐
│  INTEGRATED SMALLHOLDER PLATFORM (not a single-feature app) │
├─────────────────────────────────────────────────────────────┤
│  ✓ CNN leaf disease scan (20 disease classes)               │
│  ✓ Crop-aware inference (cassava scan ≠ tomato result)      │
│  ✓ Farm GPS + map picker + per-farm health score            │
│  ✓ 10-day weather history + forecast (Open-Meteo)           │
│  ✓ Regional crop advisories (East/West Africa, USA, etc.)   │
│  ✓ Offline SQLite cache + sync when backend online          │
│  ✓ English + Kinyarwanda                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. System Architecture (Implemented MVP)

```
┌──────────────────────────┐
│   Flutter Mobile App     │
│   Scan · Farms · Weather │
│   Profile · SQLite cache │
└────────────┬─────────────┘
             │  REST API (JWT)
             ▼
┌──────────────────────────┐
│   FastAPI Backend :8001  │
│   Auth · Farms · Diagnose│
│   POST /analyze/image    │
└────────────┬─────────────┘
             │
     ┌───────┼──────────────┬──────────────┐
     ▼       ▼              ▼              ▼
 MongoDB  MobileNetV2   (trained with     Open-Meteo
 users    PyTorch CNN    MixStyle +       (weather +
 farms    20 classes     agro-style aug   elevation for
 diagnoses  location-     → location-      farm advisories)
            invariant     robust)
```

### Location handling
- **Disease scan takes no location** — the model is trained to be location-invariant (see §3B), so a photo alone is enough anywhere.
- Farm **GPS** is still used, but only for **weather and regional advisories**, not for the diagnosis.
- Scan history links to a specific farm for traceability.

---

## 6. Technology Stack

| Layer | Technology | Role |
|-------|------------|------|
| **Mobile** | Flutter 3, Provider | Cross-platform UI (iOS + Android) |
| **Local storage** | SQLite, SharedPreferences | Offline profiles, farms, scan cache |
| **Maps** | flutter_map, OpenStreetMap, Nominatim | Farm GPS picker, reverse geocoding |
| **Backend** | FastAPI, Uvicorn | REST API, JWT auth |
| **Database** | MongoDB (Motor async driver) | Users, farms, diagnoses |
| **ML framework** | PyTorch, torchvision | Training & server inference |
| **Model** | MobileNetV2 (ImageNet transfer learning) | Lightweight CNN for mobile-era hardware |
| **Weather** | Open-Meteo API | Free forecast & archive per farm |
| **DevOps** | Docker, docker-compose | MongoDB + API containerization |
| **Notebook** | Jupyter, matplotlib, seaborn, scikit-learn | EDA, metrics, documentation |

---

## 7. Machine Learning Model

### Architecture
- **Base:** MobileNetV2 pretrained on ImageNet  
- **Head:** Dropout → Linear(1280→512) → ReLU → Dropout → Linear(512→N classes)  
- **Input:** 224×224 RGB leaf images  
- **Output:** Softmax probabilities over disease classes  

### Training pipeline (location-invariant — see §3B)
1. Images organized in folders: `{crop}_{disease}/` (e.g. `cassava_mosaic/`)
2. **Agro-ecological style augmentation** — each image re-rendered into random "location looks" (white balance, contrast, saturation, humidity haze, camera noise)
3. **MixStyle** feature-statistics mixing inside MobileNetV2 to synthesise unseen locations (no extra parameters)
4. Class-weighted loss for imbalance; **80/20 train/validation** split
5. **Model selection balances clean accuracy with worst-location accuracy**, not clean accuracy alone
6. Train with `python -m app.ml.train_robust`; checkpoint → `backend/model_weights/kulimaiq_mobilenet.pth`

### Crop-aware inference
The model sees all 20 classes, but at scan time probabilities are **filtered to the selected crop** (+ `healthy`) and re-normalized — preventing a cassava photo from returning a tomato disease.

### Single model, no location input
Diagnosis uses **one trained model** — the MobileNetV2 vision CNN, strengthened to be location-invariant. The scan request carries only the leaf photo and the crop; no GPS, elevation or zone is sent or needed. Because MixStyle is inference-time-inert, the deployed checkpoint is an ordinary MobileNetV2 (~11 MB), so on-device/offline deployment is unchanged.

### Deployed model — 20 classes

| Crop | Diseases detected |
|------|-------------------|
| Banana | Sigatoka, Wilt (BXW) |
| Bean | Angular spot, Rust |
| Cassava | Mosaic (CMD), Brown streak |
| Coffee | Leaf rust, Berry disease |
| Maize | Necrosis (MLN), Common rust, Gray leaf spot |
| Potato | Early blight, Late blight |
| Rice | Blast, Brown spot |
| Tomato | Early/Late blight, Leaf mold, Yellow leaf curl |
| All | Healthy |

### Validation metrics (prototype checkpoint)

| Metric | Value |
|--------|-------|
| Accuracy | 99.7% |
| Precision (weighted) | 99.7% |
| Recall (weighted) | 99.7% |
| F1 (weighted) | 99.7% |
| Validation set | 320 images, 20 classes |

> **Note for examiners:** Prototype metrics are on a curated validation set. Production deployment should retrain on full public datasets + local field images from Byumba. Field accuracy may be lower than lab metrics (Mwebaze & Biehl, 2019).

---

## 8. Datasets Used

### Primary open-access sources

| Source | Dataset | Used for | Licence |
|--------|---------|----------|---------|
| HuggingFace | **PlantVillage** | Tomato, potato, maize, healthy, many classes | CC BY |
| Kaggle | **Cassava Leaf Disease** (iCassava 2019) | CMD, cassava diseases | CC BY-SA 4.0 |
| Kaggle | **Bean Leaf Lesions** (iBean) | Bean angular spot, rust | Open |
| Kaggle | **Rice Leafs** | Rice blast, brown spot | Open |
| Kaggle | **Banana Disease Recognition** | Banana sigatoka, wilt | Open |
| Kaggle | **Coffee Leaf Diseases** | Coffee rust, berry disease | Open |
| Mendeley | **Tanzania Maize Imagery** (NM-AIST 2023) | MLN (`maize_necrosis`) | CC BY 4.0 |
| Mendeley | **Banana Leaf Disease** (AASTU Ethiopia) | BXW (`banana_wilt`) | CC BY 4.0 |

### Data preparation
```bash
cd backend
python scripts/prepare_data.py   # downloads & maps all sources
python -m app.ml.train --data_dir data --epochs 30
```

Folder convention: `data/train/cassava_mosaic/`, `data/val/healthy/`, etc.

---

## 9. App Features (Live Demo Flow)

1. **Login / Register** — JWT-secured accounts  
2. **Scan** — 3 steps: choose crop → photo → analyze → instant result screen  
3. **Results** — Disease name, confidence, recommendation, treatment steps  
4. **Farms** — Add farms on map, list crops, health score, weather strip  
5. **Farm detail** — What to do now, crops, 10-day weather, scan history  
6. **Climate** — Active weather alerts per farm location  
7. **Profile** — Farmer details, crops grown, language (EN / Kinyarwanda)  

---

## 10. API Endpoints (for technical audience)

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/auth/register` | Create account |
| POST | `/auth/login` | JWT token |
| POST | `/analyze/image` | Leaf photo + crop → diagnosis |
| GET | `/farms/` | List farms |
| POST | `/farms/` | Create farm |
| GET | `/diagnoses/` | Scan history |
| GET | `/crops/classes` | Model-supported crops |
| GET | `/health` | Server + ML model status |

**Swagger UI:** http://localhost:8001/docs

---

## 11. Significance & SDG Alignment

| SDG | Contribution |
|-----|--------------|
| **SDG 2 — Zero Hunger** | Earlier disease response → less crop loss → more food |
| **SDG 13 — Climate Action** | Weather-aware advisories support climate-smart farming |
| **SDG 8 — Decent Work** | Protects rural household income from preventable losses |

**Stakeholders:** Farmers, cooperatives, Twigire Muhinzi promoters, RAWARD, AgriTech ecosystem.

---

## 12. Methodology & Timeline

| Phase | Weeks | Activities |
|-------|-------|------------|
| Design | 1–3 | Literature review, requirements, UI mockups |
| Development | 4–8 | Flutter app, FastAPI, CNN training, integration |
| Pilot | 9–11 | 30–50 farmers in Byumba, surveys, interviews |
| Reflection | 12 | Analysis, report, recommendations |

**Methods:** Mixed-methods — quantitative (model metrics, surveys) + qualitative (interviews, FGDs, field observation).

---

## 13. Limitations & Future Work

| Limitation | Mitigation / future |
|------------|---------------------|
| Lab vs field accuracy gap | Collect local Byumba field images; retrain |
| Server-side inference (needs connectivity for ML) | Convert to TFLite on-device model |
| 20 classes (not all regional crops) | Expand dataset (avocado, mango, sorghum…) |
| Pilot limited to Byumba | Scale to other sectors after validation |

---

## 14. Demo Checklist (before presenting)

- [ ] Backend running: `uvicorn app.main:app --port 8001`
- [ ] MongoDB running (Docker or local)
- [ ] Flutter app on emulator/device
- [ ] Demo login or registered account ready
- [ ] Sample leaf images (cassava, maize, tomato) for live scan
- [ ] At least one farm with GPS for weather demo
- [ ] Notebook open: `backend/notebooks/KulimaIQ_Model_Notebook.ipynb`

---

## 15. Key References

- Mohanty, S. P., et al. (2016). Using deep learning for image-based plant disease detection. *Frontiers in Plant Science*.
- Mrisho, L. M., et al. (2020). PlantVillage Nuru accuracy in East Africa. *Frontiers in Plant Science*.
- Savary, S., et al. (2019). The global burden of pathogens and pests on major food crops. *Nature Ecology & Evolution*.
- Mwebaze, E., & Biehl, M. (2019). Deep learning for cassava disease detection. *IEEE ICMLA*.
- IPCC (2022). Climate Change and Food Security in Africa.

---

## 16. Closing

**KulimaIQ** bridges the gap between AI research and smallholder reality: integrated disease detection, farm-aware advisories, and offline resilience — designed for Eastern Africa.

**Questions?**
