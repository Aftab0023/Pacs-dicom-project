# Modality Worklist (MWL) Implementation Guide

## Overview
This document describes the complete Modality Worklist implementation for the PACS system. MWL allows imaging modalities (CT, MRI, X-Ray) to query scheduled procedures and automatically populate patient/study information.

---

## What Was Implemented

### 1. Database Schema
- **Order Entity**: Stores scheduled imaging procedures
  - AccessionNumber (unique identifier)
  - Patient information (via PatientId FK)
  - Ordering/Referring physicians
  - Modality, Study description
  - Scheduled date/time
  - Status (Scheduled, InProgress, Completed, Cancelled)
  - Priority (Routine, Urgent, STAT)

- **ReportTemplate Entity**: Stores report templates for different specialties

### 2. Backend Services

#### WorklistService (`PACS.Infrastructure/Services/WorklistService.cs`)
- `GetScheduledOrdersAsync()`: Retrieve all scheduled orders
- `GetOrderByAccessionNumberAsync()`: Find specific order
- `CreateOrderAsync()`: Create new order and generate worklist file
- `UpdateOrderStatusAsync()`: Update order status
- `GenerateWorklistFilesAsync()`: Regenerate all worklist files
- `GenerateWorklistFileForOrderAsync()`: Generate DICOM worklist file for specific order

#### DICOM Worklist File Generation
Uses **fo-dicom** library to create proper DICOM worklist files (.wl) containing:
- Patient demographics (Name, ID, DOB, Sex)
- Scheduled Procedure Step (SPS) information
- Modality, AE Title, scheduled date/time
- Requesting/Referring physician information
- Accession number

### 3. API Endpoints

#### OrderController (`PACS.API/Controllers/OrderController.cs`)
```
GET    /api/order/scheduled              - Get all scheduled orders
GET    /api/order/{accessionNumber}      - Get order by accession number
POST   /api/order                        - Create new order
PUT    /api/order/{orderId}/status       - Update order status
POST   /api/order/generate-worklists     - Regenerate all worklist files
```

### 4. Orthanc Configuration
Updated `orthanc/orthanc.json`:
```json
"Worklists": {
  "Enable": true,
  "Database": "/var/lib/orthanc/worklists"
}
```

---

## How It Works

### Workflow
1. **Order Creation**: HIS/RIS creates order via API or HL7 message
2. **Worklist Generation**: System generates DICOM worklist file (.wl)
3. **Modality Query**: Imaging modality queries Orthanc MWL SCP
4. **Worklist Response**: Orthanc returns matching worklist items
5. **Study Acquisition**: Modality uses worklist data to populate study
6. **Image Storage**: Images sent to PACS with correct metadata
7. **Order Completion**: Order status updated to "Completed"

### DICOM Worklist Query (C-FIND)
Modalities query using DICOM C-FIND with matching keys:
- Patient Name
- Patient ID
- Scheduled Procedure Step Start Date
- Modality
- Accession Number

---

## Deployment Steps

### Step 1: Rebuild Backend
```powershell
docker-compose down
docker-compose build pacs-backend
docker-compose up -d
```

### Step 2: Database Migration
The database will auto-migrate on startup. Verify tables created:
```sql
SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME IN ('Orders', 'ReportTemplates')
```

### Step 3: Create Worklist Directory
```powershell
docker exec pacs-orthanc mkdir -p /var/lib/orthanc/worklists
docker exec pacs-orthanc chmod 777 /var/lib/orthanc/worklists
```

### Step 4: Restart Orthanc
```powershell
docker-compose restart pacs-orthanc
```

### Step 5: Verify Orthanc Configuration
Check Orthanc logs:
```powershell
docker logs pacs-orthanc
```
Should see: "Worklist plugin is enabled"

---

## Testing

### Test 1: Create Sample Order
```powershell
$headers = @{
    "Authorization" = "Bearer YOUR_JWT_TOKEN"
    "Content-Type" = "application/json"
}

$body = @{
    accessionNumber = "ACC001"
    patientId = 1
    orderingPhysician = "Dr. Smith"
    referringPhysician = "Dr. Jones"
    modality = "CT"
    studyDescription = "CT Chest with Contrast"
    scheduledDateTime = "2026-02-20T10:00:00Z"
    priority = "Routine"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/api/order" `
    -Method POST `
    -Headers $headers `
    -Body $body
