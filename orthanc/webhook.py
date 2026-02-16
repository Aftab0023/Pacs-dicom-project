import orthanc
import json
import requests

API_URL = "http://pacs-api:80/api/orthanc/webhook"

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
            
            response = requests.post(API_URL, json=payload, timeout=10)
            orthanc.LogWarning(f"Webhook sent for study {resource}: {response.status_code}")
        except Exception as e:
            orthanc.LogError(f"Error sending webhook: {str(e)}")

orthanc.RegisterOnChangeCallback(OnChange)
