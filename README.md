# FIT4110_lab04_docker_packaging

**Học phần:** FIT4110 – Dịch vụ kết nối và Công nghệ nền tảng  
**Buổi 4:** Đóng gói service với Docker & tư duy công nghệ nền tảng  
**Case study:** Smart Campus Operations Platform  
**Repo nền:** `FIT4110_lab03_postman_mock_testing`

> Lab 03 đã có OpenAPI contract, Postman Collection, Mock Server và Newman report.  
> Lab 04 dùng lại logic đó để kiểm tra một điều mới: **service có chạy ổn khi được đóng gói thành Docker container không?**

---

## 1. Ý tưởng nối tiếp từ Lab 03 sang Lab 04

Ở Lab 03, luồng làm việc là:

```text
OpenAPI Contract → Mock Server → Postman Test → Newman Report → CI Evidence
```

Ở Lab 04, luồng đó được mở rộng thành:

```text
OpenAPI Contract
→ Service thật
→ Dockerfile
→ Docker Image
→ Docker Container
→ Postman/Newman chạy lại trên container
→ Evidence
```

Lab 04 hiện đã đồng bộ lại với contract IoT của Lab 03 theo payload:

```json
{
  "device_id": "ESP32-LAB-A01",
  "metric": "temperature",
  "value": 31.5,
  "unit": "celsius",
  "timestamp": "2026-05-13T08:30:00+07:00"
}
```

Boundary dùng trong bài:

```text
temperature: -40 đến 80
```

Thông điệp chính của buổi học:

> Một API pass Postman trên máy cá nhân chưa đủ.  
> Service cần được đóng gói thành container để người khác có thể chạy lại nhất quán.

---

## 2. Mục tiêu sau buổi lab

Sau khi hoàn thành Lab 04, mỗi nhóm cần làm được:

- Viết được `Dockerfile` cho service của nhóm.
- Dùng `.dockerignore` để giảm context build.
- Tách cấu hình runtime qua `.env.example`.
- Không commit secret thật vào repo.
- Chạy app bằng user non-root trong container.
- Có `HEALTHCHECK` gọi `GET /health`.
- Build được Docker image.
- Run được container từ image.
- Chạy lại Postman Collection của Lab 03 trên container.
- Kiểm tra được functional, auth, negative, boundary và schema lỗi `ProblemDetails`.
- Xuất Newman report làm bằng chứng.
- Viết được `RUN_LOCAL.md` hướng dẫn người khác chạy lại trong 3–5 bước.

---

## 3. Cấu trúc repo

```text
FIT4110_lab04_docker_packaging/
├── README.md
├── RUN_LOCAL.md
├── Dockerfile
├── .dockerignore
├── .env.example
├── .gitignore
├── Makefile
├── package.json
├── requirements.txt
├── src/
│   └── iot_app/
│       ├── __init__.py
│       └── main.py
├── contracts/
│   └── iot-ingestion.openapi.yaml
├── postman/
│   ├── collections/
│   │   └── FIT4110_lab04_iot_docker.postman_collection.json
│   └── environments/
│       ├── FIT4110_lab04_mock.postman_environment.json
│       └── FIT4110_lab04_local.postman_environment.json
├── mock-data/
├── scripts/
├── docs/
├── checklists/
├── templates/
├── reports/
└── .github/
    └── workflows/
        └── docker-newman.yml
```

---

## 4. Chuẩn bị môi trường

Cần cài trước:

- Git
- Docker Desktop hoặc Docker Engine
- Node.js 20.x LTS
- npm
- Postman Desktop hoặc Postman Web

Cài dependencies phục vụ Prism, Spectral, Newman:

```bash
npm install
```

Kiểm tra:

```bash
docker --version
docker info
node --version
npx newman --version
npx prism --version
```

---

## 5. Chạy service local không dùng Docker

Cài Python dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Chạy API:

```bash
uvicorn iot_app.main:app --app-dir src --host 0.0.0.0 --port 8000
```

Kiểm tra:

```bash
curl http://localhost:8000/health
```

---

## 6. Build và chạy bằng Docker

Build image:

```bash
docker build -t fit4110/iot-ingestion:lab04 .
```

