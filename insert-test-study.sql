-- Insert test patient
INSERT INTO Patients (MRN, FirstName, LastName, DateOfBirth, Gender, CreatedAt)
VALUES ('0', 'Anonymized', 'Patient', '1990-01-01', 'M', GETUTCDATE());

-- Get the patient ID
DECLARE @PatientId INT = SCOPE_IDENTITY();

-- Insert test study
INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
VALUES (
    '1.3.6.1.4.1.44316.6.102.1.20250704114423696.6115867211953577193 2',
    @PatientId,
    '2015-12-07',
    'CT',
    'KUNAS',
    '',
    'a2390fab-3be3e31b-268f6c22-4eb2e70f-6e5d1726',
    'Pending',
    0,
    GETUTCDATE()
);

-- Verify
SELECT * FROM Patients WHERE MRN = '0';
SELECT * FROM Studies WHERE OrthancStudyId = 'a2390fab-3be3e31b-268f6c22-4eb2e70f-6e5d1726';
