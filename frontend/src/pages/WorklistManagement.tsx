import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { worklistEnterpriseApi } from '../services/api'
import Layout from '../components/Layout'
import { HiPlus, HiTrash, HiCalendar } from 'react-icons/hi'

export default function WorklistManagement() {
  const queryClient = useQueryClient()
  const [filters, setFilters] = useState({
    modality: '',
    status: '',
    startDate: '',
    endDate: ''
  })

  const { data: entries, isLoading } = useQuery({
    queryKey: ['worklist-entries', filters],
    queryFn: () => worklistEnterpriseApi.getEntries(filters)
  })

  // Create dialog functionality - to be implemented
  const handleCreateClick = () => {
    alert('Create worklist entry dialog - to be implemented')
  }

  const deleteMutation = useMutation({
    mutationFn: worklistEnterpriseApi.deleteEntry,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['worklist-entries'] })
    }
  })

  return (
    <Layout>
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-white">Modality Worklist Management</h1>
            <p className="text-slate-400 mt-1">Schedule procedures for imaging modalities</p>
          </div>
          <button
            onClick={handleCreateClick}
            className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-bold"
          >
            <HiPlus size={20} />
            Schedule Procedure
          </button>
        </div>

        {/* Filters */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">Modality</label>
              <select
                value={filters.modality}
                onChange={(e) => setFilters({ ...filters, modality: e.target.value })}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
              >
                <option value="">All Modalities</option>
                <option value="CT">CT</option>
                <option value="MR">MR</option>
                <option value="XR">XR</option>
                <option value="US">US</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">Status</label>
              <select
                value={filters.status}
                onChange={(e) => setFilters({ ...filters, status: e.target.value })}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
              >
                <option value="">All Status</option>
                <option value="SCHEDULED">Scheduled</option>
                <option value="IN_PROGRESS">In Progress</option>
                <option value="COMPLETED">Completed</option>
                <option value="CANCELLED">Cancelled</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">Start Date</label>
              <input
                type="date"
                value={filters.startDate}
                onChange={(e) => setFilters({ ...filters, startDate: e.target.value })}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">End Date</label>
              <input
                type="date"
                value={filters.endDate}
                onChange={(e) => setFilters({ ...filters, endDate: e.target.value })}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
              />
            </div>
          </div>
        </div>

        {/* Worklist Entries Table */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-800">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Accession #
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Patient
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Scheduled Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Modality
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Procedure
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-slate-300 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800">
                {isLoading ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center text-slate-400">
                      Loading worklist entries...
                    </td>
                  </tr>
                ) : entries?.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center text-slate-400">
                      No worklist entries found
                    </td>
                  </tr>
                ) : (
                  entries?.map((entry: any) => (
                    <tr key={entry.worklistID} className="hover:bg-slate-800/50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-white">
                        {entry.accessionNumber}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-300">
                        {entry.patientName}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-300">
                        <div className="flex items-center gap-2">
                          <HiCalendar className="text-slate-500" />
                          {new Date(entry.scheduledProcedureStepStartDate).toLocaleDateString()}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="px-2 py-1 text-xs font-semibold rounded-full bg-blue-500/10 text-blue-400">
                          {entry.modality}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-300">
                        {entry.scheduledProcedureStepDescription}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                          entry.status === 'COMPLETED' ? 'bg-green-500/10 text-green-400' :
                          entry.status === 'IN_PROGRESS' ? 'bg-yellow-500/10 text-yellow-400' :
                          entry.status === 'CANCELLED' ? 'bg-red-500/10 text-red-400' :
                          'bg-slate-500/10 text-slate-400'
                        }`}>
                          {entry.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <button
                          onClick={() => deleteMutation.mutate(entry.worklistID)}
                          className="text-red-400 hover:text-red-300 ml-3"
                        >
                          <HiTrash size={18} />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </Layout>
  )
}
