# PACS System — Complete Project Guide

## What This System Does

A full Picture Archiving and Communication System (PACS) for medical imaging.
Radiologists can view DICOM studies, write reports, and manage patient worklists.

---

## Architecture Overview

```
Browser (any device on network)
    │
    ▼
pacs-frontend  (React + Nginx)  :3000
    │  calls API
    ▼
pacs-api       (.NET 8)         :5000
    │  reads/writes
    ├──► SQL Server              :1434  (your local Windows install)
    │  fetches DICOM metadata
    └──► pacs-orthanc            :8042 / :4242
              │  fires webhook on new study
              └──► pacs-api /api/orthanc/webhook
```

---

## Project Structure

```
Pacs-dicom-project/
│
├── backend/                        ← .NET 8 API (C#)
│   ├── PACS.API/
│   │   ├── Controllers/            ← HTTP endpoints
│   │   │   ├── AuthController.cs         login/logout
│   │   │   ├── WorklistController.cs     study list + stats
│   │   │   ├── ReportController.cs       create/finalize reports + PDF
│   │   │   ├── OrthancWebhookController  receives new DICOM studies
│   │   │   ├── PatientShareController    share study links
│   │   │   └── SystemSettingsController  admin settings
│   │   ├── Program.cs              ← app startup, DI, middleware
│   │   ├── appsettings.json        ← DB connection, JWT, Orthanc URL
│   │   └── Dockerfile
│   │
│   ├── PACS.Core/
│   │   ├── Entities/               ← database models (Study, Patient, Report...)
│   │   ├── DTOs/                   ← request/response shapes
│   │   └── Interfaces/             ← service contracts
│   │
│   └── PACS.Infrastructure/
│       ├── Data/
│       │   └── PACSDbContext.cs    ← EF Core context + indexes
│       └── Services/
│           ├── StudyService.cs     ← worklist queries + caching
│           ├── ReportService.cs    ← report CRUD + PDF generation
│           ├── OrthancService.cs   ← fetches DICOM metadata, saves to DB
│           ├── AuthService.cs      ← JWT login
│           ├── WorklistService.cs  ← DICOM modality worklist (.wl files)
│           ├── AuditService.cs     ← audit logging
│           ├── PatientShareService ← share token management
│           └── SystemSettingsService ← settings CRUD
│
├── frontend/                       ← React + TypeScript + Tailwind
│   ├── src/
│   │   ├── pages/
│   │   │   ├── Login.tsx           ← login form
│   │   │   ├── Dashboard.tsx       ← stats cards
│   │   │   ├── Worklist.tsx        ← main study list
│   │   │   ├── StudyViewer.tsx     ← study detail + OHIF launch
│   │   │   ├── OHIFViewer.tsx      ← redirects to Orthanc OHIF
│   │   │   ├── Reporting.tsx       ← write radiology report
│   │   │   ├── ReportPreview.tsx   ← view/print finalized report
│   │   │   ├── SharedViewer.tsx    ← patient share link viewer
│   │   │   ├── AdminSettings.tsx   ← system settings (Admin only)
│   │   │   └── WorklistManagement  ← DICOM modality worklist management
│   │   ├── components/
│   │   │   ├── Layout.tsx          ← nav bar + page wrapper
│   │   │   └── ViewerShareDialog   ← share study with patient
│   │   ├── contexts/
│   │   │   └── AuthContext.tsx     ← JWT token + user state
│   │   └── services/
│   │       └── api.ts              ← all API calls + runtime URL config
│   ├── public/
│   │   └── config.js               ← EDIT THIS to change IP after deployment
│   ├── .env                        ← build-time IP (used during npm run build)
│   ├── .env.example                ← template — copy to .env
│   └── Dockerfile
│
├── orthanc/
│   ├── orthanc.json                ← Orthanc server config
│   └── webhook.lua                 ← fires when new DICOM arrives → calls API
│
├── database/
│   └── init.sql                    ← initial DB schema (used by Docker SQL Server)
│
├── docker-compose.yml              ← runs API + Frontend + Orthanc together
├── CHANGE-IP.md                    ← how to update IP when it changes
└── PROJECT-GUIDE.md                ← this file
```

