import { useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import Layout from '../components/Layout'

export default function Dashboard() {
  const { user } = useAuth()
  const navigate = useNavigate()

  return (
    <Layout>
      <div className="space-y-6">
        <h1 className="text-3xl font-bold">Welcome, {user?.firstName} {user?.lastName}</h1>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div 
            onClick={() => navigate('/worklist')}
            className="bg-medical-dark p-6 rounded-lg shadow-lg cursor-pointer hover:bg-opacity-80 transition"
          >
            <h2 className="text-xl font-semibold mb-2">Worklist</h2>
            <p className="text-gray-400">View and manage studies</p>
          </div>

          {user?.role === 'Radiologist' && (
            <div className="bg-medical-dark p-6 rounded-lg shadow-lg">
              <h2 className="text-xl font-semibold mb-2">My Studies</h2>
              <p className="text-gray-400">Studies assigned to you</p>
            </div>
          )}

          <div className="bg-medical-dark p-6 rounded-lg shadow-lg">
            <h2 className="text-xl font-semibold mb-2">Statistics</h2>
            <p className="text-gray-400">System overview</p>
          </div>
        </div>

        <div className="bg-medical-dark p-6 rounded-lg shadow-lg">
          <h2 className="text-xl font-semibold mb-4">Quick Stats</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-3xl font-bold text-medical-accent">0</div>
              <div className="text-sm text-gray-400">Pending Studies</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-yellow-500">0</div>
              <div className="text-sm text-gray-400">In Progress</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-green-500">0</div>
              <div className="text-sm text-gray-400">Completed</div>
            </div>
            <div className="text-center">
              <div className="text-3xl font-bold text-red-500">0</div>
              <div className="text-sm text-gray-400">Priority</div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  )
}
