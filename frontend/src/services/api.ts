import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api'

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Add this below your request interceptor
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const authApi = {
  login: async (email: string, password: string) => {
    const response = await api.post('/auth/login', { email, password })
    return response.data
  },
  logout: async () => {
    await api.post('/auth/logout', {})
  }
}

export const worklistApi = {
  getWorklist: async (filters: any) => {
    const response = await api.get('/worklist', { params: filters })
    return response.data
  },
  getStudyDetail: async (studyId: number) => {
    const response = await api.get(`/worklist/${studyId}`)
    return response.data
  },
  assignStudy: async (studyId: number, radiologistId: number) => {
    const response = await api.post(`/worklist/${studyId}/assign`, { radiologistId })
    return response.data
  },
  updateStatus: async (studyId: number, status: string) => {
    const response = await api.put(`/worklist/${studyId}/status`, { status })
    return response.data
  },
  setPriority: async (studyId: number, isPriority: boolean) => {
    const response = await api.put(`/worklist/${studyId}/priority`, { isPriority })
    return response.data
  },
  getStats: async () => {
    const response = await api.get('/worklist/stats');
    return response.data;
  }
}

export const reportApi = {
  getReport: async (reportId: number) => {
    const response = await api.get(`/report/${reportId}`)
    return response.data
  },
  getStudyReports: async (studyId: number) => {
    const response = await api.get(`/report/study/${studyId}`)
    return response.data
  },
  createReport: async (data: any) => {
    const response = await api.post('/report', data)
    return response.data
  },
  updateReport: async (reportId: number, data: any) => {
    const response = await api.put(`/report/${reportId}`, data)
    return response.data
  },
  finalizeReport: async (reportId: number, signature: string) => {
    const response = await api.post(`/report/${reportId}/finalize`, { digitalSignature: signature })
    return response.data
  },
  downloadPdf: async (reportId: number) => {
    const response = await api.get(`/report/${reportId}/pdf`, { responseType: 'blob' })
    return response.data
  }
  
}

// Enterprise Features - Modality Worklist
export const worklistEnterpriseApi = {
  getEntries: async (filters: any) => {
    const response = await api.get('/worklist/entries', { params: filters })
    return response.data
  },
  createEntry: async (data: any) => {
    const response = await api.post('/worklist/entries', data)
    return response.data
  },
  updateEntry: async (id: number, data: any) => {
    const response = await api.put(`/worklist/entries/${id}`, data)
    return response.data
  },
  deleteEntry: async (id: number) => {
    const response = await api.delete(`/worklist/entries/${id}`)
    return response.data
  },
  updateStatus: async (id: number, status: string) => {
    const response = await api.patch(`/worklist/entries/${id}/status`, { status })
    return response.data
  }
}

// Enterprise Features - Routing Rules
export const routingApi = {
  getRules: async () => {
    const response = await api.get('/routing/rules')
    return response.data
  },
  createRule: async (data: any) => {
    const response = await api.post('/routing/rules', data)
    return response.data
  },
  updateRule: async (id: number, data: any) => {
    const response = await api.put(`/routing/rules/${id}`, data)
    return response.data
  },
  deleteRule: async (id: number) => {
    const response = await api.delete(`/routing/rules/${id}`)
    return response.data
  },
  evaluateRouting: async (studyData: any) => {
    const response = await api.post('/routing/evaluate', studyData)
    return response.data
  }
}

// Enterprise Features - Permissions & Roles
export const permissionApi = {
  getPermissions: async () => {
    const response = await api.get('/permissions')
    return response.data
  },
  getUserPermissions: async (userId: number) => {
    const response = await api.get(`/permissions/user/${userId}`)
    return response.data
  },
  checkPermission: async (permissionName: string) => {
    const response = await api.post('/permissions/check', { permissionName })
    return response.data
  },
  getRoles: async () => {
    const response = await api.get('/roles')
    return response.data
  },
  createRole: async (data: any) => {
    const response = await api.post('/roles', data)
    return response.data
  },
  assignRole: async (userId: number, roleId: number) => {
    const response = await api.post(`/users/${userId}/roles/${roleId}`)
    return response.data
  },
  getDepartments: async () => {
    const response = await api.get('/departments')
    return response.data
  }
}

// Enterprise Features - Audit Logs
export const auditApi = {
  getLogs: async (filters: any) => {
    const response = await api.get('/audit/logs', { params: filters })
    return response.data
  },
  exportLogs: async (filters: any) => {
    const response = await api.get('/audit/export', { params: filters, responseType: 'blob' })
    return response.data
  }
}

// OHIF Viewer - Patient Sharing
export const viewerSharingApi = {
  createShareLink: async (studyInstanceUID: string, expiresInHours: number = 24) => {
    const response = await api.post('/viewer/share', {
      studyInstanceUID,
      expiresInHours
    })
    return response.data
  },
  getShareLink: async (shareToken: string) => {
    const response = await api.get(`/viewer/share/${shareToken}`)
    return response.data
  },
  revokeShareLink: async (shareToken: string) => {
    const response = await api.delete(`/viewer/share/${shareToken}`)
    return response.data
  },
  sendToPatient: async (studyInstanceUID: string, patientEmail: string, message?: string) => {
    const response = await api.post('/viewer/send-to-patient', {
      studyInstanceUID,
      patientEmail,
      message
    })
    return response.data
  }
}

// System Settings (Admin only)
export const systemSettingsApi = {
  getAllSettings: async () => {
    const response = await api.get('/SystemSettings')
    return response.data
  },
  getSettingsByCategory: async (category: string) => {
    const response = await api.get(`/SystemSettings/category/${category}`)
    return response.data
  },
  getReportSettings: async () => {
    const response = await api.get('/SystemSettings/report')
    return response.data
  },
  updateSetting: async (key: string, value: string) => {
    const response = await api.put(`/SystemSettings/${key}`, { settingValue: value })
    return response.data
  },
  updateReportSettings: async (settings: any) => {
    const response = await api.put('/SystemSettings/report', settings)
    return response.data
  }
}

export default api
