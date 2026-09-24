from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.endpoints import router as api_router
from app.config import settings

app = FastAPI(
    title="RETIVA AI Inference Microservice",
    description="Provider-agnostic inference engine with Quality Gate, EfficientNet-B3 DR Classification, and Reliability Gate.",
    version="1.0.0"
)

# AI Service is private/internal, but allow localhost communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)

@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "retiva-ai-service",
        "active_model": settings.MODEL_NAME,
        "model_version": settings.MODEL_VERSION,
        "pipeline_version": settings.PIPELINE_VERSION
    }
