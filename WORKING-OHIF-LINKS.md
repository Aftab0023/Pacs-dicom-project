# 🎯 Working OHIF Viewer Links

You have **3 real DICOM studies** in Orthanc that will work with OHIF viewer:

## ✅ Study 1: Original CT Study (KUNAS)
- **Date**: 2015-12-07
- **OHIF Link**: http://localhost:8042/ohif/viewer?StudyInstanceUIDs=1.3.6.1.4.1.44316.6.102.1.20250704114423696.6115867211953577193
- **Status**: ✅ Working (this is your original study)

## ✅ Study 2: CT Study from 2010
- **Date**: 2010-08-06  
- **OHIF Link**: http://localhost:8042/ohif/viewer?StudyInstanceUIDs=1.3.6.1.4.1.5962.99.1.1761388472.1291962045.1616669124536.2592.0
- **Status**: ✅ Should work (has real DICOM data)

## ✅ Study 3: Study from 1994
- **Date**: 1994-10-13
- **OHIF Link**: http://localhost:8042/ohif/viewer?StudyInstanceUIDs=1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6
- **Status**: ✅ Should work (has real DICOM data)

## 🔧 How to Test

### Method 1: Direct Links (Easiest)
Click any of the OHIF links above. Login with `orthanc` / `orthanc` when prompted.

### Method 2: Via Worklist (Realistic)
The problem is that your worklist shows the **database studies** (which don't have DICOM files), not the **Orthanc studies** (which do have DICOM files).

## 🚨 The Core Issue

**Database Studies** ≠ **Orthanc Studies**

- **Database**: 6 studies (5 fake + 1 real)
- **Orthanc**: 3 studies (all real with DICOM files)

Only studies that exist in **both** database and Orthanc will work properly.

## 🔧 Solutions

### Solution A: Update Database with Real Orthanc Studies
Let me sync the database with the actual Orthanc studies:

```sql
-- Clear fake studies (keep only the real ones)
DELETE FROM Studies WHERE OrthancStudyId LIKE 'sample-study-%' OR OrthancStudyId LIKE 'bulk-study-%';

-- Add the 2 new real studies from Orthanc
INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
VALUES 
(
    '1.3.6.1.4.1.5962.99.1.1761388472.1291962045.1616669124536.2592.0',
    1, -- Use existing patient
    '2010-08-06',
    'CT',
    'CT Study 2010',
    'REAL001',
    '750255f1-a6d57cdf-6f7692af-b6eb20e8-76b2cd54',
    'Pending',
    0,
    GETUTCDATE()
),
(
    '1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6',
    1, -- Use existing patient  
    '1994-10-13',
    'CT',
    'CT Study 1994',
    'REAL002',
    'aa938400-09e9f0df-8ba95f68-e21f98dd-0c6e0cf0',
    'Pending',
    0,
    GETUTCDATE()
);
```

### Solution B: Upload More DICOM Files
Upload real DICOM files to Orthanc, then the webhook will add them to the database automatically.

## 🎯 Quick Test Right Now

**Try this working link:**
http://localhost:8042/ohif/viewer?StudyInstanceUIDs=1.3.6.1.4.1.44316.6.102.1.20250704114423696.6115867211953577193

Login: `orthanc` / `orthanc`

This should load the DICOM images successfully! 🎉

## 📋 Next Steps

1. **Test the working OHIF link above**
2. **Clean up fake database studies** 
3. **Upload more real DICOM files**
4. **Fix the webhook** to automatically sync new uploads

The core system is working - you just need real DICOM data instead of fake database entries!