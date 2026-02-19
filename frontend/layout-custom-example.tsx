import { ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

interface LayoutProps {
  children: ReactNode
}

export default function Layout({ children }: LayoutProps) {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-medical-darker">
      {/* CUSTOMIZABLE NAVIGATION */}
      <nav className="bg-gradient-to-r from-medical-dark to-medical-blue shadow-xl border-b border-medical-accent/20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-20"> {/* Increased height */}
            
            {/* LEFT SIDE - Logo & Navigation */}
            <div className="flex items-center space-x-8">
              {/* CUSTOM LOGO */}
              <div className="flex items-center space-x-3">
                {/* Add your logo image here */}
                <div className="w-10 h-10 bg-medical-accent rounded-lg flex items-center justify-center">
                  <span className="text-white font-bold text-xl">P</span>
                </div>
                <div>
                  <div className="text-2xl font-bold text-white">MediPACS</div>
                  <div className="text-xs text-gray-300">Radiology System</div>
                </div>
              </div>
              
              {/* NAVIGATION MENU */}
              <div className="hidden md:flex space-x-1">
                <button
                  onClick={() => navigate('/')}
                  className="text-gray-300 hover:text-white hover:bg-medical-accent/20 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200"
                >
                  🏠 Dashboard
                </button>
                <button
                  onClick={() => navigate('/worklist')}
                  className="text-gray-300 hover:text-white hover:bg-medical-accent/20 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200"
                >
                  📋 Worklist
                </button>
                {user?.role === 'Radiologist' && (
                  <button
                    onClick={() => navigate('/reports')}
                    className="text-gray-300 hover:text-white hover:bg-medical-accent/20 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200"
                  >
                    📄 Reports
                  </button>
                )}
                {user?.role === 'Admin' && (
                  <button
                    onClick={() => navigate('/admin')}
                    className="text-gray-300 hover:text-white hover:bg-medical-accent/20 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200"
                  >
                    ⚙️ Admin
                  </button>
                )}
              </div>
            </div>

            {/* RIGHT SIDE - User Info & Actions */}
            <div className="flex items-center space-x-4">
              {/* NOTIFICATIONS (Optional) */}
              <button className="text-gray-300 hover:text-white p-2 rounded-lg hover:bg-medical-accent/20 transition-all">
                <span className="text-xl">🔔</span>
                <span className="absolute -mt-1 -mr-1 px-1 py-0 bg-red-500 text-xs text-white rounded-full">3</span>
              </button>
              
              {/* USER PROFILE */}
              <div className="flex items-center space-x-3 bg-medical-darker/50 rounded-lg px-4 py-2">
                <div className="w-8 h-8 bg-medical-accent rounded-full flex items-center justify-center">
                  <span className="text-white text-sm font-bold">
                    {user?.firstName?.charAt(0)}{user?.lastName?.charAt(0)}
                  </span>
                </div>
                <div className="text-sm">
                  <div className="text-white font-medium">{user?.firstName} {user?.lastName}</div>
                  <div className="text-gray-400 text-xs">{user?.role}</div>
                </div>
              </div>
              
              {/* LOGOUT BUTTON */}
              <button
                onClick={handleLogout}
                className="px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg text-sm font-medium transition-all duration-200 shadow-lg hover:shadow-xl"
              >
                🚪 Logout
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* MAIN CONTENT */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="animate-fade-in">
          {children}
        </div>
      </main>
      
      {/* FOOTER (Optional) */}
      <footer className="bg-medical-dark border-t border-gray-700 mt-auto">
        <div className="max-w-7xl mx-auto px-4 py-4 text-center text-gray-400 text-sm">
          © 2024 MediPACS - Radiology Information System
        </div>
      </footer>
    </div>
  )
}