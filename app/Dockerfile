FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app

COPY app.py .

RUN useradd --create-home --uid 10001 appuser
USER 10001:10001

EXPOSE 8080

CMD ["python", "app.py"]
