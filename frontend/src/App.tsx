import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './contexts/AuthContext'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Worklist from './pages/Worklist'
import StudyViewer from './pages/StudyViewer'
import Reporting from './pages/Reporting'
import OHIFViewer from './pages/OHIFViewer'

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user } = useAuth()
  return user ? <>{children}</> : <Navigate to="/login" />
}

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/worklist" element={<ProtectedRoute><Worklist /></ProtectedRoute>} />
          <Route path="/viewer/:studyId" element={<ProtectedRoute><StudyViewer /></ProtectedRoute>} />
          <Route path="/viewer" element={<ProtectedRoute><OHIFViewer /></ProtectedRoute>} />
          <Route path="/report/:studyId" element={<ProtectedRoute><Reporting /></ProtectedRoute>} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}

export default App
