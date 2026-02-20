import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
// 1. Import your logo
import logo from '../Images/logo.png' 

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { login } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      await login(email, password)
      navigate('/worklist')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Invalid email or password')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-950 p-4 sm:p-6">
      {/* Container with max-width for mobile and shadow for depth */}
      <div className="bg-slate-900 border border-slate-800 p-6 sm:p-10 rounded-2xl shadow-2xl w-full max-w-[440px] transition-all">
        
        {/* Logo and Header Section */}
        <div className="flex flex-col items-center mb-10">
          <div className="w-20 h-20 mb-4 flex items-center justify-center bg-white/5 rounded-2xl p-2 border border-white/10">
            <img 
              src={logo} 
              alt="PACS Logo" 
              className="w-full h-full object-contain" 
            />
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">
            PACS Portal
          </h1>
          <p className="text-slate-400 text-sm mt-2 text-center">
            Secure Medical Imaging System
          </p>
        </div>
        
        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Email Field */}
          <div className="space-y-1.5">
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400 ml-1">
              Email Address
            </label>
            <input
              type="email"
              value={email}
              placeholder="name@hospital.com"
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all text-base"
              required
            />
          </div>

          {/* Password Field */}
          <div className="space-y-1.5">
            <div className="flex justify-between items-center px-1">
              <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                Password
              </label>
            </div>
            <input
              type="password"
              value={password}
              placeholder="••••••••"
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 transition-all text-base"
              required
            />
          </div>

          {/* Error Message */}
          {error && (
            <div className="bg-red-500/10 border border-red-500/50 text-red-400 px-4 py-3 rounded-xl text-sm animate-pulse">
              {error}
            </div>
          )}

          {/* Login Button */}
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-blue-600 hover:bg-blue-500 active:scale-[0.98] text-white font-bold py-3.5 rounded-xl transition-all shadow-lg shadow-blue-900/20 disabled:opacity-50 disabled:cursor-not-allowed mt-2"
          >
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <svg className="animate-spin h-5 w-5 text-white" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Authenticating...
              </span>
            ) : 'Sign In'}
          </button>
        </form>

        {/* Footer Info / Demo Accs */}
        <div className="mt-8 pt-6 border-t border-slate-800">
          <div className="grid grid-cols-2 gap-4 text-[10px] sm:text-xs">
             <div className="bg-white/5 p-2 rounded-lg border border-white/5">
                <p className="text-blue-400 font-bold mb-1">ADMIN</p>
                <p className="text-slate-300">admin@pacs.local</p>
                <p className="text-slate-500 italic">admin123</p>
             </div>
             <div className="bg-white/5 p-2 rounded-lg border border-white/5">
                <p className="text-blue-400 font-bold mb-1">STAFF</p>
                <p className="text-slate-300">radiologist@pacs.local</p>
                <p className="text-slate-500 italic">admin123</p>
             </div>
          </div>
        </div>
      </div>
    </div>
  )
}