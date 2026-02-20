import { useParams, useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { worklistApi } from '../services/api'
import Layout from '../components/Layout'
import { 
  HiArrowLeft, 
  HiOutlineUser, 
  HiOutlineCalendar, 
  HiOutlineIdentification,
  HiOutlineCube,
  HiExternalLink,
  HiOutlineDocumentText
} from 'react-icons/hi'

import { MdOutlineScreenSearchDesktop } from 'react-icons/md'

export default function StudyViewer() {
  const { studyId } = useParams<{ studyId: string }>()
  const navigate = useNavigate()
  
  const ORTHANC_URL = import.meta.env.VITE_ORTHANC_URL || 'http://localhost:8042'

  const { data: study, isLoading } = useQuery({
    queryKey: ['study', studyId],
    queryFn: () => worklistApi.getStudyDetail(Number(studyId)),
    enabled: !!studyId
  })

  if (isLoading) {
    return (
      <Layout>
        <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
          <p className="text-slate-400 font-medium">Loading Medical Study...</p>
        </div>
      </Layout>
    )
  }

  if (!study) {
    return (
      <Layout>
        <div className="flex flex-col items-center justify-center min-h-[60vh]">
          <div className="bg-red-500/10 p-6 rounded-3xl border border-red-500/20 text-center">
            <h2 className="text-red-400 text-xl font-bold">Study Not Found</h2>
            <button onClick={() => navigate('/worklist')} className="mt-4 text-slate-300 underline">Return to Worklist</button>
          </div>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="max-w-[1600px] mx-auto space-y-6 pb-10">
        
        {/* Header Navigation */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div className="flex items-center gap-4">
            <button
              onClick={() => navigate('/worklist')}
              className="p-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl transition-all active:scale-95"
            >
              <HiArrowLeft size={20} />
            </button>
            <div>
              <h1 className="text-2xl font-black text-white tracking-tight">Diagnostic Viewer</h1>
              <p className="text-slate-500 text-sm font-medium uppercase tracking-widest">Internal PACS ID: {studyId}</p>
            </div>
          </div>
          
          <button
            onClick={() => navigate(`/report/${studyId}`)}
            className="flex items-center gap-2 px-6 py-3 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl font-bold shadow-lg shadow-emerald-900/20 transition-all active:scale-95 w-full sm:w-auto justify-center"
          >
            <HiOutlineDocumentText size={20} />
            Create Report
          </button>
        </div>

        {/* Patient Info Bar (Glassmorphism Effect) */}
        <div className="bg-slate-900/50 backdrop-blur-md border border-slate-800 p-6 rounded-3xl shadow-xl">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
            <InfoItem icon={<HiOutlineUser className="text-blue-400" />} label="Patient Name" value={`${study.patient.firstName} ${study.patient.lastName}`} />
            <InfoItem icon={<HiOutlineIdentification className="text-purple-400" />} label="MRN" value={study.patient.mrn} />
            <InfoItem icon={<HiOutlineCalendar className="text-emerald-400" />} label="Study Date" value={new Date(study.studyDate).toLocaleDateString(undefined, { dateStyle: 'long' })} />
            <InfoItem icon={<HiOutlineCube className="text-amber-400" />} label="Modality" value={study.modality} badge />
          </div>
          
          <div className="mt-6 pt-6 border-t border-slate-800/50 flex flex-col md:flex-row gap-4 justify-between">
            <div>
              <span className="text-slate-500 text-xs font-bold uppercase tracking-widest block mb-1">Study Description</span>
              <p className="text-slate-200 font-medium">{study.description || "No description provided."}</p>
            </div>
            <div className="text-right">
              <span className="text-slate-500 text-xs font-bold uppercase tracking-widest block mb-1">Study UID</span>
              <p className="text-slate-500 text-[10px] font-mono break-all">{study.studyInstanceUID}</p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* Series Sidebar */}
          <div className="lg:col-span-4 space-y-4">
            <h3 className="text-slate-400 text-xs font-black uppercase tracking-[0.2em] px-2">Series Explorer ({study.series.length})</h3>
            <div className="space-y-3 max-h-[600px] overflow-y-auto pr-2 scrollbar-thin scrollbar-thumb-slate-700">
              {study.series.map((series: any) => (
                <div key={series.seriesId} className="group bg-slate-900 border border-slate-800 p-4 rounded-2xl hover:border-blue-500/50 transition-all cursor-default">
                  <div className="flex justify-between items-start">
                    <div className="space-y-1">
                      <span className="text-[10px] bg-slate-800 text-slate-400 px-2 py-0.5 rounded uppercase font-bold">Series {series.seriesNumber}</span>
                      <p className="text-slate-200 font-semibold group-hover:text-blue-400 transition-colors">{series.description || 'Unnamed Series'}</p>
                    </div>
                    <span className="text-blue-500 text-xs font-bold bg-blue-500/10 px-2 py-1 rounded-lg">{series.instanceCount} Img</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Viewer Preview Area */}
          <div className="lg:col-span-8">
            <div className="bg-slate-950 border-2 border-dashed border-slate-800 rounded-3xl h-[600px] flex flex-col items-center justify-center p-8 text-center relative overflow-hidden">
              {/* Decorative background icon */}
              <MdOutlineScreenSearchDesktop className="absolute text-slate-900 -bottom-10 -right-10 w-64 h-64 -z-0" />
              
              <div className="relative z-10 space-y-6">
                <div className="bg-blue-600/10 p-5 rounded-full inline-block border border-blue-600/20">
                  <MdOutlineScreenSearchDesktop className="text-blue-500 w-12 h-12" />
                </div>
                <div>
                  <h2 className="text-white text-xl font-bold mb-2">OHIF Integration Ready</h2>
                  <p className="text-slate-400 text-sm max-w-sm mx-auto leading-relaxed">
                    Launch the full diagnostic viewer to interact with DICOM layers, 3D reconstructions, and measurement tools.
                  </p>
                </div>
                
                <button
                  onClick={() => window.open(`${ORTHANC_URL}/ohif/viewer?StudyInstanceUIDs=${study.studyInstanceUID}`, '_blank')}
                  className="group flex items-center gap-3 px-8 py-4 bg-blue-600 hover:bg-blue-500 text-white rounded-2xl font-bold transition-all shadow-xl shadow-blue-900/40 active:scale-95"
                >
                  Launch Full Viewer
                  <HiExternalLink size={20} className="group-hover:translate-x-1 group-hover:-translate-y-1 transition-transform" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  )
}

// Helper Components
function InfoItem({ icon, label, value, badge }: any) {
  return (
    <div className="flex items-start gap-4">
      <div className="mt-1 p-2 bg-slate-800 rounded-xl">{icon}</div>
      <div>
        <span className="text-slate-500 text-[10px] font-black uppercase tracking-widest block mb-0.5">{label}</span>
        {badge ? (
          <span className="inline-block px-3 py-0.5 bg-blue-500/10 text-blue-400 border border-blue-500/20 rounded-md text-sm font-bold tracking-tight">
            {value}
          </span>
        ) : (
          <p className="text-slate-100 font-bold text-lg">{value}</p>
        )}
      </div>
    </div>
  )
}