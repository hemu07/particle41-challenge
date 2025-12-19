FROM python:3.11-slim AS builder
WORKDIR /build
COPY app.py .
RUN pip install --no-cache-dir --target=/build/python-deps flask

FROM gcr.io/distroless/python3-debian12
WORKDIR /app
COPY --from=builder /build/app.py /app/app.py
COPY --from=builder /build/python-deps /app/python-deps
ENV PYTHONPATH=/app/python-deps

EXPOSE 5000

CMD ["app.py"]
