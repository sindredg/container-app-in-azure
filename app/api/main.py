"""Internal API for the cloud operations lab.

Runs behind internal-only ingress. The public web container is its only
caller, so this service is never addressable from the internet.
"""

# --- imports ---
import hmac
import logging
import os
import time
from datetime import datetime, timezone

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, PlainTextResponse

# --- service identity: version comes from the image tag via Terraform ---
SERVICE_NAME = "api"
SERVICE_VERSION = os.getenv("SERVICE_VERSION", "0.0.0-local")

# --- shared secret: set on both apps by Terraform and sent by the web proxy.
# --- A browser cannot supply it, so only the proxy can reach these routes. ---
SHARED_SECRET = os.getenv("API_SHARED_SECRET", "")
SECRET_HEADER = "x-api-key"

# --- the platform calls /health directly on the container, not through the
# --- proxy, so requiring the secret there would fail every probe ---
UNAUTHENTICATED_PATHS = frozenset({"/health"})

# --- logging setup ---
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(SERVICE_NAME)

# --- app: interactive docs are off because their assets come from a CDN the CSP
# --- blocks. The schema follows the same rule: nothing consumes it in Azure, so
# --- it is opt-in and stays off unless a local run asks for it. ---
ENABLE_OPENAPI = os.getenv("ENABLE_OPENAPI", "false").lower() == "true"

app = FastAPI(
    title="Cloud Operations Lab API",
    version=SERVICE_VERSION,
    openapi_url="/openapi.json" if ENABLE_OPENAPI else None,
    docs_url=None,
    redoc_url=None,
)


# --- platform metadata: Container Apps injects these, "local" when run under Docker ---
def platform_metadata():
    return {
        "app": os.getenv("CONTAINER_APP_NAME", "local"),
        "revision": os.getenv("CONTAINER_APP_REVISION", "local"),
        "replica": os.getenv("CONTAINER_APP_REPLICA_NAME", "local"),
    }


# --- auth: registered before the logger on purpose. Starlette makes the last
# --- registered middleware the outermost one, so logging wraps this and a
# --- rejected request still gets a log line. ---
@app.middleware("http")
async def require_shared_secret(request: Request, call_next):
    if request.url.path in UNAUTHENTICATED_PATHS:
        return await call_next(request)

    presented = request.headers.get(SECRET_HEADER, "")

    # compare_digest takes the same time whichever character differs, so the
    # value cannot be recovered one character at a time by timing the reply.
    # An unset secret fails closed rather than allowing everything through.
    if not SHARED_SECRET or not hmac.compare_digest(presented, SHARED_SECRET):
        return JSONResponse({"detail": "Unauthorized"}, status_code=401)

    return await call_next(request)


# --- request logging: records what was asked for, never who asked ---
@app.middleware("http")
async def log_request(request: Request, call_next):
    started = time.perf_counter()
    response = await call_next(request)
    duration_ms = (time.perf_counter() - started) * 1000

    logger.info(
        '"%s %s" %d %.1fms',
        request.method,
        request.url.path,
        response.status_code,
        duration_ms,
    )
    return response


# --- route: probe target for Docker, ingress, and all three Container Apps probes ---
@app.get("/health", response_class=PlainTextResponse)
async def health():
    return "healthy\n"


# --- route: the JSON contract the web card renders ---
@app.get("/status")
async def status():
    return JSONResponse(
        {
            "service": SERVICE_NAME,
            "version": SERVICE_VERSION,
            "status": "ok",
            "time": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            **platform_metadata(),
        }
    )