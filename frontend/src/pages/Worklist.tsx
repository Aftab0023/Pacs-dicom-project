import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { worklistApi } from '../services/api'
import Layout from '../components/Layout'
import { format } from 'date-fns'

export default function Worklist() {
  const navigate = useNavigate()
  const [filters, setFilters] = useState({
    searchTerm: '',
    modality: '',
    status: '',
    page: 1,
    pageSize: 20
  })

  const { data, isLoading } = useQuery({
    queryKey: ['worklist', filters],
    queryFn: () => worklistApi.getWorklist(filters)
  })

  const handleViewStudy = (studyId: number) => {
    navigate(`/viewer/${studyId}`)
  }

  const handleCreateReport = (studyId: number) => {
    navigate(`/report/${studyId}`)
  }

  return (
    <Layout>
      <div className="space-y-6">
        <h1 className="text-3xl font-bold">Worklist</h1>

        <div className="bg-medical-dark p-4 rounded-lg shadow-lg">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <input
              type="text"
              placeholder="Search patient, MRN, accession..."
              value={filters.searchTerm}
              onChange={(e) => setFilters({ ...filters, searchTerm: e.target.value, page: 1 })}
              className="px-4 py-2 bg-medical-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-medical-accent"
            />
            
            <select
              value={filters.modality}
              onChange={(e) => setFilters({ ...filters, modality: e.target.value, page: 1 })}
              className="px-4 py-2 bg-medical-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-medical-accent"
            >
              <option value="">All Modalities</option>
              <option value="CT">CT</option>
              <option value="MR">MRI</option>
              <option value="XR">X-Ray</option>
              <option value="US">Ultrasound</option>
            </select>

            <select
              value={filters.status}
              onChange={(e) => setFilters({ ...filters, status: e.target.value, page: 1 })}
              className="px-4 py-2 bg-medical-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-medical-accent"
            >
              <option value="">All Status</option>
              <option value="Pending">Pending</option>
              <option value="InProgress">In Progress</option>
              <option value="Reported">Reported</option>
            </select>

            <button
              onClick={() => setFilters({ searchTerm: '', modality: '', status: '', page: 1, pageSize: 20 })}
              className="px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg transition"
            >
              Clear Filters
            </button>
          </div>
        </div>

        {isLoading ? (
          <div className="text-center py-12">Loading...</div>
        ) : (
          <>
            <div className="bg-medical-dark rounded-lg shadow-lg overflow-hidden">
              <table className="w-full">
                <thead className="bg-medical-darker">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Patient</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">MRN</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Study Date</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Modality</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Description</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-700">
                  {data?.studies?.map((study: any) => (
                    <tr key={study.studyId} className="hover:bg-medical-darker transition">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          {study.isPriority && (
                            <span className="text-red-500 mr-2">⚠</span>
                          )}
                          {study.patientName}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">{study.mrn}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                        {format(new Date(study.studyDate), 'yyyy-MM-dd')}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="px-2 py-1 text-xs font-semibold rounded-full bg-blue-900 text-blue-200">
                          {study.modality}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-300">{study.description}</td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                          study.status === 'Pending' ? 'bg-yellow-900 text-yellow-200' :
                          study.status === 'InProgress' ? 'bg-blue-900 text-blue-200' :
                          'bg-green-900 text-green-200'
                        }`}>
                          {study.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm space-x-2">
                        <button
                          onClick={() => handleViewStudy(study.studyId)}
                          className="text-medical-accent hover:text-blue-400"
                        >
                          View
                        </button>
                        <button
                          onClick={() => handleCreateReport(study.studyId)}
                          className="text-green-500 hover:text-green-400"
                        >
                          Report
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {data && (
              <div className="flex justify-between items-center">
                <div className="text-sm text-gray-400">
                  Showing {data.studies?.length || 0} of {data.totalCount} studies
                </div>
                <div className="flex space-x-2">
                  <button
                    disabled={filters.page === 1}
                    onClick={() => setFilters({ ...filters, page: filters.page - 1 })}
                    className="px-4 py-2 bg-medical-dark hover:bg-opacity-80 rounded-lg disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <button
                    disabled={filters.page >= data.totalPages}
                    onClick={() => setFilters({ ...filters, page: filters.page + 1 })}
                    className="px-4 py-2 bg-medical-dark hover:bg-opacity-80 rounded-lg disabled:opacity-50"
                  >
                    Next
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </Layout>
  )
}
