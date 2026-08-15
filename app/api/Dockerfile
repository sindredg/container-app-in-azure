FROM python:3.13-slim

# Unbuffered stdout, or log lines reach Log Analytics late and in clumps
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Dependencies before source, so editing main.py does not reinstall FastAPI
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py ./

# The Nginx base image supplies a non-root user; this one has to declare its own
RUN useradd --create-home --uid 10001 appuser
USER appuser

EXPOSE 8080

# The slim image has no curl or wget, so the check goes through Python's stdlib
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health')" || exit 1

# --host 0.0.0.0 binds all interfaces; the default 127.0.0.1 is unreachable from outside
# --no-access-log suppresses Uvicorn's IP logging, leaving the middleware as sole logger
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080", "--no-access-log"]