---

## Setup on a New Machine (Docker)

### Prerequisites
- Docker Desktop installed and running
- Git installed
- Your server IP address (run `ipconfig` to find it)

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd Pacs-dicom-project

# 2. Set your IP in frontend/.env
echo VITE_API_URL=http://YOUR_IP:5000/api > frontend/.env
echo VITE_ORTHANC_URL=http://YOUR_IP:8042 >> frontend/.env

# 3. Update docker-compose.yml build args with same IP
# Edit docker-compose.yml → pacs-frontend → args section

# 4. Update orthanc webhook
# Edit orthanc/webhook.lua line 4 → API_URL = "http://YOUR_IP:5000/api/orthanc/webhook"

# 5. Start everything
docker compose up -d --build

# 6. Open firewall ports (run as Admin)
netsh advfirewall firewall add rule name="PACS API" dir=in action=allow protocol=TCP localport=5000
netsh advfirewall firewall add rule name="PACS Frontend" dir=in action=allow protocol=TCP localport=3000
netsh advfirewall firewall add rule name="PACS Orthanc" dir=in action=allow protocol=TCP localport=8042
netsh advfirewall firewall add rule name="PACS DICOM" dir=in action=allow protocol=TCP localport=4242
```

### Access
| Service | URL |
|---|---|
| Frontend | http://YOUR_IP:3000 |
| API Swagger | http://YOUR_IP:5000/swagger |
| Orthanc | http://YOUR_IP:8042 |

### Default Logins
| Role | Email | Password |
|---|---|---|
| Admin | admin@pacs.local | Admin123! |
| Radiologist | radiologist@pacs.local | Radio123! |

---

## SQL Server

This project uses your **local Windows SQL Server** (not Docker).

Connection string in `backend/PACS.API/appsettings.json`:
```json
"DefaultConnection": "Server=host.docker.internal,1434;Database=PACSDB;..."
```

- `host.docker.internal` = Docker's way of reaching your Windows host
- Port `1434` = SQL Server Express default named instance port
- Database `PACSDB` is auto-created on first API startup

---

## How DICOM Flow Works

```
1. Modality (CT/MRI) sends DICOM → Orthanc port 4242
2. Orthanc stores the file
3. After 3 seconds (StableAge), Orthanc fires webhook.lua
4. webhook.lua POSTs to API: /api/orthanc/webhook
5. API fetches study metadata from Orthanc
6. API saves Patient + Study + Series + Instances to SQL Server
7. Study appears in Worklist immediately
8. Radiologist opens OHIF viewer → views DICOM images
9. Radiologist writes report → finalizes → PDF generated
```

---

## Key Configuration Files

### `backend/PACS.API/appsettings.json`
- DB connection string
- JWT secret key
- Orthanc URL (internal Docker network: `http://orthanc:8042`)

### `frontend/public/config.js`
- Runtime URL config — edit after deployment without rebuilding
- `API_URL` — where the browser sends API requests
- `ORTHANC_URL` — where the browser opens OHIF viewer

### `orthanc/orthanc.json`
- Orthanc HTTP/DICOM ports
- Registered DICOM modalities (CT rooms, MRI, X-Ray)
- StableAge: 3 seconds (how long to wait before firing webhook)

### `docker-compose.yml`
- Defines all 3 containers: pacs-api, pacs-frontend, orthanc
- Maps ports to host
- Sets environment variables for API

---

## Changing IP — Quick Summary

See `CHANGE-IP.md` for full details.

Short version — update these 4 places:
1. `frontend/.env` → `VITE_API_URL` and `VITE_ORTHANC_URL`
2. `docker-compose.yml` → frontend build `args`
3. `frontend/public/config.js` → `API_URL` and `ORTHANC_URL`
4. `orthanc/webhook.lua` → `API_URL`

Then: `docker compose build --no-cache pacs-frontend && docker compose up -d pacs-frontend`
