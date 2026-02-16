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
    public async Task<ActionResult> HandleWebhook([FromBody] OrthancWebhookPayload payload)
    {
        _logger.LogInformation($"Received Orthanc webhook: {payload.ChangeType} - {payload.ResourceType} - {payload.ID}");

        try
        {
            if (payload.ChangeType == "StableStudy" && payload.ResourceType == "Study")
            {
                await _orthancService.ProcessNewStudyAsync(payload.ID);
                _logger.LogInformation($"Successfully processed study: {payload.ID}");
            }

            return Ok();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error processing webhook for study: {payload.ID}");
            return StatusCode(500, new { message = "Error processing webhook" });
        }
    }

    [HttpGet("dicomweb/{studyInstanceUID}")]
    public async Task<ActionResult> GetDicomWebUrl(string studyInstanceUID)
    {
        var url = await _orthancService.GetDicomWebUrlAsync(studyInstanceUID);
        return Ok(new { url });
    }
}
