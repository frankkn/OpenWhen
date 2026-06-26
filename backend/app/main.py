from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import auth, capsules, ai

app = FastAPI(
    title="OpenWhen API",
    description="時光膠囊信件 Backend",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(capsules.router)
app.include_router(ai.router)


@app.get("/health")
def health():
    return {"status": "ok"}
