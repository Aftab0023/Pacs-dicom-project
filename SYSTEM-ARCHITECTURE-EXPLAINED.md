# 🏥 PACS System Architecture - Complete Explanation

## Overview: Two Systems Working Together

Your PACS system consists of TWO main applications:

1. **Orthanc (Port 8042)** - DICOM Server & Image Storage
2. **PACS Application (Port 3000)** - Web Interface & Workflow Management

---

## 🔷 ORTHANC (Port 8042) - The DICOM Engine

### What is Orthanc?

Orthanc is an **open-source DICOM server** - think of it as the "heart" of your PACS system. It handles all the medical imaging (DICOM) operations.

### Primary Functions

#### 1. DICOM Storage (C-STORE)
- **Receives DICOM images** from medical devices (CT scanners, MRI 