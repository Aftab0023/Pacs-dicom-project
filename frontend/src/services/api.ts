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

export default api
