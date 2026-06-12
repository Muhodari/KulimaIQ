from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import settings
from .database import close_db
from .ml.inference import init_inference_service
from .routers import analyze, auth, crops, diagnoses, farms


@asynccontextmanager
async def lifespan(app: FastAPI):
    # ── Startup ───────────────────────────────────────────────────────────────
    init_inference_service(settings.model_weights_path)
    yield
    # ── Shutdown ──────────────────────────────────────────────────────────────
    await close_db()


app = FastAPI(
    title="KulimaIQ API",
    description=(
        "Crop-disease detection API for smallholder farmers. "
        "Backed by MobileNetV2 (PyTorch) + MongoDB."
    ),
    version="1.0.0",
    lifespan=lifespan,
)

# ── CORS ──────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(farms.router)
app.include_router(diagnoses.router)
app.include_router(analyze.router)
app.include_router(crops.router)


# ── Health check ──────────────────────────────────────────────────────────────
@app.get("/health", tags=["system"])
async def health():
    from .ml.inference import get_inference_service
    svc = get_inference_service()
    return {
        "status": "ok",
        "ml_model_ready": svc.is_ready,
        "num_classes": len(svc.classes),
        "classes": svc.classes,
    }
