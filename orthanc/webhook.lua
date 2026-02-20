-- PACS Webhook Script (Lua)
-- This script automatically sends new studies to the PACS API

local API_URL = "http://pacs-api:8080/api/orthanc/webhook"

function OnStableStudy(studyId, tags, metadata)
    print("New stable study detected: " .. studyId)
    
    -- Create webhook payload matching the C# DTO structure
    local payload = {
        ChangeType = "StableStudy",
        ResourceType = "Study",
        ID = studyId,
        Path = "/studies/" .. studyId,
        Seq = 0
    }
    
    -- Convert payload to JSON
    local jsonPayload = DumpJson(payload)
    
    -- Send HTTP POST request to PACS API
    local response = HttpPost(API_URL, jsonPayload, {
        ["Content-Type"] = "application/json"
    })
    
    if response then
        print("Webhook sent successfully for study: " .. studyId)
        print("Response: " .. response)
    else
        print("Failed to send webhook for study: " .. studyId)
    end
end

print("PACS Lua Webhook loaded successfully!")