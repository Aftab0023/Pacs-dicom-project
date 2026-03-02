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
    
    // Enterprise entities
    public DbSet<WorklistEntry> WorklistEntries => Set<WorklistEntry>();
    public DbSet<RoutingRule> RoutingRules => Set<RoutingRule>();
    public DbSet<StudyAssignment> StudyAssignments => Set<StudyAssignment>();
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<RolePermission> RolePermissions => Set<RolePermission>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<Department> Departments => Set<Department>();
    public DbSet<UserDepartment> UserDepartments => Set<UserDepartment>();
    public DbSet<StudyAccessControl> StudyAccessControls => Set<StudyAccessControl>();
    public DbSet<AuditLogEnhanced> AuditLogsEnhanced => Set<AuditLogEnhanced>();
    public DbSet<PatientShare> PatientShares => Set<PatientShare>();
    public DbSet<PatientShareAccess> PatientShareAccesses => Set<PatientShareAccess>();
    public DbSet<SystemSetting> SystemSettings => Set<SystemSetting>();

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

        // Enterprise Entities Configuration
        ConfigureEnterpriseEntities(modelBuilder);

        // Seed data
        SeedData(modelBuilder);
    }

    private void ConfigureEnterpriseEntities(ModelBuilder modelBuilder)
    {
        // WorklistEntry
        modelBuilder.Entity<WorklistEntry>(entity =>
        {
            entity.HasKey(e => e.WorklistID);
            entity.HasIndex(e => e.AccessionNumber).IsUnique();
            entity.HasIndex(e => e.ScheduledProcedureStepStartDate);
            entity.HasIndex(e => e.Modality);
            entity.HasIndex(e => e.Status);
            entity.HasIndex(e => e.PatientID);
            
            entity.HasOne(e => e.Creator)
                .WithMany()
                .HasForeignKey(e => e.CreatedBy)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // RoutingRule
        modelBuilder.Entity<RoutingRule>(entity =>
        {
            entity.HasKey(e => e.RuleID);
            entity.HasIndex(e => new { e.Priority, e.IsActive });
            
            entity.HasOne(e => e.Creator)
                .WithMany()
                .HasForeignKey(e => e.CreatedBy)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // StudyAssignment
        modelBuilder.Entity<StudyAssignment>(entity =>
        {
            entity.HasKey(e => e.AssignmentID);
            entity.HasIndex(e => e.StudyInstanceUID);
            entity.HasIndex(e => new { e.AssignedToUserID, e.Status });
            entity.HasIndex(e => new { e.Priority, e.Status });
            
            entity.HasOne(e => e.AssignedToUser)
                .WithMany()
                .HasForeignKey(e => e.AssignedToUserID)
                .OnDelete(DeleteBehavior.Restrict);
                
            entity.HasOne(e => e.AssignedByRule)
                .WithMany(r => r.StudyAssignments)
                .HasForeignKey(e => e.AssignedByRuleID)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Permission
        modelBuilder.Entity<Permission>(entity =>
        {
            entity.HasKey(e => e.PermissionID);
            entity.HasIndex(e => e.PermissionName).IsUnique();
            entity.Property(e => e.PermissionName).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Category).HasMaxLength(50).IsRequired();
        });

        // Role
        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(e => e.RoleID);
            entity.HasIndex(e => e.RoleName).IsUnique();
            entity.Property(e => e.RoleName).HasMaxLength(50).IsRequired();
        });

        // RolePermission
        modelBuilder.Entity<RolePermission>(entity =>
        {
            entity.HasKey(e => new { e.RoleID, e.PermissionID });
            
            entity.HasOne(e => e.Role)
                .WithMany(r => r.RolePermissions)
                .HasForeignKey(e => e.RoleID)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.Permission)
                .WithMany(p => p.RolePermissions)
                .HasForeignKey(e => e.PermissionID)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // UserRole
        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.HasKey(e => new { e.UserID, e.RoleID });
            
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserID)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(e => e.RoleID)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Department
        modelBuilder.Entity<Department>(entity =>
        {
            entity.HasKey(e => e.DepartmentID);
            entity.HasIndex(e => e.DepartmentName).IsUnique();
            entity.Property(e => e.DepartmentName).HasMaxLength(100).IsRequired();
        });

        // UserDepartment
        modelBuilder.Entity<UserDepartment>(entity =>
        {
            entity.HasKey(e => new { e.UserID, e.DepartmentID });
            
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserID)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.Department)
                .WithMany(d => d.UserDepartments)
                .HasForeignKey(e => e.DepartmentID)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // StudyAccessControl
        modelBuilder.Entity<StudyAccessControl>(entity =>
        {
            entity.HasKey(e => e.AccessID);
            entity.HasIndex(e => e.StudyInstanceUID);
            entity.HasIndex(e => new { e.UserID, e.AccessType });
            entity.HasIndex(e => new { e.DepartmentID, e.AccessType });
            
            entity.HasOne(e => e.Department)
                .WithMany(d => d.StudyAccessControls)
                .HasForeignKey(e => e.DepartmentID)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserID)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(e => e.GrantedByUser)
                .WithMany()
                .HasForeignKey(e => e.GrantedBy)
                .OnDelete(DeleteBehavior.NoAction);
        });

        // AuditLogEnhanced
        modelBuilder.Entity<AuditLogEnhanced>(entity =>
        {
            entity.HasKey(e => e.AuditID);
            entity.HasIndex(e => e.Timestamp);
            entity.HasIndex(e => new { e.UserID, e.Timestamp });
            entity.HasIndex(e => new { e.EventType, e.Timestamp });
            entity.HasIndex(e => new { e.ResourceID, e.Timestamp });
            entity.HasIndex(e => new { e.EventCategory, e.Timestamp });
            
            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserID)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // PatientShare
        modelBuilder.Entity<PatientShare>(entity =>
        {
            entity.HasKey(e => e.ShareID);
            entity.HasIndex(e => e.ShareToken).IsUnique();
            entity.HasIndex(e => e.StudyInstanceUID);
            entity.HasIndex(e => new { e.IsActive, e.ExpiresAt });
            entity.Property(e => e.ShareToken).HasMaxLength(100).IsRequired();
            entity.Property(e => e.StudyInstanceUID).HasMaxLength(200).IsRequired();
            entity.Property(e => e.PatientEmail).HasMaxLength(200);
            
            entity.HasOne(e => e.Patient)
                .WithMany()
                .HasForeignKey(e => e.PatientID)
                .OnDelete(DeleteBehavior.Restrict);
                
            entity.HasOne(e => e.CreatedByUser)
                .WithMany()
                .HasForeignKey(e => e.CreatedBy)
                .OnDelete(DeleteBehavior.Restrict);
        });

        // PatientShareAccess
        modelBuilder.Entity<PatientShareAccess>(entity =>
        {
            entity.HasKey(e => e.AccessID);
            entity.HasIndex(e => new { e.ShareID, e.AccessedAt });
            entity.Property(e => e.IPAddress).HasMaxLength(50);
            entity.Property(e => e.UserAgent).HasMaxLength(500);
            
            entity.HasOne(e => e.Share)
                .WithMany(s => s.AccessLogs)
                .HasForeignKey(e => e.ShareID)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // SystemSetting
        modelBuilder.Entity<SystemSetting>(entity =>
        {
            entity.HasKey(e => e.SettingID);
            entity.HasIndex(e => e.SettingKey).IsUnique();
            entity.HasIndex(e => new { e.Category, e.IsEditable });
            entity.Property(e => e.SettingKey).HasMaxLength(100).IsRequired();
            entity.Property(e => e.SettingType).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Category).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(500);
            
            entity.HasOne(e => e.UpdatedByUser)
                .WithMany()
                .HasForeignKey(e => e.UpdatedBy)
                .OnDelete(DeleteBehavior.SetNull);
        });
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
