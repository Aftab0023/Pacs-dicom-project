import { useEffect, useState } from 'react'
import { useSearchParams, useNavigate } from 'react-router-dom'

export default function OHIFViewer() {
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const studyInstanceUIDs = searchParams.get('StudyInstanceUIDs')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!studyInstanceUIDs) {
      setError('No Study UID provided')
      setLoading(false)
      return
    }

    // Find the Orthanc study ID from StudyInstanceUID
    const findOrthancStudy = async () => {
      try {
        const response = await fetch(`http://localhost:8042/tools/find`, {
          method: 'POST',
          headers: {
            'Authorization': 'Basic ' + btoa('orthanc:orthanc'),
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            Level: 'Study',
            Query: {
              StudyInstanceUID: studyInstanceUIDs
            }
          })
        })
        
        if (!response.ok) {
          setError('Study not found in Orthanc')
          setLoading(false)
          return
        }

        const studies = await response.json()
        if (studies.length === 0) {
          setError('Study not found in Orthanc. Please upload the DICOM study first.')
          setLoading(false)
          return
        }

        // Study found - redirect to OHIF in new window
        const ohifUrl = `http://localhost:8042/ohif/viewer?StudyInstanceUIDs=${encodeURIComponent(studyInstanceUIDs)}`
        window.location.href = ohifUrl
      } catch (err) {
        setError('Cannot connect to Orthanc server')
        setLoading(false)
      }
    }

    findOrthancStudy()
  }, [studyInstanceUIDs, navigate])

  if (loading) {
    return (
      <div className="min-h-screen bg-medical-darker flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-medical-accent mx-auto mb-4"></div>
          <p className="text-gray-400">Loading DICOM Viewer...</p>
          <p className="text-sm text-gray-500 mt-2">Redirecting to OHIF Viewer...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-medical-darker flex items-center justify-center">
        <div className="text-center max-w-2xl p-8 bg-medical-dark rounded-lg">
          <div className="text-red-500 text-xl mb-4">⚠️ Viewer Error</div>
          <p className="text-gray-400 mb-6">{error}</p>
          
          <div className="space-y-4 text-left bg-medical-darker p-6 rounded">
            <p className="text-sm text-gray-300 font-semibold">Troubleshooting:</p>
            <ul className="text-sm text-gray-400 space-y-2 list-disc list-inside">
              <li>Verify Orthanc is running: <a href="http://localhost:8042" target="_blank" rel="noreferrer" className="text-blue-400 hover:underline">http://localhost:8042</a></li>
              <li>Check if study exists in Orthanc Explorer</li>
              <li>Study UID: <code className="bg-black px-2 py-1 rounded text-xs break-all">{studyInstanceUIDs}</code></li>
              <li>Upload DICOM files to Orthanc if not already uploaded</li>
            </ul>
          </div>

          <div className="flex gap-4 justify-center mt-6">
            <button
              onClick={() => navigate('/worklist')}
              className="px-6 py-3 bg-medical-accent hover:bg-blue-600 rounded-lg"
            >
              Back to Worklist
            </button>
            <button
              onClick={() => window.open('http://localhost:8042/app/explorer.html', '_blank')}
              className="px-6 py-3 bg-gray-700 hover:bg-gray-600 rounded-lg"
            >
              Open Orthanc Explorer
            </button>
          </div>
        </div>
      </div>
    )
  }

  return null
}

