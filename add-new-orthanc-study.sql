-- Add the new Echocardiogram study from Orthanc to database

-- First, let's see what we have
SELECT 'Current Studies in Database:' as Info;
SELECT StudyId, StudyInstanceUID, Description, OrthancStudyId FROM Studies;

-- Add the new study (Echocardiogram)
INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
VALUES (
    '999.999.3859744',
    1, -- Use existing patient (Anonymized Patient)
    '1994-03-23',
    'US', -- Ultrasound for Echocardiogram
    'Echocardiogram',
    'ECHO001',
    'e0345e10-60e8309f-e4b53d9d-1f2a9545-e9372411',
    'Pending',
    0,
    GETUTCDATE()
);

-- Verify the addition
SELECT 'Updated Studies in Database:' as Info;
SELECT StudyId, StudyInstanceUID, Description, OrthancStudyId FROM Studies ORDER BY CreatedAt DESC;

PRINT 'New Echocardiogram study added to database!';