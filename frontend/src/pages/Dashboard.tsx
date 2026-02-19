import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { worklistApi } from '../services/api'
import Layout from '../components/Layout'
import { 
  HiOutlineClipboardList, 
  HiOutlineCheckCircle, 
  HiOutlineClock, 
  HiOutlineLightningBolt 
} from 'react-icons/hi'

export default function Dashboard() {
  const navigate = useNavigate()

  // Fetch real statistics from the new backend endpoint
  const { data: statsData, isLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: () => worklistApi.getStats() // You'll need to add this to your api.ts
  })

  const dashboardCards = [
    { 
      label: 'Pending Studies', 
      value: statsData?.pendingCount ?? 0, 
      icon: <HiOutlineClock className="text-amber-500" />, 
      color: 'border-amber-500/20',
      filter: 'Pending'
    },
    { 
      label: 'Priority Cases', 
      value: statsData?.priorityCount ?? 0, 
      icon: <HiOutlineLightningBolt className="text-red-500" />, 
      color: 'border-red-500/20',
      filter: 'Priority' 
    },
    { 
      label: 'Total Completed', 
      value: statsData?.reportedCount ?? 0, 
      icon: <HiOutlineCheckCircle className="text-emerald-500" />, 
      color: 'border-emerald-500/20',
      filter: 'Reported' 
    }
  ]

  return (
    <Layout>
      <div className="max-w-7xl mx-auto space-y-8">
        <header>
          <h1 className="text-3xl font-black text-white tracking-tight">Radiology Command Center</h1>
          <p className="text-slate-400 mt-1">Real-time department status and quick actions.</p>
        </header>

        {/* Dynamic Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {dashboardCards.map((card, index) => (
            <div 
              key={index} 
              onClick={() => navigate(`/worklist?status=${card.filter}`)}
              className={`bg-slate-900 border ${card.color} p-8 rounded-[2rem] shadow-xl transition-all hover:scale-[1.03] cursor-pointer group`}
            >
              <div className="flex justify-between items-start">
                <div className="p-4 bg-slate-950 rounded-2xl group-hover:bg-slate-800 transition-colors">
                  {card.icon}
                </div>
                {isLoading ? (
                  <div className="h-10 w-12 bg-slate-800 animate-pulse rounded-lg" />
                ) : (
                  <span className="text-5xl font-black text-white">{card.value}</span>
                )}
              </div>
              <p className="text-slate-500 text-xs font-black uppercase tracking-[0.2em] mt-6">{card.label}</p>
            </div>
          ))}
        </div>

        {/* Quick Access Area */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-slate-900 border border-slate-800 rounded-[2.5rem] p-8 flex flex-col justify-between">
            <div>
              <h2 className="text-xl font-bold text-white mb-2">Active Worklist</h2>
              <p className="text-slate-400 text-sm mb-6">Access the full list of patient studies and imaging series.</p>
            </div>
            <button 
              onClick={() => navigate('/worklist')}
              className="flex items-center justify-center gap-3 w-full py-4 bg-blue-600 hover:bg-blue-500 text-white rounded-2xl font-bold transition-all shadow-lg shadow-blue-900/20 active:scale-95"
            >
              <HiOutlineClipboardList size={22} />
              Open Full Worklist
            </button>
          </div>

          <div className="bg-slate-900/50 border border-slate-800 border-dashed rounded-[2.5rem] p-8 flex flex-col items-center justify-center text-center">
            <div className="p-4 bg-slate-800 rounded-full mb-4">
              <HiOutlineLightningBolt className="text-slate-500 w-8 h-8" />
            </div>
            <h3 className="text-white font-bold">System Status</h3>
            <p className="text-slate-500 text-sm">Orthanc PACS: <span className="text-emerald-500 font-bold">Online</span></p>
          </div>
        </div>
      </div>
    </Layout>
  )
}