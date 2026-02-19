# Worklist Data Flow Explanation

## Complete Data Journey: From Database to UI

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA FLOW DIAGRAM                            │
└─────────────────────────────────────────────────────────────────────┘

1. USER INTERACTION (Frontend)
   ↓
2. API CALL (React Query)
   ↓
3. HTTP REQUEST (Axios)
   ↓
4. API CONTROLLER (ASP.NET Core)
   ↓
5. SERVICE LAYER (Business Logic)
   ↓
6. DATABASE QUERY (Entity Framework)
   ↓
7. SQL SERVER (Database)
   ↓
8. RESPONSE BACK UP THE CHAIN
```

---

## Detailed Step-by-Step Flow

### 1️⃣ **Frontend - User Opens Worklist Page**
**File:** `frontend/src/pages/Worklist.tsx`

```typescript
// User lands on /worklist page
const [filters, setFilters] = useState({
  searchTerm: '',
  modality: '',
  status: '',
  page: 1,
  pageSize: 20
})

// React Query automatically fetches data
const { data, isLoading } = useQuery({
  queryKey: ['worklist', filters],
  queryFn: () => worklistApi.getWorklist(filters)
})
```

**What happens:**
- Component mounts
- React Query triggers the API call
- Filters are passed as query parameters

---

### 2️⃣ **API Service Layer - Making the HTTP Request**
**File:** `frontend/src/services/api.ts`

```typescript
export const worklistApi = {
  getWorklist: async (filters: any) => {
    const response = await api.get('/worklist', { params: filters })
    return response.data
  }
}
```

**HTTP Request:**
```
GET http://localhost:5000/api/worklist?searchTerm=&modality=&status=&page=1&pageSize=20
Headers:
  - Authorization: Bearer <JWT_TOKEN>
  - Content-Type: application/json
```

---

### 3️⃣ **Backend - API Controller Receives Request**
**File:** `backend/PACS.API/Controllers/WorklistController.cs`

```csharp
[HttpGet]
public async Task<ActionResult> GetWorklist([FromQuery] WorklistFilterDto filter)
{
    // Calls the service layer
    var (studies, totalCount) = await _studyService.GetWorklistAsync(filter);

    // Returns formatted response
    return Ok(new
    {
        studies,
        totalCount,
        page = filter.Page,
        pageSize = filter.PageSize,
        totalPages = (int)Math.Ceiling(totalCount / (double)filter.PageSize)
    });
}
```

**What happens:**
- ASP.NET Core maps query parameters to `WorklistFilterDto`
- JWT token is validated (user must be authenticated)
- Controller calls the service layer

---

### 4️⃣ **Service Layer - Business Logic**
**File:** `backend/PACS.Infrastructure/Services/StudyService.cs`

```csharp
public async Task<(List<StudyDto> Studies, int TotalCount)> GetWorklistAsync(WorklistFilterDto filter)
{
    // Start with base query - includes related data
    var query = _context.Studies
        .Include(s => s.Patient)              // Join with Patients table
        .Include(s => s.AssignedRadiologist)  // Join with Users table
        .Include(s => s.Series)               // Join with Series table
        .ThenInclude(sr => sr.Instances)      // Join with Instances table
        .AsQueryable();

    // Apply filters dynamically
    if (!string.IsNullOrEmpty(filter.SearchTerm))
    {
        query = query.Where(s =>
            s.Patient.FirstName.Contains(filter.SearchTerm) ||
            s.Patient.LastName.Contains(filter.SearchTerm) ||
            s.Patient.MRN.Contains(filter.SearchTerm));
    }

    if (!string.IsNullOrEmpty(filter.Modality))
        query = query.Where(s => s.Modality == filter.Modality);

    if (!string.IsNullOrEmpty(filter.Status))
        query = query.Where(s => s.Status == filter.Status);

    // Get total count for pagination
    var totalCount = await query.CountAsync();

    // Apply sorting and pagination
    var studies = await query
        .OrderByDescending(s => s.IsPriority)  // Priority studies first
        .ThenByDescending(s => s.StudyDate)    // Then by date
        .Skip((filter.Page - 1) * filter.PageSize)
        .Take(filter.PageSize)
        .Select(s => new StudyDto(...))        // Map to DTO
        .ToListAsync();

    return (studies, totalCount);
}
```

---

### 5️⃣ **Database Query - Entity Framework Generates SQL**

Entity Framework converts the LINQ query to SQL:

```sql
SELECT 
    s.StudyId,
    s.StudyInstanceUID,
    s.StudyDate,
    s.Modality,
    s.Description,
    s.Status,
    s.IsPriority,
    p.FirstName,
    p.LastName,
    p.MRN,
    u.FirstName AS RadFirstName,
    u.LastName AS RadLastName,
    COUNT(ser.SeriesId) AS SeriesCount
