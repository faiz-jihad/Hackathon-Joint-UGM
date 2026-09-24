"""
Legacy endpoints re-export module for backward compatibility.
All primary endpoints are now modularized under app.api.routes.
"""
from app.api.routes import api_router as router
