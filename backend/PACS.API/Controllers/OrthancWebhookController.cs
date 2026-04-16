using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;

namespace PACS.API.Controllers;

[ApiController]
[Route("api/orthanc")]
public class OrthancWebhookController : ControllerBase
{
    private readonly IOrthancService _orthancService;
    private readonly ILogger<OrthancWebhookController> _logger;

    public OrthancWebhookController(IOrthancService orthancService, ILogger<OrthancWebhookController> logger)
    {
        _orthancService = orthancService;
        _logger = logger;
    }

    [HttpPost("webhook")]
    [AllowAnonymous]
    public ActionResult HandleWebhook([FromBody] OrthancWebhookPayload payload)
    {
        _logger.LogInformation("Received webhook: {Type} - {ResourceType} - {ID}",
            payload.ChangeType, payload.ResourceType, payload.ID);

        if (payload.ChangeType == "StableStudy" && payload.ResourceType == "Study")
        {
            // Fire and forget — respond to Orthanc instantly, process in background
            _ = Task.Run(async () =>
            {
                try
                {
                    await _orthancService.ProcessNewStudyAsync(payload.ID);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Background processing failed for study: {ID}", payload.ID);
                }
            });
        }

        return Ok(); // Orthanc gets response in <1ms
    }

    [HttpGet("dicomweb/{studyInstanceUID}")]
    [Authorize]
    public async Task<ActionResult> GetDicomWebUrl(string studyInstanceUID)
    {
        var url = await _orthancService.GetDicomWebUrlAsync(studyInstanceUID);
        return Ok(new { url });
    }
}
