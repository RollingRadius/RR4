"""
Fleet Management System - FastAPI Main Application
Authentication & Company Management API
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
import os

from app.config import settings

# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Fleet Management System API - Authentication & Company Management",
    docs_url="/docs",  # Swagger UI
    redoc_url="/redoc",  # ReDoc documentation
    debug=settings.DEBUG
)

# Configure CORS
# In development, allow all localhost origins
# In production, this should be restricted to specific domains
if settings.ENVIRONMENT == "development":
    cors_origins = ["*"]  # Allow all origins in development
else:
    cors_origins = settings.allowed_origins_list

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)


@app.get("/", tags=["Health"])
def root():
    """Health check endpoint"""
    return {
        "message": "Fleet Management System API",
        "version": settings.APP_VERSION,
        "status": "running",
        "environment": settings.ENVIRONMENT
    }


@app.get("/health", tags=["Health"])
def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "app_name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT
    }


# Exception handlers
@app.exception_handler(404)
def not_found_handler(request, exc):
    return JSONResponse(
        status_code=404,
        content={"detail": "Resource not found"}
    )


@app.exception_handler(500)
def internal_error_handler(request, exc):
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )


# Application startup event
@app.on_event("startup")
async def startup_event():
    """Initialize application on startup"""
    print(f"Starting {settings.APP_NAME} v{settings.APP_VERSION}")
    print(f"Environment: {settings.ENVIRONMENT}")
    print(f"Debug mode: {settings.DEBUG}")

    # Auto-seed capabilities and predefined roles (idempotent - safe to run every startup)
    try:
        from app.database import SessionLocal
        from app.services.capability_service import CapabilityService
        from app.services.template_service import TemplateService

        db = SessionLocal()
        try:
            # Seed capabilities first (required before predefined roles due to FK)
            cap_service = CapabilityService(db)
            cap_count = cap_service.seed_capabilities()
            if cap_count > 0:
                print(f"Seeded {cap_count} capabilities")

            # Seed predefined role templates with their capability assignments
            tmpl_service = TemplateService(db)
            role_count = tmpl_service.seed_predefined_roles()
            if role_count > 0:
                print(f"Seeded {role_count} predefined roles")
        except Exception as seed_error:
            # Tables may not exist yet if migrations haven't been run
            print(f"Warning: Seeding skipped (run migrations first): {seed_error}")
            db.rollback()
        finally:
            db.close()
    except Exception as e:
        print(f"Warning: Could not initialize seeding: {e}")


# Application shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    print(f"Shutting down {settings.APP_NAME}")


# Import and include API routers
from app.api.v1 import (
    auth, company, driver, user, organization, reports, capabilities,
    custom_roles, templates, vehicles, profile, roles, organization_management,
    tracking, expenses, invoices, payments, budgets, branding
)

app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(profile.router, prefix="/api/profile", tags=["Profile"])
app.include_router(roles.router, prefix="/api/roles", tags=["Roles"])
app.include_router(company.router, prefix="/api/companies", tags=["Companies"])
app.include_router(driver.router, prefix="/api/drivers", tags=["Drivers"])
app.include_router(vehicles.router, prefix="/api/vehicles", tags=["Vehicles"])
app.include_router(user.router, prefix="/api/user", tags=["User Profile"])
app.include_router(organization.router, prefix="/api/organizations", tags=["Organization Management"])
app.include_router(organization_management.router, prefix="/api/organization", tags=["Organization Dashboard"])
app.include_router(reports.router, prefix="/api/reports", tags=["Reports"])
app.include_router(capabilities.router, prefix="/api/capabilities", tags=["Capabilities"])
app.include_router(custom_roles.router, prefix="/api/custom-roles", tags=["Custom Roles"])
app.include_router(templates.router, prefix="/api/templates", tags=["Templates"])
app.include_router(tracking.router, prefix="/api/v1", tags=["GPS Tracking"])
app.include_router(branding.router, prefix="/api/v1/branding", tags=["Branding"])

# Financial Management API routers
app.include_router(expenses.router, prefix="/api/expenses", tags=["Expenses"])
app.include_router(invoices.router, prefix="/api/invoices", tags=["Invoices"])
app.include_router(payments.router, prefix="/api/payments", tags=["Payments"])
app.include_router(budgets.router, prefix="/api/budgets", tags=["Budgets"])

# Mount static files for logo uploads
uploads_path = os.path.join(os.getcwd(), settings.UPLOAD_DIR)
os.makedirs(uploads_path, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_path), name="uploads")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
