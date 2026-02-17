# 🚀 Quick Start - Test PACS Image Viewing

## Step-by-Step (5 Minutes)

### 1️⃣ Get Sample DICOM Files

**Download from:** https://www.dicomlibrary.com/

- Click any study (CT, MR, or X-Ray)
- Click "Download" button
- Extract the ZIP file

### 2️⃣ Upload to Orthanc

1. Open: **http://localhost:8042**
2. Login: `orthanc` / `orthanc`
3. Click **"Upload"** button (top right)
4. Select all .dcm files from extracted folder
5. Click **"Start Upload"**
6. Wait for "Upload Complete"

### 3️⃣ View in PACS

1. Open: **http://localhost:3000**
2. Login: `admin@pacs.local` / `Admin123!`
3. Click **"Worklist"** in navigation
4. Wait 10 seconds (for processing)
5. Refresh page if needed
6. You should see your study!

### 4️⃣ View Images

**Option A: Study Viewer**
- Click **"View"** button on the study
- See patient info and series list

**Option B: OHIF Viewer**
- Click **"Open in OHIF Viewer"** button
- Images will load in the viewer
- Use mouse to scroll through slices

### 5️⃣ Create Report

1. Click **"Report"** button
2. Fill in:
   - Clinical History
   - Findings
   - Impression
3. Click **"Save Draft"** or **"Finalize Report"**

---

## 🎯 Expected Results

✅ Study appears in Worklist within 10 seconds
✅ Patient name and study info displayed
✅ Images load in OHIF viewer
✅ Can scroll through slices
✅ Can create and save report

---

## ⚠️ If Something Goes Wrong

**Study not in Worklist?**
```powershell
# Check Orthanc has the study
curl http://localhost:8042/studies

# Check API logs
docker logs pacs-api --tail 20

# Restart API
docker restart pacs-api
```

**Images not loading?**
- Check Orthanc is running: http://localhost:8042
- Check browser console (F12) for errors
- Try refreshing the page

**Need help?**
- See TESTING-WORKFLOW.md for detailed guide
- Check docker logs: `docker-compose logs`

---

## 📦 Recommended Test Files

**Best for testing:**
1. **CT Chest** - Multiple slices, good for scrolling
2. **MRI Brain** - Multiple series
3. **X-Ray** - Simple, single image

**Where to get:**
- https://www.dicomlibrary.com/ (FREE)
- https://www.rubomedical.com/dicom_files/ (FREE)
- https://www.osirix-viewer.com/resources/dicom-image-library/ (FREE)

---

## 🎉 You're Ready!

Start with Step 1 - Download sample DICOM files and let's test the system!
