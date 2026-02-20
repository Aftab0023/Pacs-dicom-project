import { useEffect, useState } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'
import { HiArrowLeft, HiOutlineServer, HiOutlineExclamationCircle, HiExternalLink } from 'react-icons/hi'
import { RiDnaLine } from 'react-icons/ri'

export default function OHIFViewer() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const studyInstanceUIDs = searchParams.get('StudyInstanceUIDs')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  
  const ORTHANC_URL = import.meta.env.VITE_ORTHANC_URL || 'http://localhost:8042'

  useEffect(() => {
    if (!studyInstanceUIDs) {
      setError('No Study Instance UID provided. Access the viewer through the worklist.')
      setLoading(false)
      return
    }

    const findOrthancStudy = async () => {
      try {
        const response = await fetch(`${ORTHANC_URL}/tools/find`, {
          method: 'POST',
          headers: {
            'Authorization': 'Basic ' + btoa('orthanc:orthanc'),
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            Level: 'Study',
            Query: { StudyInstanceUID: studyInstanceUIDs }
          })
        })
        
        if (!response.ok) {
          setError('The Orthanc server is unreachable or returned an error.')
          setLoading(false)
          return
        }

        const studies = await response.json()
        if (studies.length === 0) {
          setError('Study not found in Orthanc database. Please ensure the DICOM files are uploaded.')
          setLoading(false)
          return
        }

        // Success - redirecting to OHIF
        const ohifUrl = `${ORTHANC_URL}/ohif/viewer?StudyInstanceUIDs=${encodeURIComponent(studyInstanceUIDs)}`
        window.location.href = ohifUrl
      } catch (err) {
        setError('Connection Refused: Ensure the Orthanc Docker container is running on port 8042.')
        setLoading(false)
      }
    }

    findOrthancStudy()
  }, [studyInstanceUIDs, navigate])

  // --- Loading State ---
  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-6 text-center">
        <div className="relative mb-8">
          {/* Pulsing background effect */}
          <div className="absolute inset-0 bg-blue-500/20 blur-3xl rounded-full animate-pulse"></div>
          <div className="relative bg-slate-900 p-6 rounded-3xl border border-blue-500/30 shadow-2xl">
            <RiDnaLine className="w-16 h-16 text-blue-500 animate-spin-slow" />
          </div>
        </div>
        <h2 className="text-2xl font-black text-white tracking-tight mb-2">Initializing OHIF Engine</h2>
        <p className="text-slate-400 max-w-xs leading-relaxed">
          Verifying DICOM availability and synchronizing with Orthanc PACS...
        </p>
        <div className="mt-8 flex gap-2">
            <div className="w-2 h-2 bg-blue-600 rounded-full animate-bounce [animation-delay:-0.3s]"></div>
            <div className="w-2 h-2 bg-blue-600 rounded-full animate-bounce [animation-delay:-0.15s]"></div>
            <div className="w-2 h-2 bg-blue-600 rounded-full animate-bounce"></div>
        </div>
      </div>
    )
  }

  // --- Error State ---
  if (error) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
        <div className="max-w-xl w-full bg-slate-900 rounded-[2.5rem] border border-slate-800 p-8 md:p-12 shadow-2xl">
          <div className="flex flex-col items-center text-center">
            <div className="p-4 bg-red-500/10 rounded-2xl border border-red-500/20 mb-6">
              <HiOutlineExclamationCircle className="w-12 h-12 text-red-500" />
            </div>
            <h2 className="text-2xl font-bold text-white mb-2">Launch Sequence Failed</h2>
            <p className="text-slate-400 text-sm mb-8 leading-relaxed">
              {error}
            </p>

            <div className="w-full bg-slate-950 border border-slate-800 rounded-2xl p-6 text-left mb-8 space-y-4">
              <div className="flex items-start gap-3">
                <HiOutlineServer className="text-blue-500 w-5 h-5 mt-0.5" />
                <div>
                  <p className="text-xs font-black uppercase tracking-widest text-slate-500 mb-1">Server Status</p>
                  <p className="text-sm text-slate-300 italic">Check Docker Desktop / Orthanc Logs</p>
                </div>
              </div>
              <div className="flex items-start gap-3">
                <HiExternalLink className="text-emerald-500 w-5 h-5 mt-0.5" />
                <div>
                  <p className="text-xs font-black uppercase tracking-widest text-slate-500 mb-1">Study Instance UID</p>
                  <code className="text-[10px] text-slate-500 break-all font-mono leading-tight">{studyInstanceUIDs}</code>
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 w-full">
              <button
                onClick={() => navigate('/worklist')}
                className="flex items-center justify-center gap-2 px-6 py-3.5 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-bold transition-all active:scale-95"
              >
                <HiArrowLeft /> Back to List
              </button>
              <button
                onClick={() => window.open(`${ORTHANC_URL}/app/explorer.html`, '_blank')}
                className="flex items-center justify-center gap-2 px-6 py-3.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-bold shadow-lg shadow-blue-900/20 transition-all active:scale-95"
              >
                Open Orthanc Explorer
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return null
}