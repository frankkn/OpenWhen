# OpenWhen — 開發指引

## 專案概述

OpenWhen 是一個「時光膠囊信件」app：使用者寫一封信給未來的自己，鎖住後等到設定的日期才能開封；開封時 AI 扮演見證者，根據信的內容提問，幫使用者反思當年的自己。

---

## 技術架構

| 層級       | 技術                                      |
|------------|-------------------------------------------|
| Frontend   | Flutter（Web PWA + Android）              |
| Backend    | FastAPI + Python 3.11+                    |
| 資料庫     | PostgreSQL 15                             |
| Auth       | Firebase Authentication（Google OAuth + Email/密碼）|
| AI         | Claude API (`claude-sonnet-4-6`)          |
| 排程       | APScheduler（到期膠囊通知，MVP 階段暫略）  |
| Email      | Resend API（MVP 階段暫略）                |

---

## 本地開發環境啟動

### 前置需求
- Python 3.11+
- Flutter 3.x（`flutter doctor` 確認無誤）
- Docker Desktop（跑 PostgreSQL）
- Firebase 專案（已開啟 Authentication）

### Backend

```bash
cd backend

# 1. 建立虛擬環境
python -m venv venv
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# 2. 安裝依賴
pip install -r requirements.txt

# 3. 設定環境變數（複製後填入真實值）
cp .env.example .env

# 4. 啟動 PostgreSQL（用 Docker）
docker run -d \
  --name openwhen-db \
  -e POSTGRES_USER=openwhen \
  -e POSTGRES_PASSWORD=openwhen_dev \
  -e POSTGRES_DB=openwhen \
  -p 5432:5432 \
  postgres:15

# 5. 執行資料庫 migration
alembic upgrade head

# 6. 啟動 FastAPI（dev mode）
uvicorn app.main:app --reload --port 8000
```

API Docs: http://localhost:8000/docs

### Frontend

```bash
cd frontend

# 安裝 Flutter 依賴
flutter pub get

# 設定環境變數（填入 .env 或 lib/config/env.dart）

# 啟動 Web（dev）
flutter run -d chrome

# 啟動 Android
flutter run -d android
```

---

## 環境變數清單

### Backend (`backend/.env`)

```env
# 資料庫
DATABASE_URL=postgresql://openwhen:openwhen_dev@localhost:5432/openwhen

# Firebase
FIREBASE_PROJECT_ID=
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json

# Claude AI
ANTHROPIC_API_KEY=

# Email（MVP 後再加）
RESEND_API_KEY=

# App
SECRET_KEY=
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Frontend (`frontend/lib/config/env.dart`)

```dart
// Firebase（填入 Firebase Console 的 Web app config）
const firebaseApiKey = '';
const firebaseAuthDomain = '';
const firebaseProjectId = '';
const firebaseStorageBucket = '';
const firebaseMessagingSenderId = '';
const firebaseAppId = '';

