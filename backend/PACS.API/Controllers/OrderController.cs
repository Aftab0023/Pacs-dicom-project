using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PACS.Core.DTOs;
using PACS.Core.Interfaces;

namespace PACS.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class OrderController : ControllerBase
{
    private readonly IWorklistService _worklistService;
    private readonly ILogger<OrderController> _logger;

    public OrderController(IWorklistService worklistService, ILogger<OrderController> logger)
    {
        _worklistService = worklistService;
        _logger = logger;
    }

    [HttpGet("scheduled")]
    public async Task<ActionResult<List<OrderDto>>> GetScheduledOrders()
    {
        try
        {
            var orders = await _worklistService.GetScheduledOrdersAsync();
            return Ok(orders);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting scheduled orders");
            return StatusCode(500, "Error retrieving scheduled orders");
        }
    }

    [HttpGet("{accessionNumber}")]
    public async Task<ActionResult<OrderDto>> GetOrderByAccessionNumber(string accessionNumber)
    {
        try
        {
            var order = await _worklistService.GetOrderByAccessionNumberAsync(accessionNumber);
            if (order == null)
                return NotFound($"Order with accession number {accessionNumber} not found");

            return Ok(order);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting order {AccessionNumber}", accessionNumber);
            return StatusCode(500, "Error retrieving order");
        }
    }

    [HttpPost]
    public async Task<ActionResult<int>> CreateOrder([FromBody] CreateOrderRequest request)
    {
        try
        {
            var orderId = await _worklistService.CreateOrderAsync(request);
            return CreatedAtAction(nameof(GetOrderByAccessionNumber), 
                new { accessionNumber = request.AccessionNumber }, orderId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating order");
            return StatusCode(500, "Error creating order");
        }
    }

    [HttpPut("{orderId}/status")]
    public async Task<ActionResult> UpdateOrderStatus(int orderId, [FromBody] UpdateOrderStatusRequest request)
    {
        try
        {
            var success = await _worklistService.UpdateOrderStatusAsync(orderId, request.Status);
            if (!success)
                return NotFound($"Order {orderId} not found");

            return Ok();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating order status");
            return StatusCode(500, "Error updating order status");
        }
    }

    [HttpPost("generate-worklists")]
    public async Task<ActionResult> GenerateWorklistFiles()
    {
        try
        {
            await _worklistService.GenerateWorklistFilesAsync();
            return Ok("Worklist files generated successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating worklist files");
            return StatusCode(500, "Error generating worklist files");
        }
    }
}
