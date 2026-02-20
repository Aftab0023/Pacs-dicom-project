using Microsoft.EntityFrameworkCore;
using PACS.Core.Entities;

namespace PACS.Infrastructure.Data;

public class PACSDbContext : DbContext
{
    public PACSDbContext(DbContextOptions<PACSDbContext> options) : base(options)
    {
    }

    public DbSet<Patient> Patients => Set<Patient>();
    public DbSet<Study> Studies => Set<Study>();
    public DbSet<Series> Series => Set<Series>();
    public DbSet<Instance> Instances => Set<Instance>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Report> Reports => Set<Report>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<ReportTemplate> ReportTemplates => Set<ReportTemplate>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Patient
        modelBuilder.Entity<Patient>(entity =>
        {
            entity.HasKey(e => e.PatientId);
            entity.HasIndex(e => e.MRN).IsUnique();
            entity.Property(e => e.MRN).HasMaxLength(50).IsRequired();
            entity.Property(e => e.FirstName).HasMaxLength(100).IsRequired();
            entity.Property(e => e.LastName).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Gender).HasMaxLength(10);
        });

        // Study
        modelBuilder.Entity<Study>(entity =>
        {
            entity.HasKey(e => e.StudyId);
            entity.HasIndex(e => e.StudyInstanceUID).IsUnique();
            entity.Property(e => e.StudyInstanceUID).HasMaxLength(200).IsRequired();
            
            // New & Updated Fields
            entity.Property(e => e.Status)
                  .HasMaxLength(50)
                  .HasDefaultValue("Pending"); // Matches frontend default
            
            entity.Property(e => e.IsPriority)
                  .HasDefaultValue(false); // Matches frontend logic

            entity.Property(e => e.CreatedAt)
                  .HasDefaultValueSql("GETUTCDATE()");

            entity.HasOne(e => e.Patient)
                .WithMany(p => p.Studies)
                .HasForeignKey(e => e.PatientId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.AssignedRadiologist)
                .WithMany(u => u.AssignedStudies)
                .HasForeignKey(e => e.AssignedRadiologistId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Series
        modelBuilder.Entity<Series>(entity =>
        {
            entity.HasKey(e => e.SeriesId);
            entity.HasIndex(e => e.SeriesInstanceUID).IsUnique();
            entity.Property(e => e.SeriesInstanceUID).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Modality).HasMaxLength(50);
            entity.Property(e => e.BodyPart).HasMaxLength(100);
            entity.Property(e => e.Description).HasMaxLength(500);

            entity.HasOne(e => e.Study)
                .WithMany(s => s.Series)
                .HasForeignKey(e => e.StudyId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Instance
        modelBuilder.Entity<Instance>(entity =>
        {
            entity.HasKey(e => e.InstanceId);
            entity.HasIndex(e => e.SOPInstanceUID).IsUnique();
            entity.Property(e => e.SOPInstanceUID).HasMaxLength(200).IsRequired();
            entity.Property(e => e.FilePath).HasMaxLength(1000);

            entity.HasOne(e => e.Series)
                .WithMany(s => s.Instances)
                .HasForeignKey(e => e.SeriesId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // User
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.UserId);
            entity.HasIndex(e => e.Email).IsUnique();
            entity.HasIndex(e => e.Username).IsUnique();
            entity.Property(e => e.Username).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Email).HasMaxLength(200).IsRequired();
            entity.Property(e => e.PasswordHash).HasMaxLength(500).IsRequired();
            entity.Property(e => e.Role).HasMaxLength(50).IsRequired();
            entity.Property(e => e.FirstName).HasMaxLength(100);
            entity.Property(e => e.LastName).HasMaxLength(100);
        });

        // Report
        modelBuilder.Entity<Report>(entity =>
        {
            entity.HasKey(e => e.ReportId);
            entity.HasIndex(e => e.StudyId);
            entity.HasIndex(e => e.Status);
            entity.Property(e => e.Status).HasMaxLength(50);
            entity.Property(e => e.DigitalSignature).HasMaxLength(1000);

            entity.HasOne(e => e.Study)
                .WithMany(s => s.Reports)
                .HasForeignKey(e => e.StudyId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Radiologist)
                .WithMany(u => u.Reports)
                .HasForeignKey(e => e.RadiologistId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // AuditLog
        modelBuilder.Entity<AuditLog>(entity =>
        {
            entity.HasKey(e => e.AuditLogId);
            entity.HasIndex(e => e.CreatedAt);
            entity.HasIndex(e => e.UserId);
            entity.Property(e => e.Action).HasMaxLength(100);
            entity.Property(e => e.EntityType).HasMaxLength(100);
            entity.Property(e => e.EntityId).HasMaxLength(100);
            entity.Property(e => e.IpAddress).HasMaxLength(50);

            entity.HasOne(e => e.User)
                .WithMany(u => u.AuditLogs)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Order
        modelBuilder.Entity<Order>(entity =>
        {
            entity.HasKey(e => e.OrderId);
            entity.HasIndex(e => e.AccessionNumber).IsUnique();
            entity.HasIndex(e => e.Status);
            entity.Property(e => e.AccessionNumber).HasMaxLength(50).IsRequired();
            entity.Property(e => e.OrderingPhysician).HasMaxLength(200);
            entity.Property(e => e.ReferringPhysician).HasMaxLength(200);
            entity.Property(e => e.Modality).HasMaxLength(50);
            entity.Property(e => e.StudyDescription).HasMaxLength(500);
            entity.Property(e => e.Status).HasMaxLength(50).HasDefaultValue("Scheduled");
            entity.Property(e => e.Priority).HasMaxLength(50).HasDefaultValue("Routine");
            entity.Property(e => e.HL7MessageId).HasMaxLength(100);

            entity.HasOne(e => e.Patient)
                .WithMany()
                .HasForeignKey(e => e.PatientId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // ReportTemplate
        modelBuilder.Entity<ReportTemplate>(entity =>
        {
            entity.HasKey(e => e.TemplateId);
            entity.HasIndex(e => e.Specialty);
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Specialty).HasMaxLength(100);
            entity.Property(e => e.Modality).HasMaxLength(50);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
        });

        // Seed data
        SeedData(modelBuilder);
    }

    private void SeedData(ModelBuilder modelBuilder)
    {
        // Seed admin user
        modelBuilder.Entity<User>().HasData(
            new User
            {
                UserId = 1,
                Username = "admin",
                Email = "admin@pacs.local",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Admin123!"),
                Role = "Admin",
                FirstName = "System",
                LastName = "Administrator",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            },
            new User
            {
                UserId = 2,
                Username = "radiologist",
                Email = "radiologist@pacs.local",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("Radio123!"),
                Role = "Radiologist",
                FirstName = "John",
                LastName = "Radiologist",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            }
        );
    }
}