Run container:

```bash
docker run --rm \
  --name fit4110-iot-lab04 \
  -p 8000:8000 \
  --env-file .env.example \
  fit4110/iot-ingestion:lab04
```

Kiểm tra health:

```bash
curl http://localhost:8000/health
```

---

## 7. Chạy lại Postman Collection trên container

Chạy Newman với local environment:

```bash
npm run test:local
```

Hoặc dùng script:

```bash
bash scripts/run-newman.sh local
```

Report được sinh trong:

```text
reports/
```

---

## 8. Các lệnh nhanh bằng Makefile

```bash
make install
make lint
make mock
make test-mock
make build
make run
make test-docker
make stop
```

---

## 9. Bài làm của từng nhóm

Mỗi nhóm dùng repo này làm mẫu, sau đó thay phần IoT bằng service của mình.

| Nhóm | Cần thay đổi |
|---|---|
| `team-iot` | Có thể dùng mẫu này trực tiếp, mở rộng thêm endpoint từ Lab 03 |
| `team-camera` | Thay `src/` bằng Camera Stream service, thêm OpenCV headless |
| `team-gate` | Thay bằng Access Gate service, lưu ý biến môi trường DB |
| `team-vision` | Thay bằng AI Vision service, chuẩn bị model YOLOv8n hoặc mock model |
| `team-analytics` | Thay bằng Analytics service, chưa bắt buộc TimescaleDB trong Lab 04 |
| `team-core` | Thay bằng Core Business policy engine |
| `team-notify` | Thay bằng Notification service, không commit token thật |

---

## 10. Điều kiện hoàn thành Lab 04

Một nhóm được xem là hoàn thành khi:

- `Dockerfile` build được image.
- Image chạy được container.
- Container có `GET /health` trả `200`.
- Service chạy bằng non-root user.
- Có `.dockerignore`.
- Có `.env.example`.
- Có `RUN_LOCAL.md`.
- Chạy lại Postman/Newman pass trên container.
- Có test cho functional, auth, negative, boundary.
- Error response trả đúng dạng `ProblemDetails`.
- Có report trong `reports/`.
- Có bằng chứng image tag đúng quy ước.

Tag gợi ý:

```text
v0.1.0-<team>
```

Ví dụ:

```bash
docker tag fit4110/iot-ingestion:lab04 ghcr.io/<owner>/team-iot:v0.1.0-team-iot
```

---

## 11. Artefact cần nộp

```text
Dockerfile
.dockerignore
.env.example
RUN_LOCAL.md
contracts/<team>.openapi.yaml
postman/collections/<team>.postman_collection.json
postman/environments/<team>_local.postman_environment.json
reports/newman-lab04-local.xml
reports/newman-lab04-local.html
ảnh chụp /health hoặc log container
tag image đã push lên registry
```

---

## 12. Rubric gợi ý

| Tiêu chí | Điểm |
|---|---:|
| Dockerfile đúng, build được | 2.0 |
| Container chạy được và `/health` pass | 2.0 |
| Non-root, `.dockerignore`, `.env.example` tốt | 2.0 |
| Newman/Postman test pass trên container | 2.0 |
| RUN_LOCAL.md rõ ràng, người khác chạy lại được | 1.0 |
| Evidence đầy đủ: log/report/image tag | 1.0 |
| **Tổng** | **10.0** |

---

## 13. Tinh thần của buổi học

Sau Buổi 3, nhóm đã chứng minh:

```text
API đúng contract khi kiểm thử bằng Postman/Newman.
```

Sau Buổi 4, nhóm cần chứng minh thêm:

```text
API đó có thể được đóng gói, chạy lại và kiểm thử trong container.
```

Đây là bước đệm trực tiếp cho Buổi 5:

```text
Docker container đơn lẻ → Docker Compose nhiều service → Plug-a-thon.
```
## 14. KẾT QUẢ NGHIỆM THU THỰC TẾ (LAB COMPLETION EVIDENCE)

