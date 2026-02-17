# PACS Testing Workflow Guide

## ✅ Step 1: Login (COMPLETED)
You've successfully logged in at http://localhost:3000

---

## 📤 Step 2: Upload DICOM Images to Orthanc

You need DICOM test images to view. Here are your options:

### Option A: Upload via Orthanc Web Interface (EASIEST)

1. **Open Orthanc Web Interface**
   - Go to: http://localhost:8042
   - Login with:
     - Username: `orthanc`
     - Password: `orthanc`

2. **Upload DICOM Files**
   - Click the **"Upload"** button (top right)
   - Select DICOM files from your computer (.dcm files)
   - Click "Start Upload"
   - Wait for upload to complete

3. **Verify Upload**
   - You should see the study appear in Orthanc's study list
   - The study will show patient name, date, modality

### Option B: Download Free Sample DICOM Files

If you don't have DICOM files, download samples from:

**Recommended Sources:**
1. **DICOM Library** - https://www.dicomlibrary.com/
   - Free sample CT, MR, X-Ray images
   - Click "Download" on any study

2. **Rubo Medical Imaging** - https://www.rubomedical.com/dicom_files/
   - Various modalities available
   - Direct download links

3. **OsiriX Sample Data** - https://www.osirix-viewer.com/resources/dicom-image-library/
   - High-quality sample studies

**After downloading:**
- Extract the ZIP file
- Upload the .dcm files via Orthanc (Option A above)

### Option C: Use DICOM Send Tool (ADVANCED)

If you have dcm4che or similar DICOM tools:

```bash
storescu -c ORTHANC@localhost:4242 /path/to/dicom/folder
```

---

## 🔄 Step 3: Wait for Study to Appear in Worklist

After uploading to Orthanc:

1. **Automatic Processing**
   - Orthanc triggers a webhook to the PACS API
   - API extracts metadata and stores in database
   - This takes 5-10 seconds

2. **Check the Worklist**
   - Go to http://localhost:3000
   - Click **"Worklist"** in the navigation
   - You should see your uploaded study

3. **Study Information Displayed**
   - Patient Name
   - MRN (Medical Record Number)
   - Study Date
   - Modality (CT, MR, XR, etc.)
   - Description
   - Status (Pending)

---

## 👁️ Step 4: View Images

### Method 1: Quick View from Worklist

1. In the Worklist, find your study
2. Click the **"View"** button
3. You'll see:
   - Patient demographics
   - Study information
   - List of series
   - Number of images per series

### Method 2: Open in OHIF Viewer

1. From the Study Viewer page, click **"Open in OHIF Viewer"**
2. Or click the button that launches the viewer
3. OHIF will open and display your DICOM images

**OHIF Viewer Features:**
- Multi-series viewing
- Window/Level adjustment
- Zoom and pan
- Measurements
- Annotations
- MPR (Multi-Planar Reconstruction) if 3D data

---

## 📝 Step 5: Create a Report

1. **From Worklist**
   - Click **"Report"** button on any study

2. **Or from Study Viewer**
   - Click **"Create Report"** button

3. **Fill in Report**
   - Clinical History/Indication
   - Findings (detailed observations)
   - Impression (conclusion)

4. **Save Options**
   - **Save Draft** - Save and continue editing later
   - **Finalize Report** - Lock the report (cannot edit)

5. **Download PDF**
   - After finalizing, download the report as PDF

---

## 🎯 Complete Workflow Test

### Full End-to-End Test:

1. ✅ **Login** - http://localhost:3000
2. 📤 **Upload DICOM** - http://localhost:8042
3. ⏳ **Wait 10 seconds** for processing
4. 📋 **Check Worklist** - Should see study
5. 👁️ **View Images** - Click "View" button
6. 🖼️ **Open OHIF** - Launch viewer
7. 📝 **Create Report** - Fill in findings
8. ✅ **Finalize** - Complete the report
9. 📄 **Download PDF** - Get the report

---

## 🔍 Troubleshooting

### Study Not Appearing in Worklist?

**Check Orthanc:**
```powershell
# Check if study is in Orthanc
curl http://localhost:8042/studies
```

**Check API Logs:**
```powershell
docker logs pacs-api --tail 50
```

**Check Database:**
```powershell
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -d PACSDB -Q "SELECT * FROM Studies"
```

### Images Not Loading in OHIF?

1. **Check DICOMweb URL**
   - Should be: http://localhost:8042/dicom-web

2. **Check Orthanc DICOMweb Plugin**
   - Go to http://localhost:8042
   - Check if DICOMweb is enabled

3. **Check Browser Console**
   - Press F12 in browser
   - Look for errors in Console tab

### Webhook Not Triggering?

**Check Orthanc Configuration:**
```powershell
docker exec pacs-orthanc cat /etc/orthanc/orthanc.json | Select-String -Pattern "Python"
```

**Restart Orthanc:**
```powershell
docker restart pacs-orthanc
```

---

## 📊 Test Data Recommendations

For best testing experience, use:

1. **CT Scan** - Shows multiple slices, good for scrolling
2. **MRI Study** - Multiple series, different sequences
3. **X-Ray** - Simple, single image
4. **Ultrasound** - Video/cine mode

**Recommended Test Study:**
- CT Chest or CT Abdomen
- 100-300 slices
- Multiple series
- Good for testing performance

---

## 🎓 Next Steps After Testing

Once you've verified the workflow works:

1. **Configure Modalities**
   - Add your actual CT/MR scanners
   - Configure DICOM AE titles

2. **Add More Users**
   - Create radiologist accounts
   - Set up referring physicians

3. **Customize Worklist**
   - Add custom filters
   - Configure hanging protocols

4. **Set Up Backup**
   - Configure database backups
   - Set up DICOM storage backup

5. **Production Deployment**
   - See DEPLOYMENT.md for production setup
   - Configure HTTPS
   - Set up monitoring

---

## 📞 Quick Reference

| Service | URL | Credentials |
|---------|-----|-------------|
| **PACS Frontend** | http://localhost:3000 | admin@pacs.local / Admin123! |
| **Orthanc Upload** | http://localhost:8042 | orthanc / orthanc |
| **API Swagger** | http://localhost:5000/swagger | Use JWT from login |

---

## ✨ Tips

1. **Use Chrome or Edge** - Best browser compatibility
2. **Upload Small Studies First** - Test with 10-20 images
3. **Check Logs** - If something fails, check docker logs
4. **Refresh Worklist** - Click refresh if study doesn't appear
5. **Wait for Processing** - Give it 10 seconds after upload

---

**Ready to test? Start with Step 2 - Upload DICOM Images!**
