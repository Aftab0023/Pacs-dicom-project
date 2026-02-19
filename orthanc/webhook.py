import orthanc
import json
import requests

# Fixed API URL - use correct port
API_URL = "http://pacs-api:8080/api/orthanc/webhook"

def OnChange(changeType, level, resource):
    if changeType == orthanc.ChangeType.STABLE_STUDY:
        try:
            payload = {
                "ChangeType": "StableStudy",
                "ID": resource,
                "Path": f"/studies/{resource}",
                "ResourceType": "Study",
                "Seq": 0
            }
            
            orthanc.LogWarning(f"Sending webhook for study {resource} to {API_URL}")
            response = requests.post(API_URL, json=payload, timeout=10)
            orthanc.LogWarning(f"Webhook response for study {resource}: {response.status_code}")
            
            if response.status_code == 200:
                orthanc.LogWarning(f"Successfully processed study {resource}")
            else:
                orthanc.LogError(f"Webhook failed with status {response.status_code}: {response.text}")
                
        except Exception as e:
            orthanc.LogError(f"Error sending webhook for study {resource}: {str(e)}")

orthanc.RegisterOnChangeCallback(OnChange)
orthanc.LogWarning("PACS Webhook plugin loaded successfully!")
