import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { worklistApi, reportApi } from '../services/api' // Added reportApi
import Layout from '../components/Layout'
import { format } from 'date-fns'
import { HiOutlinePrinter, HiOutlineEye, HiOutlineDocumentText } from 'react-icons/hi'

// UI Icons (Simple SVG versions)
const SearchIcon = () => <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
const UrgencyIcon = () => <svg className="w-4 h-4 text-red-500 animate-pulse" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" /></svg>

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

  // Corrected handleDownload logic for the Worklist
  const handleDownload = async (studyId: number) => {
    try {
      // In a real scenario, you'd fetch the specific report ID for the study
      const blob = await reportApi.downloadPdf(studyId); 
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Study-Report-${studyId}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } catch (err) {
      alert("Could not generate PDF. The report might not be finalized yet.");
    }
  };

  return (
    <Layout>
      <div className="max-w-[1600px] mx-auto space-y-6 pb-10">
        <header className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-2xl md:text-3xl font-extrabold text-white tracking-tight">Study Worklist</h1>
            <p className="text-slate-400 text-sm">Manage and review patient diagnostic imaging</p>
          </div>
          <div className="bg-slate-800/50 px-4 py-2 rounded-xl border border-slate-700">
             <span className="text-blue-400 font-bold">{data?.totalCount || 0}</span>
             <span className="text-slate-400 text-sm ml-2">Total Studies</span>
          </div>
        </header>

        {/* Filters Section */}
        <div className="bg-slate-900 p-4 md:p-6 rounded-2xl border border-slate-800 shadow-xl">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="relative">
              <div className="absolute inset-y-0 left-3 flex items-center pointer-events-none">
                <SearchIcon />
              </div>
              <input
                type="text"
                placeholder="Search MRN or Patient..."
                value={filters.searchTerm}
                onChange={(e) => setFilters({ ...filters, searchTerm: e.target.value, page: 1 })}
                className="w-full pl-10 pr-4 py-2.5 bg-slate-950 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-blue-500/50 outline-none"
              />
            </div>
            
            <select
              value={filters.modality}
              onChange={(e) => setFilters({ ...filters, modality: e.target.value, page: 1 })}
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-blue-500/50 outline-none"
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
              className="w-full px-4 py-2.5 bg-slate-950 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-blue-500/50 outline-none"
            >
              <option value="">All Statuses</option>
              <option value="Pending">🕒 Pending</option>
              <option value="InProgress">⚡ In Progress</option>
              <option value="Reported">✅ Reported</option>
            </select>

            <button
              onClick={() => setFilters({ searchTerm: '', modality: '', status: '', page: 1, pageSize: 20 })}
              className="w-full px-4 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl font-medium transition-colors"
            >
              Reset Filters
            </button>
          </div>
        </div>

        {isLoading ? (
          <div className="flex flex-col items-center justify-center py-20 space-y-4">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
            <p className="text-slate-400">Fetching studies...</p>
          </div>
        ) : (
          <div className="space-y-4">
            {/* Desktop Table */}
            <div className="hidden lg:block bg-slate-900 rounded-2xl border border-slate-800 shadow-2xl overflow-hidden">
              <table className="w-full text-left border-collapse">
                <thead className="bg-slate-800/50 border-b border-slate-700">
                  <tr>
                    <th className="px-6 py-4 text-xs font-bold text-slate-400 uppercase">Patient Details</th>
                    <th className="px-6 py-4 text-xs font-bold text-slate-400 uppercase">Date</th>
                    <th className="px-6 py-4 text-xs font-bold text-slate-400 uppercase">Modality</th>
                    <th className="px-6 py-4 text-xs font-bold text-slate-400 uppercase">Status</th>
                    <th className="px-6 py-4 text-xs font-bold text-slate-400 uppercase text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800">
                  {data?.studies?.map((study: any) => (
                    <tr key={study.studyId} className="hover:bg-blue-500/5 transition-colors group">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className={`p-2 rounded-lg ${study.isPriority ? 'bg-red-500/10' : 'bg-slate-800'}`}>
                            {study.isPriority ? <UrgencyIcon /> : <span className="text-slate-500 text-xs font-bold">ST</span>}
                          </div>
                          <div>
                            <div className="font-bold text-slate-100 group-hover:text-blue-400">{study.patientName}</div>
                            <div className="text-xs text-slate-500">MRN: {study.mrn}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm text-slate-300">{format(new Date(study.studyDate), 'MMM dd, yyyy')}</div>
                      </td>
                      <td className="px-6 py-4">
                        <span className="px-3 py-1 text-[10px] font-black rounded-md bg-blue-500/10 text-blue-400 border border-blue-500/20">
                          {study.modality}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <StatusBadge status={study.status} />
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex justify-end gap-2">
                          <button onClick={() => navigate(`/viewer/${study.studyId}`)} title="View Images" className="p-2 text-blue-400 hover:bg-blue-400/10 rounded-lg"><HiOutlineEye size={18}/></button>
                          <button onClick={() => navigate(`/report/${study.studyId}`)} title="Write Report" className="p-2 text-emerald-400 hover:bg-emerald-400/10 rounded-lg"><HiOutlineDocumentText size={18}/></button>
                          {study.status === 'Reported' && (
                            <button onClick={() => handleDownload(study.studyId)} title="Print PDF" className="p-2 text-slate-400 hover:bg-slate-400/10 rounded-lg"><HiOutlinePrinter size={18}/></button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Mobile Cards */}
            <div className="lg:hidden space-y-4">
              {data?.studies?.map((study: any) => (
                <div key={study.studyId} className="bg-slate-900 p-5 rounded-2xl border border-slate-800 shadow-lg">
                  <div className="flex justify-between items-start mb-4">
                    <div className="flex items-center gap-3">
                      {study.isPriority && <UrgencyIcon />}
                      <div>
                        <h3 className="font-bold text-slate-100">{study.patientName}</h3>
                        <p className="text-[10px] text-slate-500 font-mono">{study.mrn}</p>
                      </div>
                    </div>
                    <StatusBadge status={study.status} />
                  </div>
                  <div className="flex justify-between text-xs text-slate-400 mb-4 bg-slate-950 p-3 rounded-xl border border-slate-800">
                    <span>Modality: <b className="text-blue-400">{study.modality}</b></span>
                    <span>{format(new Date(study.studyDate), 'MM/dd/yy')}</span>
                  </div>
                  <div className="flex gap-2">
                    <button onClick={() => navigate(`/viewer/${study.studyId}`)} className="flex-1 bg-blue-600 py-2.5 rounded-xl text-white font-bold text-sm shadow-lg shadow-blue-900/20">View</button>
                    <button onClick={() => navigate(`/report/${study.studyId}`)} className="flex-1 bg-slate-800 py-2.5 rounded-xl text-white font-bold text-sm">Report</button>
                    {study.status === 'Reported' && (
                      <button onClick={() => handleDownload(study.studyId)} className="bg-slate-800 p-2.5 rounded-xl text-slate-400 border border-slate-700">
                        <HiOutlinePrinter size={20} />
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {/* Pagination */}
            <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-4">
              <p className="text-xs text-slate-500">Showing page {filters.page} of {data?.totalPages || 1}</p>
              <div className="flex gap-2">
                <button disabled={filters.page === 1} onClick={() => setFilters({ ...filters, page: filters.page - 1 })} className="px-6 py-2 bg-slate-800 text-white rounded-xl disabled:opacity-30">Prev</button>
                <button disabled={filters.page >= (data?.totalPages || 1)} onClick={() => setFilters({ ...filters, page: filters.page + 1 })} className="px-6 py-2 bg-blue-600 text-white rounded-xl disabled:opacity-30 shadow-lg shadow-blue-900/20">Next</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </Layout>
  )
}

function StatusBadge({ status }: { status: string }) {
  const styles: Record<string, string> = {
    Pending: 'bg-amber-500/10 text-amber-500 border-amber-500/20',
    InProgress: 'bg-blue-500/10 text-blue-500 border-blue-500/20',
    Reported: 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20',
  }
  return (
    <span className={`px-2.5 py-0.5 text-[10px] font-bold rounded-full border ${styles[status] || styles.Pending}`}>
      {status}
    </span>
  )
}