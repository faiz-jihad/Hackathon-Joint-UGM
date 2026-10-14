from fastapi import APIRouter
from app.api.routes.health import router as health_router
from app.api.routes.quality import router as quality_router
from app.api.routes.reliability import router as reliability_router
from app.api.routes.explainability import router as explainability_router
from app.api.routes.screening import router as screening_router
from app.api.routes.daily_care import router as daily_care_router
from app.api.routes.sos import router as sos_router

api_router = APIRouter()

# Include all sub-routers
api_router.include_router(health_router)
api_router.include_router(quality_router)
api_router.include_router(reliability_router)
api_router.include_router(explainability_router)
api_router.include_router(screening_router)
api_router.include_router(daily_care_router)
api_router.include_router(sos_router)