FROM Studies s
INNER JOIN Patients p ON s.PatientId = p.PatientId
LEFT JOIN Users u ON s.AssignedRadiologistId = u.UserId
LEFT JOIN Series ser ON s.StudyId = ser.StudyId
WHERE 
    s.Status = 'Pending'  -- If status filter applied
    AND s.Modality = 'CT' -- If modality filter applied
    AND (p.FirstName LIKE '%search%' OR p.LastName LIKE '%search%') -- If search applied
GROUP BY s.StudyId, s.StudyInstanceUID, ... (all selected columns)
ORDER BY 
    s.IsPriority DESC,
    s.StudyDate DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY  -- Pagination
```

---

### 6️⃣ **Database Tables Involved**

```
┌─────────────┐
│   Studies   │ ← Main table
├─────────────┤
│ StudyId     │
│ PatientId   │ ──┐
│ Status      │   │
│ Modality    │   │
│ IsPriority  │   │
│ StudyDate   │   │
└─────────────┘   │
                  │
        ┌─────────┴──────────┐
        │                    │
┌───────▼──────┐    ┌────────▼────────┐
│   Patients   │    │     Series      │
├──────────────┤    ├─────────────────┤
│ PatientId    │    │ SeriesId        │
│ FirstName    │    │ StudyId         │
│ LastName     │    │ Modality        │
│ MRN          │    │ SeriesNumber    │
└──────────────┘    └─────────────────┘
                            │
                    ┌───────▼──────────┐
                    │   Instances      │
                    ├──────────────────┤
                    │ InstanceId       │
                    │ SeriesId         │
                    │ SOPInstanceUID   │
                    └──────────────────┘
```

---

### 7️⃣ **Response Journey Back to Frontend**

**Backend Response (JSON):**
```json
{
  "studies": [
    {
      "studyId": 1,
      "studyInstanceUID": "1.2.840.113619.2.55.3...",
      "patientName": "Doe, John",
      "mrn": "MRN001",
      "studyDate": "2024-02-19T10:30:00Z",
      "modality": "CT",
      "description": "CT Chest with Contrast",
      "accessionNumber": "ACC001",
      "status": "Pending",
      "isPriority": true,
      "assignedRadiologist": null,
      "seriesCount": 3,
      "instanceCount": 0
    }
  ],
  "totalCount": 45,
  "page": 1,
  "pageSize": 20,
  "totalPages": 3
}
```

**Frontend Receives & Renders:**
```typescript
// React Query caches the data
data?.studies?.map((study: any) => (
  <tr key={study.studyId}>
    <td>{study.patientName}</td>
    <td>{format(new Date(study.studyDate), 'MMM dd, yyyy')}</td>
    <td>{study.modality}</td>
    <td><StatusBadge status={study.status} /></td>
    <td>
      <button onClick={() => navigate(`/viewer/${study.studyId}`)}>
        View
      </button>
    </td>
  </tr>
))
```

---

## 🔄 How Data Gets INTO the Database

### Option 1: Orthanc Webhook (Automatic)
```
DICOM Image Uploaded to Orthanc
         ↓
Orthanc triggers webhook
         ↓
POST /api/orthanc/webhook
         ↓
OrthancWebhookController receives data
         ↓
Creates/Updates: Patient → Study → Series → Instances
         ↓
Data saved to SQL Server
```

### Option 2: Manual SQL Insert
```sql
-- Insert sample data
INSERT INTO Patients (MRN, FirstName, LastName, DateOfBirth, Gender)
VALUES ('MRN001', 'John', 'Doe', '1980-01-01', 'M');

INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Status)
VALUES ('1.2.840...', 1, GETDATE(), 'CT', 'Pending');
```

---

## 🎯 Key Features of the Worklist

### 1. **Filtering**
- Search by patient name or MRN
- Filter by modality (CT, MRI, X-Ray, etc.)
- Filter by status (Pending, InProgress, Reported)

### 2. **Pagination**
- Shows 20 studies per page
- Calculates total pages
- Previous/Next navigation

### 3. **Sorting**
- Priority studies appear first (red triangle icon)
- Then sorted by study date (newest first)

### 4. **Actions**
- **View**: Opens OHIF viewer to see DICOM images
- **Report**: Opens reporting page to write findings
- **Print**: Downloads PDF report (only for reported studies)

---

## 🔐 Security

1. **JWT Authentication**: All requests require valid token
2. **Role-Based Access**: Only Admin/Radiologist can assign studies
3. **Audit Logging**: All actions are logged with user ID and IP

---

## 📊 Performance Optimizations

1. **Eager Loading**: Uses `.Include()` to avoid N+1 queries
2. **Pagination**: Only loads 20 records at a time
3. **React Query Caching**: Prevents unnecessary API calls
4. **Indexed Columns**: Database indexes on StudyDate, Status, Modality

---

## 🐛 Troubleshooting

**No data showing?**
1. Check if studies exist: `SELECT * FROM Studies`
2. Check API response in browser DevTools Network tab
3. Check backend logs: `docker logs pacs-api`

**Filters not working?**
1. Verify filter values match database exactly (case-sensitive)
2. Check SQL query in backend logs

**Slow loading?**
1. Check database indexes
2. Reduce pageSize
3. Add database query logging
