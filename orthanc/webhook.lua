-- PACS Webhook Script (Lua)
-- This script automatically sends new studies to the PACS API

local API_URL = "http://pacs-api:5000/api/orthanc/webhook"

function OnStableStudy(studyId, tags, metadata)
    print("New stable study detected: " .. studyId)

    local payload = {
        ChangeType = "StableStudy",
        ResourceType = "Study",
        ID = studyId,
        Path = "/studies/" .. studyId,
        Seq = 0
    }

    local jsonPayload = DumpJson(payload)

    -- Retry up to 3 times with a short delay
    for attempt = 1, 3 do
        local success, response = pcall(function()
            return HttpPost(API_URL, jsonPayload, {
                ["Content-Type"] = "application/json"
            })
        end)

        if success and response then
            print("Webhook sent successfully for study: " .. studyId .. " (attempt " .. attempt .. ")")
            return
        else
            print("Webhook attempt " .. attempt .. " failed for study: " .. studyId .. ", retrying in 5s...")
            if attempt < 3 then
                os.execute("sleep 5")
            end
        end
    end

    print("All webhook attempts failed for study: " .. studyId)
end

print("PACS Lua Webhook loaded successfully!")
