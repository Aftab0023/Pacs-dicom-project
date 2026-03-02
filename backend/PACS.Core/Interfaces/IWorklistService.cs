using PACS.Core.DTOs;
using PACS.Core.Entities;

namespace PACS.Core.Interfaces;

public interface IWorklistService
{
    Task<WorklistEntryResponse> CreateWorklistEntryAsync(CreateWorklistEntryRequest request, int createdBy);
    Task<WorklistEntryResponse?> GetWorklistEntryAsync(int worklistId);
    Task<WorklistEntryResponse?> GetWorklistEntryByAccessionAsync(string accessionNumber);
    Task<List<WorklistEntryResponse>> QueryWorklistEntriesAsync(WorklistQueryRequest request);
    Task<WorklistEntryResponse?> UpdateWorklistEntryAsync(int worklistId, UpdateWorklistEntryRequest request);
    Task<WorklistEntryResponse?> UpdateWorklistStatusAsync(int worklistId, string status);
    Task<bool> DeleteWorklistEntryAsync(int worklistId);
    Task<bool> LinkStudyToWorklistAsync(string accessionNumber, string studyInstanceUID);
    Task GenerateWorklistFilesAsync(); // For Orthanc MWL plugin
}
