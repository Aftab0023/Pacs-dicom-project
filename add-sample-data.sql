-- Add Sample Patients and Studies for Testing

-- Patient 2: John Smith
INSERT INTO Patients (MRN, FirstName, LastName, DateOfBirth, Gender, CreatedAt)
VALUES ('12345', 'John', 'Smith', '1980-05-15', 'M', GETUTCDATE());

DECLARE @Patient2Id INT = SCOPE_IDENTITY();

-- Patient 3: Sarah Johnson  
INSERT INTO Patients (MRN, FirstName, LastName, DateOfBirth, Gender, CreatedAt)
VALUES ('67890', 'Sarah', 'Johnson', '1975-08-22', 'F', GETUTCDATE());

DECLARE @Patient3Id INT = SCOPE_IDENTITY();

-- Patient 4: Michael Brown
INSERT INTO Patients (MRN, FirstName, LastName, DateOfBirth, Gender, CreatedAt)
VALUES ('11111', 'Michael', 'Brown', '1990-12-03', 'M', GETUTCDATE());

DECLARE @Patient4Id INT = SCOPE_IDENTITY();

-- Patient 5: Emily Davis
INSERT INTO Patients (MRN, FirstName, LastName, DateOfBirth, Gender, CreatedAt)
VALUES ('22222', 'Emily', 'Davis', '1985-03-18', 'F', GETUTCDATE());

DECLARE @Patient5Id INT = SCOPE_IDENTITY();

-- Study 2: John Smith - Chest X-Ray
INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
VALUES (
    '1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.20',
    @Patient2Id,
    '2026-02-16',
    'XR',
    'Chest X-Ray PA and Lateral',
    'ACC001',
    'sample-study-001',
    'Pending',
    0,
    GETUTCDATE()
);

-- Study 3: Sarah Johnson - Brain MRI (Priority)
INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
VALUES (
    '1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.21',
    @Patient3Id,
    '2026-02-17',
    'MR',
    'Brain MRI with and without contrast',
    'ACC002',
    'sample-study-002',
    'InProgress',
    1,
    GETUTCDATE()
);

-- Study 4: Michael Brown - Abdominal CT
INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
VALUES (
    '1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.22',
    @Patient4Id,
    '2026-02-15',
    'CT',
    'Abdomen and Pelvis CT with IV contrast',
    'ACC003',
    'sample-study-003',
    'Reported',
    0,
    GETUTCDATE()
);

-- Study 5: Emily Davis - Ultrasound
INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
VALUES (
    '1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.23',
    @Patient5Id,
    '2026-02-17',
    'US',
    'Pelvic Ultrasound',
    'ACC004',
    'sample-study-004',
    'Pending',
    0,
    GETUTCDATE()
);

-- Study 6: John Smith - Follow-up CT (Priority)
INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
VALUES (
    '1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.24',
    @Patient2Id,
    '2026-02-17',
    'CT',
    'Chest CT Follow-up',
    'ACC005',
    'sample-study-005',
    'Pending',
    1,
    GETUTCDATE()
);

-- Add some sample series for the studies (optional - for more realistic data)
INSERT INTO Series (SeriesInstanceUID, StudyId, Modality, BodyPart, SeriesNumber, Description, CreatedAt)
SELECT 
    '1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.100.' + CAST(StudyId as VARCHAR),
    StudyId,
    Modality,
    CASE 
        WHEN Modality = 'XR' THEN 'Chest'
        WHEN Modality = 'MR' THEN 'Brain'
        WHEN Modality = 'CT' AND Description LIKE '%Chest%' THEN 'Chest'
        WHEN Modality = 'CT' AND Description LIKE '%Abdomen%' THEN 'Abdomen'
        WHEN Modality = 'US' THEN 'Pelvis'
        ELSE 'Unknown'
    END,
    1,
    Description,
    GETUTCDATE()
FROM Studies WHERE StudyId > 1;

-- Verify the data
SELECT 
    s.StudyId,
    p.FirstName + ' ' + p.LastName AS PatientName,
    p.MRN,
    s.StudyDate,
    s.Modality,
    s.Description,
    s.Status,
    CASE WHEN s.IsPriority = 1 THEN 'Yes' ELSE 'No' END AS Priority
FROM Studies s
INNER JOIN Patients p ON s.PatientId = p.PatientId
ORDER BY s.StudyDate DESC, s.IsPriority DESC;

PRINT 'Sample data added successfully!';
PRINT 'Total Studies: ' + CAST((SELECT COUNT(*) FROM Studies) AS VARCHAR);
PRINT 'Total Patients: ' + CAST((SELECT COUNT(*) FROM Patients) AS VARCHAR);