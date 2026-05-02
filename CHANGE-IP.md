# How to Change IP Address

When your server IP changes, update these files:

---

## Docker Environment

### 1. `frontend/.env`
```env
VITE_API_URL=http://NEW_IP:5000/api
VITE_ORTHANC_URL=http://NEW_IP:8042
```

### 2. `docker-compose.yml` — frontend build args
```yaml
args:
  - VITE_API_URL=http://NEW_IP:5000/api
  - VITE_ORTHANC_URL=http://NEW_IP:8042
```

### 3. `frontend/public/config.js`
```js
window.__PACS_CONFIG__ = {
  API_URL: "http://NEW_IP:5000/api",
  ORTHANC_URL: "http://NEW_IP:8042"
};
```

### 4. `orthanc/webhook.lua` — line 4
```lua
local API_URL = "http://NEW_IP:5000/api/orthanc/webhook"
```

Then rebuild frontend only:
```bash
docker compose build --no-cache pacs-frontend
docker compose up -d pacs-frontend
```

---

## IIS Deployment (No Rebuild Needed)

Only edit one file on the server after deployment:

```
C:\inetpub\pacs-frontend\config.js
```

```js
window.__PACS_CONFIG__ = {
  API_URL: "http://NEW_IP:5000/api",
  ORTHANC_URL: "http://NEW_IP:8042"
};
```

Save → Refresh browser. Done. No rebuild required.

---

## Quick Reference — All IP Locations

| File | What to change |
|---|---|
| `frontend/.env` | `VITE_API_URL`, `VITE_ORTHANC_URL` |
| `docker-compose.yml` | build `args` for pacs-frontend |
| `frontend/public/config.js` | `API_URL`, `ORTHANC_URL` |
| `orthanc/webhook.lua` | `API_URL` line 4 |

> `backend/PACS.API/appsettings.json` uses `sqlserver` (Docker) or `localhost,1434` (IIS) — never needs IP change.
