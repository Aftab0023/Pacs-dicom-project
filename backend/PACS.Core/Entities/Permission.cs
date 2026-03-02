namespace PACS.Core.Entities;

public class Permission
{
    public int PermissionID { get; set; }
    public string PermissionName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
}

public class Role
{
    public int RoleID { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsSystemRole { get; set; } = false;
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();
    public ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}

public class RolePermission
{
    public int RoleID { get; set; }
    public int PermissionID { get; set; }
    
    // Navigation properties
    public Role Role { get; set; } = null!;
    public Permission Permission { get; set; } = null!;
}

public class UserRole
{
    public int UserID { get; set; }
    public int RoleID { get; set; }
    public DateTime AssignedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public User User { get; set; } = null!;
    public Role Role { get; set; } = null!;
}

public class Department
{
    public int DepartmentID { get; set; }
    public string DepartmentName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public ICollection<UserDepartment> UserDepartments { get; set; } = new List<UserDepartment>();
    public ICollection<StudyAccessControl> StudyAccessControls { get; set; } = new List<StudyAccessControl>();
}

public class UserDepartment
{
    public int UserID { get; set; }
    public int DepartmentID { get; set; }
    public DateTime AssignedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public User User { get; set; } = null!;
    public Department Department { get; set; } = null!;
}

public class StudyAccessControl
{
    public int AccessID { get; set; }
    public string StudyInstanceUID { get; set; } = string.Empty;
    public int? DepartmentID { get; set; }
    public int? UserID { get; set; }
    public string AccessType { get; set; } = string.Empty; // VIEW, DOWNLOAD, DELETE, SHARE, PRINT
    public int? GrantedBy { get; set; }
    public DateTime GrantedDate { get; set; } = DateTime.UtcNow;
    public DateTime? ExpiresAt { get; set; }
    
    // Navigation properties
    public Department? Department { get; set; }
    public User? User { get; set; }
    public User? GrantedByUser { get; set; }
}
