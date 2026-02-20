using PACS.Core.DTOs;

namespace PACS.Core.Interfaces;

public interface IWorklistService
{
    Task<List<OrderDto>> GetScheduledOrdersAsync();
    Task<OrderDto?> GetOrderByAccessionNumberAsync(string accessionNumber);
    Task<int> CreateOrderAsync(CreateOrderRequest request);
    Task<bool> UpdateOrderStatusAsync(int orderId, string status);
    Task GenerateWorklistFilesAsync();
    Task<string> GenerateWorklistFileForOrderAsync(int orderId);
}