```

### Test 2: Verify Worklist File Created
```powershell
docker exec pacs-orthanc ls -la /var/lib/orthanc/worklists/
```
Should see: `ACC001.wl`

### Test 3: Query Worklist from Modality
Use DICOM MWL query tool (e.g., dcmtk's findscu):
```bash
findscu -v -S -k 0008,0050="" \
    -k 0010,0010="" \
    -k 0010,0020="" \
    -k 0040,0100[0].0040,0002="" \
    localhost 4242
```

### Test 4: API Testing
```powershell
# Get scheduled orders
Invoke-RestMethod -Uri "http://localhost:5000/api/order/scheduled" `
    -Headers $headers

# Get specific order
Invoke-RestMethod -Uri "http://localhost:5000/api/order/ACC001" `
    -Headers $headers

# Update order status
$statusBody = @{ status = "InProgress" } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:5000/api/order/1/status" `
    -Method PUT `
    -Headers $headers `
    -Body $statusBody
```

---

## Integration with HIS/RIS

### Option 1: REST API
HIS/RIS can directly call the Order API endpoints to create/manage orders.

### Option 2: HL7 Integration (Future)
Implement HL7 listener to receive ORM (Order) messages:
- Parse HL7 ORM^O01 messages
- Extract patient and order information
- Create Order via WorklistService
- Send ACK response

---

## Configuration

### appsettings.json
```json
"Worklist": {
  "Path": "/var/lib/orthanc/worklists"
}
```

### Docker Volume (if needed)
Add to `docker-compose.yml`:
```yaml
pacs-orthanc:
  volumes:
    - orthanc-worklists:/var/lib/orthanc/worklists

volumes:
  orthanc-worklists:
```

---

## Troubleshooting

### Issue: Worklist files not generated
**Solution**: Check logs, ensure directory permissions:
```powershell
docker logs pacs-backend
docker exec pacs-orthanc ls -la /var/lib/orthanc/worklists/
```

### Issue: Modality can't query worklist
**Solution**: 
1. Verify Orthanc worklist plugin enabled
2. Check modality AE Title configured in Orthanc
3. Test DICOM connectivity: `echoscu localhost 4242`

### Issue: Empty worklist response
**Solution**: 
1. Verify worklist files exist
2. Check query matching keys
3. Ensure order status is "Scheduled"

### Issue: Database migration fails
**Solution**: 
1. Drop and recreate database
2. Check connection string
3. Verify EF Core packages installed

---

## Next Steps

### High Priority
1. ✅ Database schema (Orders, ReportTemplates)
2. ✅ WorklistService implementation
3. ✅ DICOM worklist file generation
4. ✅ Order API endpoints
5. ✅ Orthanc configuration
6. ⏳ Frontend UI for order management
7. ⏳ HL7 listener service

### Medium Priority
- Report template management UI
- Digital signature implementation
- HL7 result delivery
- Voice dictation integration

### Low Priority
- Advanced worklist filtering
- Multi-site worklist distribution
- Worklist statistics/analytics

---

## Files Modified/Created

### Created
- `backend/PACS.Core/Entities/Order.cs`
- `backend/PACS.Core/Entities/ReportTemplate.cs`
- `backend/PACS.Core/DTOs/OrderDTOs.cs`
- `backend/PACS.Core/DTOs/TemplateDTO.cs`
- `backend/PACS.Core/Interfaces/IWorklistService.cs`
- `backend/PACS.Infrastructure/Services/WorklistService.cs`
- `backend/PACS.API/Controllers/OrderController.cs`

### Modified
- `backend/PACS.Infrastructure/Data/PACSDbContext.cs` (added Order, ReportTemplate DbSets)
- `backend/PACS.API/Program.cs` (registered IWorklistService)
- `backend/PACS.Infrastructure/PACS.Infrastructure.csproj` (added fo-dicom package)
- `backend/PACS.API/appsettings.json` (added Worklist configuration)
- `backend/PACS.Core/Entities/Report.cs` (enhanced with template support)
- `orthanc/orthanc.json` (enabled Worklists)

---

## References

- [DICOM Modality Worklist Standard](https://dicom.nema.org/medical/dicom/current/output/chtml/part04/chapter_K.html)
- [fo-dicom Documentation](https://github.com/fo-dicom/fo-dicom)
- [Orthanc Worklist Plugin](https://book.orthanc-server.com/plugins/worklists.html)
