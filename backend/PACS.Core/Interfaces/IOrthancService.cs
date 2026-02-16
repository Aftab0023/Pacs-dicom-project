using PACS.Core.DTOs;

namespace PACS.Core.Interfaces;

public interface IOrthancService
{
    Task<OrthancStudyMetadata?> GetStudyMetadataAsync(string orthancStudyId);
    Task<OrthancPatientMetadata?> GetPatientMetadataAsync(string orthancPatientId);
    Task ProcessNewStudyAsync(string orthancStudyId);
    Task<string> GetDicomWebUrlAsync(string studyInstanceUID);
}
