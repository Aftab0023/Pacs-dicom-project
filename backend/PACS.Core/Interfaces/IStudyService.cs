using PACS.Core.DTOs;

namespace PACS.Core.Interfaces;

public interface IStudyService
{
    Task<WorklistStatsDto> GetWorklistStatsAsync();
    Task<(List<StudyDto> Studies, int TotalCount)> GetWorklistAsync(WorklistFilterDto filter);
    Task<StudyDetailDto?> GetStudyDetailAsync(int studyId);
    Task<StudyDetailDto?> GetStudyByUIDAsync(string studyInstanceUID);
    Task<bool> AssignStudyAsync(int studyId, int radiologistId);
    Task<bool> UpdateStudyStatusAsync(int studyId, string status);
    Task<bool> SetStudyPriorityAsync(int studyId, bool isPriority);
}
