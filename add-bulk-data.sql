-- Generate Bulk Test Data for PACS Worklist

DECLARE @i INT = 1;
DECLARE @patientCount INT = 15;
DECLARE @studyCount INT = 30;

-- Generate 15 test patients
WHILE @i <= @patientCount
BEGIN
    INSERT INTO Patients (MRN, FirstName, LastName, DateOfBirth, Gender, CreatedAt)
    VALUES (
        'MRN' + RIGHT('00000' + CAST(@i + 100 AS VARCHAR), 5),
        CASE (@i % 10)
            WHEN 0 THEN 'James'
            WHEN 1 THEN 'Mary'
            WHEN 2 THEN 'John'
            WHEN 3 THEN 'Patricia'
            WHEN 4 THEN 'Robert'
            WHEN 5 THEN 'Jennifer'
            WHEN 6 THEN 'Michael'
            WHEN 7 THEN 'Linda'
            WHEN 8 THEN 'William'
            ELSE 'Elizabeth'
        END,
        CASE (@i % 8)
            WHEN 0 THEN 'Smith'
            WHEN 1 THEN 'Johnson'
            WHEN 2 THEN 'Williams'
            WHEN 3 THEN 'Brown'
            WHEN 4 THEN 'Jones'
            WHEN 5 THEN 'Garcia'
            WHEN 6 THEN 'Miller'
            ELSE 'Davis'
        END,
        DATEADD(YEAR, -(@i + 20), GETDATE()),
        CASE (@i % 2) WHEN 0 THEN 'M' ELSE 'F' END,
        GETUTCDATE()
    );
    SET @i = @i + 1;
END

-- Generate 30 test studies
SET @i = 1;
WHILE @i <= @studyCount
BEGIN
    DECLARE @patientId INT = ((@i - 1) % @patientCount) + 6; -- Start from patient 6
    
    INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
    VALUES (
        '1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.' + CAST((200 + @i) AS VARCHAR),
        @patientId,
        DATEADD(DAY, -(@i % 30), GETDATE()),
        CASE (@i % 5)
            WHEN 0 THEN 'CT'
            WHEN 1 THEN 'MR'
            WHEN 2 THEN 'XR'
            WHEN 3 THEN 'US'
            ELSE 'CR'
        END,
        CASE (@i % 10)
            WHEN 0 THEN 'Chest CT with contrast'
            WHEN 1 THEN 'Brain MRI'
            WHEN 2 THEN 'Chest X-Ray'
            WHEN 3 THEN 'Abdominal Ultrasound'
            WHEN 4 THEN 'Lumbar Spine MRI'
            WHEN 5 THEN 'Pelvis CT'
            WHEN 6 THEN 'Knee X-Ray'
            WHEN 7 THEN 'Cardiac Echo'
            WHEN 8 THEN 'Head CT'
            ELSE 'Mammography'
        END,
        'ACC' + RIGHT('0000' + CAST(@i + 100 AS VARCHAR), 4),
        'bulk-study-' + RIGHT('000' + CAST(@i AS VARCHAR), 3),
        CASE (@i % 4)
            WHEN 0 THEN 'Pending'
            WHEN 1 THEN 'InProgress'
            WHEN 2 THEN 'Reported'
            ELSE 'Pending'
        END,
        CASE WHEN (@i % 8) = 0 THEN 1 ELSE 0 END,
        GETUTCDATE()
    );
    SET @i = @i + 1;
END

-- Show summary
SELECT 'Total Studies' AS Summary, COUNT(*) AS Count FROM Studies
UNION ALL
SELECT 'Total Patients', COUNT(*) FROM Patients
UNION ALL  
SELECT 'Priority Studies', COUNT(*) FROM Studies WHERE IsPriority = 1;

PRINT 'Bulk test data added successfully!';