// Backend API
const apiBaseUrl = 'http://localhost:8000';
```

---

## 資料庫 Schema 總覽

### `users`
| 欄位           | 型別         | 說明                    |
|----------------|--------------|-------------------------|
| id             | UUID PK      |                         |
| firebase_uid   | VARCHAR      | Firebase UID，唯一      |
| email          | VARCHAR      |                         |
| display_name   | VARCHAR      |                         |
| created_at     | TIMESTAMP    |                         |

### `capsules`
| 欄位               | 型別         | 說明                             |
|--------------------|--------------|----------------------------------|
| id                 | UUID PK      |                                  |
| user_id            | UUID FK      | → users.id                       |
| title              | VARCHAR      | 選填標題                         |
| content            | TEXT         | 最終信件內容                     |
| mode               | ENUM         | `free` / `ai_assisted`          |
| status             | ENUM         | `locked` / `opened`              |
| open_date          | DATE         | 設定的開封日期                   |
| notification_email | VARCHAR      | 到期通知 email                   |
| created_at         | TIMESTAMP    |                                  |
| opened_at          | TIMESTAMP    | 實際開封時間                     |

### `capsule_answers`
| 欄位            | 型別      | 說明                          |
|-----------------|-----------|-------------------------------|
| id              | UUID PK   |                               |
| capsule_id      | UUID FK   | → capsules.id                 |
| question_number | INT       | 1～9                          |
| question_text   | TEXT      |                               |
| answer_text     | TEXT      | 可為空（跳過）                |

### `reflections`
| 欄位            | 型別      | 說明                          |
|-----------------|-----------|-------------------------------|
| id              | UUID PK   |                               |
| capsule_id      | UUID FK   | → capsules.id                 |
| question_text   | TEXT      | AI 生成的反思問題             |
| answer_text     | TEXT      | 使用者回答（選填）            |
| created_at      | TIMESTAMP |                               |

---

## API 端點清單

### Auth
| 方法   | 路徑               | 說明                                    |
|--------|--------------------|-----------------------------------------|
| POST   | `/auth/verify`     | 驗證 Firebase ID Token，建立或取得使用者 |

### Capsules
| 方法   | 路徑                      | 說明                             |
|--------|---------------------------|----------------------------------|
| GET    | `/capsules`               | 列出當前使用者所有膠囊           |
| POST   | `/capsules`               | 建立新膠囊（鎖住）               |
| GET    | `/capsules/{id}`          | 取得膠囊詳情                     |
| POST   | `/capsules/{id}/open`     | 開封膠囊（需確認日期已到）       |
| POST   | `/capsules/{id}/reflections` | 儲存開封反思回答              |

### AI
| 方法   | 路徑                      | 說明                             |
|--------|---------------------------|----------------------------------|
| POST   | `/ai/generate-letter`     | 根據 Q&A 整理成信件              |
| POST   | `/ai/generate-reflections`| 根據信件內容生成反思問題         |

---

## 目前已完成的功能

- [x] 專案目錄結構
- [x] FastAPI 骨架（main.py、router、依賴注入）
- [x] PostgreSQL 資料庫模型（SQLAlchemy + Alembic）
- [x] Firebase Auth 驗證中介層
- [x] 使用者 API（驗證 token → 建立/取得 user）
- [x] 膠囊 CRUD API
- [x] 開封 API（日期檢查）
- [x] Claude AI 整合（整理信件、生成反思問題）

## 待完成的功能

- [ ] Flutter 前端（登入頁、寫信流程、膠囊列表、開封流程）
- [ ] Firebase Auth Flutter 整合
- [ ] AI 協助模式的 9 題問答 UI
- [ ] 開封信封動畫
- [ ] APScheduler 排程（每日檢查到期膠囊）
- [ ] Resend Email 通知
- [ ] PWA manifest + service worker
- [ ] Docker Compose 完整部署設定

---

## 常見問題與解法

### Firebase service account 找不到
- Firebase Console → 專案設定 → 服務帳戶 → 產生新的私密金鑰
- 下載 JSON 放到 `backend/firebase-service-account.json`
- **不要** commit 這個檔案（已加入 .gitignore）

### alembic revision 衝突
```bash
alembic heads   # 查看目前 head
alembic merge heads  # 合併衝突的 heads
```

### Flutter Web CORS 問題
- 確認 `backend/.env` 的 `ALLOWED_ORIGINS` 包含 Flutter dev server 的 port
- 預設 Flutter Web 用 `localhost:8080` 或 `localhost:3000`

### PostgreSQL 連線失敗
```bash
docker ps  # 確認 container 有在跑
docker logs openwhen-db
```

### Claude API rate limit
- 開發時用較短的測試文字
- 生產環境考慮加 retry with exponential backoff（`tenacity` 套件）

---

## Git 工作流程

```
main      ← 穩定版本
dev       ← 日常開發
feature/* ← 功能分支
```

PR 合入 `dev`，穩定後再 merge 到 `main`。
