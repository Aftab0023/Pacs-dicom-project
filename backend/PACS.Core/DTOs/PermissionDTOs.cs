namespace PACS.Core.DTOs;

public class PermissionResponse
{
    public int PermissionID { get; set; }
    public string PermissionName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public class RoleResponse
{
    public int RoleID { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsSystemRole { get; set; }
    public List<PermissionResponse> Permissions { get; set; } = new();
}

public class CreateRoleRequest
{
    public string RoleName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public List<int> PermissionIDs { get; set; } = new();
}

public class UpdateRoleRequest
{
    public string? RoleName { get; set; }
    public string? Description { get; set; }
}

public class AssignPermissionsRequest
{
    public List<int> PermissionIDs { get; set; } = new();
}

public class DepartmentResponse
{
    public int DepartmentID { get; set; }
    public string DepartmentName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}

public class CreateDepartmentRequest
{
    public string DepartmentName { get; set; } = string.Empty;
    public string? Description { get; set; }
}

public class GrantStudyAccessRequest
{
    public string StudyInstanceUID { get; set; } = string.Empty;
    public int? DepartmentID { get; set; }
    public int? UserID { get; set; }
    public string AccessType { get; set; } = string.Empty; // VIEW, DOWNLOAD, DELETE, SHARE, PRINT
    public DateTime? ExpiresAt { get; set; }
}

public class CheckPermissionRequest
{
    public string PermissionName { get; set; } = string.Empty;
}

public class CheckPermissionResponse
{
    public bool HasPermission { get; set; }
}

public class CheckStudyAccessRequest
{
    public string StudyInstanceUID { get; set; } = string.Empty;
    public string AccessType { get; set; } = string.Empty;
}

public class CheckStudyAccessResponse
{
    public bool HasAccess { get; set; }
    public string? Reason { get; set; }
}
