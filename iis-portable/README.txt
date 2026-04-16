================================================================
  PACS Orthanc Portable
  Windows 10 / Server 2016 / 2019 / 2022
================================================================

STEP 1 — Copy OrthancPortable to E:\
--------------------------------------
  Your E:\ drive must have this structure:

  E:\OrthancPortable\
      OrthancServer\
          Orthanc.exe
          Plugins\
              OrthancDicomWeb.dll
              OrthancExplorer2.dll
              OrthancGdcm.dll
              OsimisWebViewer.dll
              (any other .dll plugins)

  Data folders are created automatically on first run:
  E:\OrthancPortable\OrthancData\
      Database\     ← DICOM files stored here
      worklists\    ← DICOM worklist files
      cache\        ← viewer cache
      OrthancLog.txt

STEP 2 — Run
--------------------------------------
  OPTION A: Run manually (shows live logs)
    Right-click Start-Orthanc.ps1
    → "Run with PowerShell"

  OPTION B: Install as Windows Service (auto-starts on boot)
    Right-click Install-Service.ps1
    → "Run as Administrator"

STEP 3 — Access
--------------------------------------
  Orthanc Web UI : http://localhost:8042
  OHIF Viewer    : http://localhost:8042/ohif/
  DICOM port     : 4242

  Login: orthanc / orthanc
         admin   / admin

CHANGE API URL
--------------------------------------
  If your PACS API is on a different IP, edit:
  orthanc\webhook.lua  →  line 4
  Change: local API_URL = "http://YOUR_IP:5000/api/orthanc/webhook"

STOP ORTHANC
--------------------------------------
  Right-click Stop-Orthanc.ps1 → Run with PowerShell

REMOVE SERVICE
--------------------------------------
  Right-click Uninstall-Service.ps1 → Run as Administrator

================================================================
