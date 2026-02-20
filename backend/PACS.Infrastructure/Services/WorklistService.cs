using System.Text;
using FellowOakDicom;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using PACS.Core.DTOs;
using PACS.Core.Entities;
using PACS.Core.Interfaces;
using PACS.Infrastructure.Data;

namespace PACS.Infrastructure.Services;

public class WorklistService : IWorklistService
{
    private readonly PACSDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<WorklistService> _logger;
    private readonly string _worklistPath;

    public WorklistService(PACSDbContext context, IConfiguration configuration, ILogger<WorklistService> logger)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;
        _worklistPath = configuration["Worklist:Path"] ?? "/var/lib/orthanc/worklists";
    }

    public async Task<List<OrderDto>> GetScheduledOrdersAsync()
    {
        var orders = await _context.Set<Order>()
            .Include(o => o.Patient)
            .Where(o => o.Status == "Scheduled")
            .OrderBy(o => o.ScheduledDateTime)
            .ToListAsync();

        return orders.Select(o => new OrderDto(
            o.OrderId,
            o.AccessionNumber,
            $"{o.Patient.LastName}, {o.Patient.FirstName}",
            o.Patient.MRN,
            o.OrderingPhysician,
            o.Modality,
            o.StudyDescription,
            o.ScheduledDateTime,
            o.Status,
            o.Priority
        )).ToList();
    }

    public async Task<OrderDto?> GetOrderByAccessionNumberAsync(string accessionNumber)
    {
        var order = await _context.Set<Order>()
            .Include(o => o.Patient)
            .FirstOrDefaultAsync(o => o.AccessionNumber == accessionNumber);

        if (order == null) return null;

        return new OrderDto(
            order.OrderId,
            order.AccessionNumber,
            $"{order.Patient.LastName}, {order.Patient.FirstName}",
            order.Patient.MRN,
            order.OrderingPhysician,
            order.Modality,
            order.StudyDescription,
            order.ScheduledDateTime,
            order.Status,
            order.Priority
        );
    }

    public async Task<int> CreateOrderAsync(CreateOrderRequest request)
    {
        var order = new Order
        {
            AccessionNumber = request.AccessionNumber,
            PatientId = request.PatientId,
            OrderingPhysician = request.OrderingPhysician,
            ReferringPhysician = request.ReferringPhysician,
            Modality = request.Modality,
            StudyDescription = request.StudyDescription,
            ScheduledDateTime = request.ScheduledDateTime,
            Priority = request.Priority,
            Status = "Scheduled",
            CreatedAt = DateTime.UtcNow
        };

        _context.Set<Order>().Add(order);
        await _context.SaveChangesAsync();

        // Generate worklist file for this order
        await GenerateWorklistFileForOrderAsync(order.OrderId);

        return order.OrderId;
    }

    public async Task<bool> UpdateOrderStatusAsync(int orderId, string status)
    {
        var order = await _context.Set<Order>().FindAsync(orderId);
        if (order == null) return false;

        order.Status = status;
        order.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        // Regenerate worklist files
        await GenerateWorklistFilesAsync();

        return true;
    }

    public async Task GenerateWorklistFilesAsync()
    {
        var scheduledOrders = await _context.Set<Order>()
            .Include(o => o.Patient)
            .Where(o => o.Status == "Scheduled")
            .ToListAsync();

        _logger.LogInformation($"Generating worklist files for {scheduledOrders.Count} scheduled orders");

        foreach (var order in scheduledOrders)
        {
            await GenerateWorklistFileForOrderAsync(order.OrderId);
        }
    }

    public async Task<string> GenerateWorklistFileForOrderAsync(int orderId)
    {
        var order = await _context.Set<Order>()
            .Include(o => o.Patient)
            .FirstOrDefaultAsync(o => o.OrderId == orderId);

        if (order == null)
        {
            _logger.LogWarning($"Order {orderId} not found");
            return string.Empty;
        }

        try
        {
            // Generate DICOM worklist file
            var filename = $"{order.AccessionNumber}.wl";
            var filepath = Path.Combine(_worklistPath, filename);

            // Ensure directory exists
            Directory.CreateDirectory(_worklistPath);

            // Create DICOM worklist file
            var dataset = CreateDicomWorklistDataset(order);
            var dicomFile = new DicomFile(dataset);
            await dicomFile.SaveAsync(filepath);

            _logger.LogInformation($"Generated DICOM worklist file: {filepath}");
            return filepath;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error generating worklist file for order {orderId}");
            // Fallback to text representation
            return GenerateDicomWorklistContent(order);
        }
    }

    private DicomDataset CreateDicomWorklistDataset(Order order)
    {
        var dataset = new DicomDataset();

        // Patient Information Module
        dataset.AddOrUpdate(DicomTag.PatientName, $"{order.Patient.LastName}^{order.Patient.FirstName}");
        dataset.AddOrUpdate(DicomTag.PatientID, order.Patient.MRN);
        dataset.AddOrUpdate(DicomTag.PatientBirthDate, order.Patient.DateOfBirth.ToString("yyyyMMdd"));
        dataset.AddOrUpdate(DicomTag.PatientSex, order.Patient.Gender ?? "O");

        // Scheduled Procedure Step Sequence
        var spsSequence = new DicomSequence(DicomTag.ScheduledProcedureStepSequence);
        var spsItem = new DicomDataset();

        spsItem.AddOrUpdate(DicomTag.Modality, order.Modality);
        spsItem.AddOrUpdate(DicomTag.ScheduledStationAETitle, "PACS");
        spsItem.AddOrUpdate(DicomTag.ScheduledProcedureStepStartDate, order.ScheduledDateTime.ToString("yyyyMMdd"));
        spsItem.AddOrUpdate(DicomTag.ScheduledProcedureStepStartTime, order.ScheduledDateTime.ToString("HHmmss"));
        spsItem.AddOrUpdate(DicomTag.ScheduledPerformingPhysicianName, order.OrderingPhysician);
        spsItem.AddOrUpdate(DicomTag.ScheduledProcedureStepDescription, order.StudyDescription);
        spsItem.AddOrUpdate(DicomTag.ScheduledProcedureStepID, order.AccessionNumber);

        spsSequence.Items.Add(spsItem);
        dataset.Add(spsSequence);

        // Requested Procedure Module
        dataset.AddOrUpdate(DicomTag.RequestedProcedureID, order.AccessionNumber);
        dataset.AddOrUpdate(DicomTag.RequestedProcedureDescription, order.StudyDescription);
        dataset.AddOrUpdate(DicomTag.RequestedProcedurePriority, order.Priority.ToUpper());

        // Imaging Service Request Module
        dataset.AddOrUpdate(DicomTag.AccessionNumber, order.AccessionNumber);
        dataset.AddOrUpdate(DicomTag.ReferringPhysicianName, order.ReferringPhysician);
        dataset.AddOrUpdate(DicomTag.RequestingPhysician, order.OrderingPhysician);

        // Study Instance UID (generate if not exists)
        dataset.AddOrUpdate(DicomTag.StudyInstanceUID, DicomUID.Generate().UID);

        return dataset;
    }

    private string GenerateDicomWorklistContent(Order order)
    {
        // This is a simplified representation
        // In production, you would use a DICOM library like fo-dicom to create proper DICOM files
        var sb = new StringBuilder();
        sb.AppendLine($"# DICOM Modality Worklist Item");
        sb.AppendLine($"# Generated: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss}");
        sb.AppendLine();
        sb.AppendLine($"# Patient Information");
        sb.AppendLine($"PatientName: {order.Patient.LastName}^{order.Patient.FirstName}");
        sb.AppendLine($"PatientID: {order.Patient.MRN}");
        sb.AppendLine($"PatientBirthDate: {order.Patient.DateOfBirth:yyyyMMdd}");
        sb.AppendLine($"PatientSex: {order.Patient.Gender}");
        sb.AppendLine();
        sb.AppendLine($"# Study Information");
        sb.AppendLine($"AccessionNumber: {order.AccessionNumber}");
        sb.AppendLine($"StudyDescription: {order.StudyDescription}");
        sb.AppendLine($"Modality: {order.Modality}");
        sb.AppendLine();
        sb.AppendLine($"# Scheduled Procedure Step");
        sb.AppendLine($"ScheduledStationAETitle: PACS");
        sb.AppendLine($"ScheduledProcedureStepStartDate: {order.ScheduledDateTime:yyyyMMdd}");
        sb.AppendLine($"ScheduledProcedureStepStartTime: {order.ScheduledDateTime:HHmmss}");
        sb.AppendLine($"ScheduledPerformingPhysicianName: {order.OrderingPhysician}");
        sb.AppendLine($"ScheduledProcedureStepDescription: {order.StudyDescription}");
        sb.AppendLine();
        sb.AppendLine($"# Requesting Physician");
        sb.AppendLine($"ReferringPhysicianName: {order.ReferringPhysician}");
        sb.AppendLine($"RequestingPhysician: {order.OrderingPhysician}");

        return sb.ToString();
    }
}
