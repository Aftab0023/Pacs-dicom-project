# PACS Testing Guide

## Testing Strategy

### 1. Unit Testing (Backend)

Create test project:

```bash
cd backend
dotnet new xunit -n PACS.Tests
cd PACS.Tests
dotnet add reference ../PACS.Core/PACS.Core.csproj
dotnet add reference ../PACS.Infrastructure/PACS.Infrastructure.csproj
dotnet add package Moq
dotnet add package Microsoft.EntityFrameworkCore.InMemory
```

### 2. Integration Testing

Test API endpoints with real database:

```bash
dotnet test
```

### 3. End-to-End Testing (Frontend)

Install testing tools:

```bash
cd frontend
npm install --save-dev @testing-library/react @testing-library/jest-dom vitest
```

## Manual Testing Workflow

### Step 1: Send Test DICOM Study

Use DICOM tools to send a study to Orthanc:

**Using dcm4che storescu:**

```bash
storescu -c ORTHANC@localhost:4242 /path/to/dicom/files
```

**Using Orthanc's built-in upload:**

1. Open http://localhost:8042
2. Login with orthanc/orthanc
3. Click "Upload" and select DICOM files

### Step 2: Verify Study Ingestion

1. Check Orthanc received the study:
   - Go to http://localhost:8042
   - Verify study appears in list

2. Check webhook triggered:
   - Check API logs for webhook processing
   - Verify study appears in database

3. Check frontend worklist:
   - Login to http://localhost:3000
   - Navigate to Worklist
   - Verify study appears

### Step 3: Test Worklist Features

1. **Search**
   - Search by patient name
   - Search by MRN
   - Search by accession number

2. **Filter**
   - Filter by modality (CT, MR, XR)
   - Filter by status
   - Filter by date range

3. **Actions**
   - Assign study to radiologist
   - Set priority flag
   - Update status

### Step 4: Test Study Viewer

1. Click "View" on a study
2. Verify patient demographics display
3. Verify series list shows correctly
4. Click "Open in OHIF Viewer"
5. Verify images load in OHIF

### Step 5: Test Reporting

1. Click "Report" on a study
2. Enter clinical history
3. Enter findings
4. Enter impression
5. Click "Save Draft"
6. Verify draft saved
7. Click "Finalize Report"
8. Verify report finalized
9. Download PDF report

### Step 6: Test Authentication

1. **Login**
   - Test with valid credentials
   - Test with invalid credentials
   - Verify JWT token stored

2. **Authorization**
   - Test radiologist access
   - Test admin access
   - Verify role-based restrictions

3. **Logout**
   - Click logout
   - Verify redirect to login
   - Verify token cleared

## API Testing with Postman/Curl

### Login

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pacs.local","password":"Admin123!"}'
```

### Get Worklist

```bash
curl -X GET "http://localhost:5000/api/worklist?page=1&pageSize=20" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Get Study Detail

```bash
curl -X GET http://localhost:5000/api/worklist/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Create Report

```bash
curl -X POST http://localhost:5000/api/report \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "studyId": 1,
    "reportText": "Clinical history",
    "findings": "Detailed findings",
    "impression": "Conclusion"
  }'
```

## Performance Testing

### Load Testing with Apache Bench

Test API performance:

```bash
ab -n 1000 -c 10 -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:5000/api/worklist
```

### Database Performance

Monitor query performance:

```sql
-- Check slow queries
SELECT TOP 10 
    total_elapsed_time/execution_count AS avg_time,
    text
FROM sys.dm_exec_query_stats
CROSS APPLY sys.dm_exec_sql_text(sql_handle)
ORDER BY avg_time DESC
```

## Security Testing

### 1. Authentication Testing

- Test JWT expiration
- Test token refresh
- Test invalid tokens
- Test missing tokens

### 2. Authorization Testing

- Test role-based access
- Test unauthorized endpoints
- Test cross-user access

### 3. Input Validation

- Test SQL injection
- Test XSS attacks
- Test invalid data types
- Test boundary values

### 4. HTTPS Testing

- Verify SSL certificate
- Test mixed content
- Verify secure cookies

## DICOM Conformance Testing

### 1. C-STORE Testing

Send various DICOM modalities:
- CT studies
- MR studies
- X-Ray images
- Ultrasound
- Different transfer syntaxes

### 2. DICOMweb Testing

Test WADO-RS, QIDO-RS, STOW-RS:

```bash
# QIDO-RS - Search for studies
curl http://localhost:8042/dicom-web/studies

# WADO-RS - Retrieve study
curl http://localhost:8042/dicom-web/studies/{studyUID}
```

### 3. Metadata Testing

Verify correct extraction of:
- Patient demographics
- Study information
- Series details
- Instance data

## Regression Testing

Create test suite for:
1. Study ingestion workflow
2. Worklist filtering
3. Report creation
4. User authentication
5. Role-based access

## Test Data

### Sample DICOM Files

Download test DICOM files:
- https://www.dicomlibrary.com/
- https://barre.dev/medical/samples/

### Sample Patients

Create test patients with various scenarios:
- Normal studies
- Priority studies
- Multi-series studies
- Different modalities
- Various date ranges

## Automated Testing Script

Create `test-workflow.sh`:

```bash
#!/bin/bash

echo "Testing PACS Workflow..."

# 1. Login
TOKEN=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pacs.local","password":"Admin123!"}' \
  | jq -r '.token')

echo "Token: $TOKEN"

# 2. Get Worklist
curl -s -X GET "http://localhost:5000/api/worklist?page=1&pageSize=10" \
  -H "Authorization: Bearer $TOKEN" | jq

# 3. Get Study Detail
curl -s -X GET http://localhost:5000/api/worklist/1 \
  -H "Authorization: Bearer $TOKEN" | jq

echo "Tests completed!"
```

## Monitoring During Testing

### 1. Application Logs

Monitor API logs:
```bash
docker logs -f pacs-api
```

Monitor Orthanc logs:
```bash
docker logs -f pacs-orthanc
```

### 2. Database Monitoring

Check active connections:
```sql
SELECT * FROM sys.dm_exec_sessions WHERE is_user_process = 1
```

### 3. Resource Usage

Monitor Docker containers:
```bash
docker stats
```

## Test Checklist

- [ ] User can login with valid credentials
- [ ] User cannot login with invalid credentials
- [ ] Worklist displays studies correctly
- [ ] Search functionality works
- [ ] Filters work correctly
- [ ] Pagination works
- [ ] Study viewer displays patient info
- [ ] Study viewer shows series list
- [ ] OHIF viewer launches correctly
- [ ] Report can be created
- [ ] Report can be saved as draft
- [ ] Report can be finalized
- [ ] PDF can be downloaded
- [ ] User can logout
- [ ] DICOM studies are received by Orthanc
- [ ] Webhook triggers correctly
- [ ] Metadata is extracted correctly
- [ ] Studies appear in worklist
- [ ] Audit logs are created
- [ ] Role-based access works
- [ ] API returns proper error codes
- [ ] Frontend handles errors gracefully

## Known Issues & Limitations

1. **OHIF Integration**: Requires separate OHIF Viewer deployment
2. **PDF Generation**: Basic text-based, needs proper PDF library
3. **Refresh Tokens**: Not fully implemented
4. **HL7 Support**: Not implemented in this version
5. **Modality Worklist**: Not implemented in this version

## Next Steps

1. Implement comprehensive unit tests
2. Add integration test suite
3. Set up CI/CD pipeline
4. Implement automated E2E tests
5. Add performance benchmarks
6. Create test data generator
