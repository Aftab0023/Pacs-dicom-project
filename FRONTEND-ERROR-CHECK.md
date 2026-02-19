# 🔍 Frontend Error Check & Troubleshooting

## ✅ Current Status: HEALTHY

All containers are running properly:
- **Frontend**: http://localhost:3000 ✅
- **API**: http://localhost:5000 ✅  
- **Orthanc**: http://localhost:8042 ✅
- **SQL Server**: localhost:1433 ✅

## 🚨 Common Frontend Errors & Solutions

### 1. **Container Not Running**
**Symptoms**: "This site can't be reached" or connection refused
**Solution**: 
```powershell
docker-compose up -d
docker-compose ps  # Check all containers are running
```

### 2. **Authentication Errors**
**Symptoms**: Redirected to login, token expired
**Check**: Browser localStorage
```javascript
// Open browser console (F12) and run:
localStorage.getItem('token')
localStorage.getItem('user')
```
**Solution**: Clear localStorage and login again
```javascript
localStorage.clear()
```

### 3. **API Connection Errors**
**Symptoms**: Network errors, 500 status codes
**Check**: API container logs
```powershell
docker logs pacs-api --tail 50
```

### 4. **CORS Errors**
**Symptoms**: "Access-Control-Allow-Origin" errors
**Check**: API is running on correct port (5000)
**Solution**: Restart API container
```powershell
docker-compose restart pacs-api
```

### 5. **Build Errors**
**Symptoms**: White screen, JavaScript errors
**Check**: Frontend build logs
```powershell
docker logs pacs-frontend --tail 50
```
**Solution**: Rebuild frontend
```powershell
docker-compose up -d --build pacs-frontend
```

## 🔧 Quick Diagnostic Commands

### Check All Services
```powershell
# Check container status
docker-compose ps

# Check specific container logs
docker logs pacs-frontend --tail 20
docker logs pacs-api --tail 20
docker logs pacs-orthanc --tail 20
docker logs pacs-sqlserver --tail 20

# Test API connectivity
Invoke-RestMethod -Uri "http://localhost:5000/swagger" -Method GET

# Test frontend
Invoke-RestMethod -Uri "http://localhost:3000" -Method GET
```

### Browser Console Checks
Open browser console (F12) and check for:
- ❌ Red error messages
- ⚠️ Yellow warning messages
- 🌐 Network tab for failed requests

## 🐛 Known Issues & Fixes

### Issue 1: "Cannot find module 'react'"
**Cause**: TypeScript configuration issue
**Status**: ⚠️ Warning only (doesn't affect runtime)
**Fix**: Not critical, app works fine

### Issue 2: Worklist shows "Loading..." forever
**Cause**: API not responding or database connection issue
**Check**: 
```powershell
# Test API endpoint directly
Invoke-RestMethod -Uri "http://localhost:5000/api/worklist?page=1&pageSize=10" -Headers @{Authorization="Bearer YOUR_TOKEN"}
```

### Issue 3: OHIF Viewer authentication
**Cause**: Browser can't pass credentials to iframe
**Status**: ✅ Fixed - now opens in new window
**Solution**: Click "Open in OHIF Viewer" → Login with orthanc/orthanc

### Issue 4: Study not appearing in worklist
**Cause**: Webhook not working, study not in database
**Check**: Database query
```sql
SELECT * FROM Studies;
SELECT * FROM Patients;
```

## 📊 Health Check Script

Create this PowerShell script to check everything:

```powershell
# health-check.ps1
Write-Host "🔍 PACS System Health Check" -ForegroundColor Cyan

# Check containers
Write-Host "`n📦 Container Status:" -ForegroundColor Yellow
docker-compose ps

# Check endpoints
Write-Host "`n🌐 Endpoint Tests:" -ForegroundColor Yellow

try {
    $frontend = Invoke-RestMethod -Uri "http://localhost:3000" -TimeoutSec 5
    Write-Host "✅ Frontend: OK" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend: FAILED" -ForegroundColor Red
}

try {
    $api = Invoke-RestMethod -Uri "http://localhost:5000/swagger" -TimeoutSec 5
    Write-Host "✅ API: OK" -ForegroundColor Green
} catch {
    Write-Host "❌ API: FAILED" -ForegroundColor Red
}

try {
    $orthanc = Invoke-RestMethod -Uri "http://localhost:8042/app/explorer.html" -TimeoutSec 5
    Write-Host "✅ Orthanc: OK" -ForegroundColor Green
} catch {
    Write-Host "❌ Orthanc: FAILED" -ForegroundColor Red
}

Write-Host "`n🎯 Quick Tests:" -ForegroundColor Yellow
Write-Host "1. Open: http://localhost:3000"
Write-Host "2. Login: admin@pacs.local / Admin123!"
Write-Host "3. Check worklist for studies"
Write-Host "4. Test OHIF: http://localhost:8042/ohif/viewer?StudyInstanceUIDs=1.3.6.1.4.1.44316.6.102.1.20250704114423696.6115867211953577193"
```

## 🚀 Performance Optimization

### Frontend Performance Tips:
1. **Enable browser caching** - Static assets are cached
2. **Use Chrome DevTools** - Check Network tab for slow requests
3. **Monitor memory usage** - Large DICOM studies can use lots of RAM

### Common Slow Operations:
- **Worklist loading** - Depends on database query performance
- **OHIF loading** - Depends on DICOM file size and network
- **Report creation** - Usually fast

## 🔄 Recovery Procedures

### Complete System Reset:
```powershell
# Stop all containers
docker-compose down

# Remove containers and volumes (CAUTION: Deletes data!)
docker-compose down -v

# Rebuild and start
docker-compose up -d --build

# Wait for SQL Server to initialize (2-3 minutes)
# Then manually insert test study again
```

### Partial Reset (Keep Data):
```powershell
# Restart specific service
docker-compose restart pacs-frontend
docker-compose restart pacs-api

# Rebuild specific service
docker-compose up -d --build pacs-frontend
```

## 📱 Browser Compatibility

| Browser | Status | Notes |
|---------|--------|-------|
| Chrome | ✅ Fully Supported | Recommended |
| Edge | ✅ Fully Supported | Recommended |
| Firefox | ✅ Mostly Supported | Some OHIF features may vary |
| Safari | ⚠️ Limited Support | OHIF may have issues |
| IE | ❌ Not Supported | Use modern browser |

## 🎯 Current System Status

**Last Checked**: Working properly
**Frontend**: ✅ Running on port 3000
**API**: ✅ Running on port 5000  
**Database**: ✅ Connected with test data
**OHIF**: ✅ Working with authentication
**Worklist**: ✅ Displaying studies

**Next Steps**:
1. Test complete workflow (login → worklist → OHIF → reporting)
2. Upload additional DICOM studies
3. Test reporting functionality
4. Customize UI as needed

## 🆘 Emergency Contacts

If you encounter persistent issues:
1. Check this document first
2. Run the health check script
3. Check Docker logs for specific error messages
4. Restart the problematic service
5. If all else fails, do a complete system reset (with data backup)