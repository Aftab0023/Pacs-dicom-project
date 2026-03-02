import { useParams } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { viewerSharingApi } from '../services/api'
import { HiOutlineExclamationCircle, HiOutlineClock } from 'react-icons/hi'

export default function SharedViewer() {
  const { token } = useParams<{ token: string }>()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [shareData, setShareData] = useState<any>(null)
  
  const ORTHANC_URL = import.meta.env.VITE_ORTHANC_URL || 'http://localhost:8042'

  useEffect(() => {
    const validateAndLoadShare = async () => {
      if (!token) {
        setError('Invalid share link')
        setLoading(false)
        return
      }

      try {
        const response = await viewerSharingApi.getShareLink(token)
        setShareData(response)
        
        // Automatically redirect to OHIF viewer
        if (response.studyInstanceUID) {
          window.location.href = `${ORTHANC_URL}/ohif/viewer?StudyInstanceUIDs=${response.studyInstanceUID}`
        }
      } catch (err: any) {
        setError(err.response?.data?.message || 'Failed to load shared study')
      } finally {
        setLoading(false)
      }
    }

    validateAndLoadShare()
  }, [token])

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
          <p className="text-slate-400 font-medium">Loading shared study...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
        <div className="max-w-md w-full bg-slate-900 border border-red-500/20 rounded-2xl p-8 text-center">
          <div className="bg-red-500/10 p-4 rounded-full inline-block mb-4">
            <HiOutlineExclamationCircle className="text-red-500 w-12 h-12" />
          </div>
          <h2 className="text-red-400 text-xl font-bold mb-2">Access Denied</h2>
          <p className="text-slate-400">{error}</p>
          <div className="mt-6 text-sm text-slate-500">
            <p>This link may have expired or been revoked.</p>
            <p className="mt-2">Please contact your healthcare provider for assistance.</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-slate-900 border border-slate-800 rounded-2xl p-8 text-center">
        <div className="bg-blue-500/10 p-4 rounded-full inline-block mb-4">
          <HiOutlineClock className="text-blue-500 w-12 h-12" />
        </div>
        <h2 className="text-white text-xl font-bold mb-2">Redirecting to Viewer...</h2>
        <p className="text-slate-400">Please wait while we load your medical images.</p>
        
        {shareData?.customMessage && (
          <div className="mt-6 p-4 bg-slate-800 rounded-lg">
            <p className="text-sm text-slate-300">{shareData.customMessage}</p>
          </div>
        )}
      </div>
    </div>
  )
}