### 🐳 Trạng thái Docker Readiness Checklist (Nhiệm vụ Lab 04)
- [x] **Base image hợp lý:** Sử dụng `python:3.11-slim` tối ưu kích thước.
- [x] **Có `WORKDIR` & Tận dụng cache:** Phân tách bước cài đặt thư viện trước khi copy mã nguồn.
- [x] **Bảo mật hệ thống:** Cấu hình chạy app bằng `appuser` (Non-root user) và cô lập Secret Token ra biến môi trường ngoài.
- [x] **Giám sát sức khỏe (`HEALTHCHECK`):** Tích hợp script python nội bộ thăm dò endpoint `/health` định kỳ mỗi 30 giây.
- [x] **Newman test pass trên container:** Đạt tỷ lệ vượt qua kịch bản kiểm thử tuyệt đối **19/19 Assertions Pass (0 lỗi Failed)**.

---

### 📸 Bằng chứng Vận hành & Nhật ký Hệ thống (Text Logs)

#### A. Nhật ký Đóng gói Docker Image (`docker build`)
```bash
PS D:\BTVN ket noi du lieu\lab-04-NguyenVuong21> docker build -t fit4110/iot-ingestion:lab04 .
[+] Building 128.8s (19/19) FINISHED                                                    docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                    0.0s
 => [builder 5/5] RUN /opt/venv/bin/pip install --no-cache-dir --upgrade pip     && /opt/venv/bin/p  109.8s
 => [runtime 6/6] RUN chown -R appuser:appgroup /app                                                    0.2s 
 => exporting to image                                                                                  2.1s 
 => => naming to docker.io/fit4110/iot-ingestion:lab04                                                  0.0s
#### B. Nhật ký Khởi chạy Container ngầm dưới nền (docker run)
Bash
PS D:\BTVN ket noi du lieu\lab-04-NguyenVuong21> docker run --rm -d --name fit4110-iot-lab04 -p 8000:8000 --env AUTH_TOKEN=local-dev-token fit4110/iot-ingestion:lab04
0117e9df998807bfdb81257dbcc0ee558239bb0fb7dc550cfdd554d9aec4ae65
#### C. Kết quả Phản hồi Thăm dò Sức khỏe (GET /health)
Bash
PS D:\BTVN ket noi du lieu\lab-04-NguyenVuong21> curl.exe http://localhost:8000/health
{"status":"ok","service":"iot-ingestion","version":"0.4.0"}
#### D. Ma trận Bằng chứng Kiểm thử Tự động của Newman (npm run test:local)
Bash
PS D:\BTVN ket noi du lieu\lab-04-NguyenVuong21> npm run test:local

FIT4110 Lab04 IoT Docker Verification

□ 01_Functional
  └ GET health returns 200 [200 OK, 23ms]
    √  Status code is 200
  └ POST valid temperature reading returns 201 [201 Created, 6ms]
    √  Status code is 201
    √  Response follows created-reading schema
    √  Response device_id matches request
  └ GET reading by saved reading_id returns 200 [200 OK, 3ms]
    √  Status code is 200
    √  Response reading_id matches saved variable

□ 02_Auth
  └ POST reading without token returns 401 [401 Unauthorized, 3ms]
    √  Missing token returns 401
  └ POST reading with wrong token returns 401 [401 Unauthorized, 4ms]
    √  Wrong token returns 401

□ 03_Negative
  └ POST reading missing device_id returns validation error [422 Unprocessable Entity, 7ms]
    √  Missing required field returns 422

□ 04_Boundary_Reliability
  └ POST boundary temperature 80 is accepted with warning [201 Created, 4ms]
    √  Boundary value 80 returns 201
    √  High temperature response includes warning header
  └ POST boundary temperature 81 is rejected [422 Unprocessable Entity, 2ms]
    √  Boundary value 81 returns 422

┌─────────────────────────┬─────────────────┬─────────────────┐
│                         │        executed │          failed │
├─────────────────────────┼─────────────────┼─────────────────┤
│            test-scripts │              11 │               0 │
├─────────────────────────┼─────────────────┼─────────────────┤
│              assertions │              19 │               0 │
└─────────────────────────┴─────────────────┴─────────────────┘
total run duration: 995ms
#### E. Image Tag Định danh bàn giao (GHCR Registry)
Plaintext
ghcr.io/nguyenvuong21/team-iot:v0.1.0-team-iot