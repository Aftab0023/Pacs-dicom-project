-- PACS Webhook Script
-- Sends new DICOM studies to the PACS API automatically
-- Change API_URL below if your server IP is different

local API_URL = "http://localhost:5000/api/orthanc/webhook"

function OnStableStudy(studyId, tags, metadata)
    print("New stable study: " .. studyId)

    local payload = DumpJson({
        ChangeType   = "StableStudy",
        ResourceType = "Study",
        ID           = studyId,
        Path         = "/studies/" .. studyId,
        Seq          = 0
    })

    for attempt = 1, 3 do
        local ok, res = pcall(function()
            return HttpPost(API_URL, payload, {
                ["Content-Type"] = "application/json"
            })
        end)
        if ok and res then
            print("Webhook OK (attempt " .. attempt .. "): " .. studyId)
            return
        end
        print("Attempt " .. attempt .. " failed, retrying in 3s...")
        if attempt < 3 then
            os.execute("timeout /t 3 /nobreak > nul")
        end
    end
    print("All webhook attempts failed for: " .. studyId)
end

print("Webhook loaded. API target: " .. API_URL)
