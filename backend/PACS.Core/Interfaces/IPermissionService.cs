using PACS.Core.DTOs;

namespace PACS.Core.Interfaces;

public interface IPermissionService
{
    // Permission operations
    Task<List<PermissionResponse>> GetAllPermissionsAsync();
    Task<List<PermissionResponse>> GetUserPermissionsAsync(int userId);
    Task<bool> CheckUserPermissionAsync(int userId, string permissionName);
    
    // Role operations
    Task<List<RoleResponse>> GetAllRolesAsync();
    Task<RoleResponse?> GetRoleAsync(int roleId);
    Task<RoleResponse> CreateRoleAsync(CreateRoleRequest request);
    Task<RoleResponse?> UpdateRoleAsync(int roleId, UpdateRoleRequest request);
    Task<bool> DeleteRoleAsync(int roleId);
    Task<bool> AssignPermissionsToRoleAsync(int roleId, List<int> permissionIds);
    Task<bool> RemovePermissionFromRoleAsync(int roleId, int permissionId);
    
    // User-Role operations
    Task<bool> AssignRoleToUserAsync(int userId, int roleId);
    Task<bool> RemoveRoleFromUserAsync(int userId, int roleId);
    Task<List<RoleResponse>> GetUserRolesAsync(int userId);
    
    // Department operations
    Task<List<DepartmentResponse>> GetAllDepartmentsAsync();
    Task<DepartmentResponse?> GetDepartmentAsync(int departmentId);
    Task<DepartmentResponse> CreateDepartmentAsync(CreateDepartmentRequest request);
    Task<bool> AssignUserToDepartmentAsync(int userId, int departmentId);
    Task<bool> RemoveUserFromDepartmentAsync(int userId, int departmentId);
    Task<List<DepartmentResponse>> GetUserDepartmentsAsync(int userId);
    
    // Study Access Control
    Task<bool> GrantStudyAccessAsync(GrantStudyAccessRequest request, int grantedBy);
    Task<bool> RevokeStudyAccessAsync(string studyInstanceUID, int? userId, int? departmentId, string accessType);
    Task<bool> CheckStudyAccessAsync(int userId, string studyInstanceUID, string accessType);
}
