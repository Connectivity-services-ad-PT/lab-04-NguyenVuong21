# syntax=docker/dockerfile:1.7

# Stage 1: Build dependencies trong môi trường cô lập
FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /build

RUN python -m venv /opt/venv

COPY requirements.txt .

# Nâng cấp pip và cài đặt thư viện vào Virtual Environment
RUN /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt


# Stage 2: Runtime image tối ưu và bảo mật cao
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/opt/venv/bin:$PATH"

# Cấu hình mặc định cho runtime (Có thể override khi docker run)
ENV APP_HOST=0.0.0.0
ENV APP_PORT=8000

WORKDIR /app

# Tạo hệ thống user non-root bảo mật (Appuser) theo chuẩn Rubric 2.0đ
RUN addgroup --system appgroup \
    && adduser --system --ingroup appgroup --home /app appuser

# Sao chép virtual env độc lập từ stage builder sang
COPY --from=builder /opt/venv /opt/venv
COPY src/ ./src/

# Cấp quyền sở hữu thư mục làm việc cho appuser
RUN chown -R appuser:appgroup /app

# Chuyển quyền thực thi sang user non-root
USER appuser

EXPOSE 8000

# HEALTHCHECK gọi nội bộ sử dụng urllib chuẩn mã trạng thái thành công
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; res = urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3); exit(0) if res.getcode() == 200 else exit(1)" || exit 1

# Khởi chạy dịch vụ FastAPI thông qua Uvicorn sử dụng biến môi trường hệ thống
CMD ["sh", "-c", "uvicorn iot_app.main:app --app-dir src --host ${APP_HOST} --port ${APP_PORT}"]