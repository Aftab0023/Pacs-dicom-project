import { ReactNode, useState } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { 
  HiMenu, HiX, HiLogout, HiViewGrid, 
  HiClipboardList, HiBell 
} from 'react-icons/hi'

// 1. Import your logo
import logo from '../Images/logo.png' 

interface LayoutProps {
  children: ReactNode
}

export default function Layout({ children }: LayoutProps) {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const [notifications] = useState(3) // Example count

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const isActive = (path: string) => location.pathname === path

  return (
    <div className="min-h-screen bg-slate-950 text-slate-200">
      {/* --- Navigation Bar --- */}
      <nav className="bg-slate-900/80 backdrop-blur-md border-b border-slate-800 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-20"> {/* Increased height for logo */}
            
            {/* Left Side: Brand & Desktop Links */}
            <div className="flex items-center">
              <div 
                className="flex items-center gap-3 cursor-pointer group" 
                onClick={() => navigate('/')}
              >
                <div className="bg-white/5 p-1.5 rounded-xl border border-white/10 group-hover:border-blue-500/50 transition-all">
                  <img src={logo} alt="Company Logo" className="h-9 w-auto object-contain" />
                </div>
                <div className="flex flex-col">
                  <span className="text-lg font-black tracking-tighter text-white leading-none">
                    LIFE<span className="text-blue-500">RELIER</span>
                  </span>
                  <span className="text-[10px] font-bold text-slate-500 tracking-[0.2em] uppercase">
                    PACS System
                  </span>
                </div>
              </div>
              
              <div className="hidden md:ml-12 md:flex md:space-x-1">
                <NavButton onClick={() => navigate('/')} active={isActive('/')} icon={<HiViewGrid />} label="Dashboard" />
                <NavButton onClick={() => navigate('/worklist')} active={isActive('/worklist')} icon={<HiClipboardList />} label="Worklist" />
              </div>
            </div>

            {/* Right Side: User & Actions */}
            <div className="flex items-center space-x-2 md:space-x-6">
              
              {/* Notification Bell */}
              <button className="p-2.5 text-slate-400 hover:text-blue-400 hover:bg-blue-500/10 rounded-xl transition-all relative">
                <HiBell className="w-6 h-6" />
                {notifications > 0 && (
                  <span className="absolute top-2 right-2 flex h-4 w-4">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-4 w-4 bg-red-600 text-[10px] font-bold items-center justify-center text-white">
                      {notifications}
                    </span>
                  </span>
                )}
              </button>

              {/* Desktop User Info */}
              <div className="hidden md:flex items-center space-x-4 border-l border-slate-800 pl-6">
                <div className="flex flex-col items-end">
                  <span className="text-sm font-bold text-white">{user?.firstName} {user?.lastName}</span>
                  <span className="text-[10px] font-black uppercase text-blue-500 tracking-widest">{user?.role}</span>
                </div>
                <button 
                  onClick={handleLogout} 
                  className="p-2.5 bg-slate-800 hover:bg-red-500/10 hover:text-red-500 rounded-xl transition-all"
                >
                  <HiLogout className="w-5 h-5" />
                </button>
              </div>

              {/* Mobile Menu Button */}
              <button 
                onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)} 
                className="md:hidden p-2.5 bg-slate-800 rounded-xl text-slate-200"
              >
                {isMobileMenuOpen ? <HiX size={24} /> : <HiMenu size={24} />}
              </button>
            </div>
          </div>
        </div>

        {/* --- Mobile Dropdown Menu --- */}
        {isMobileMenuOpen && (
          <div className="md:hidden bg-slate-900 border-b border-slate-800 p-4 space-y-2 animate-in slide-in-from-top duration-300">
            <MobileNavButton onClick={() => {navigate('/'); setIsMobileMenuOpen(false)}} active={isActive('/')} icon={<HiViewGrid />} label="Dashboard" />
            <MobileNavButton onClick={() => {navigate('/worklist'); setIsMobileMenuOpen(false)}} active={isActive('/worklist')} icon={<HiClipboardList />} label="Worklist" />
            
            <div className="pt-4 mt-4 border-t border-slate-800 space-y-4">
               <div className="px-4">
                  <p className="text-white font-bold">{user?.firstName} {user?.lastName}</p>
                  <p className="text-blue-500 text-[10px] font-black uppercase tracking-widest">{user?.role}</p>
               </div>
               <button onClick={handleLogout} className="w-full flex items-center gap-3 px-4 py-3 bg-red-500/10 text-red-500 rounded-xl font-bold">
                  <HiLogout /> Logout
               </button>
            </div>
          </div>
        )}
      </nav>

      {/* --- Main Page Content --- */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 md:py-12">
        <div className="animate-in fade-in slide-in-from-bottom-4 duration-700">
          {children}
        </div>
      </main>

      {/* --- Footer Branding --- */}
      <footer className="max-w-7xl mx-auto px-4 py-8 border-t border-slate-900 text-center">
        <p className="text-slate-600 text-[10px] font-bold uppercase tracking-[0.3em]">
          Powered by Life Relier PACS Systems • v1.0.4
        </p>
      </footer>
    </div>
  )
}

// --- Internal Helper Components ---
function NavButton({ onClick, active, icon, label }: any) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-bold transition-all ${
        active 
          ? 'bg-blue-600/10 text-blue-400' 
          : 'text-slate-500 hover:text-slate-200 hover:bg-slate-800/50'
      }`}
    >
      {icon} {label}
    </button>
  )
}

function MobileNavButton({ onClick, active, icon, label }: any) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-3 w-full px-4 py-3.5 rounded-xl font-bold text-base transition-all ${
        active ? 'bg-blue-600 text-white shadow-lg' : 'bg-slate-800/50 text-slate-400'
      }`}
    >
      {icon} {label}
    </button>
  )
}