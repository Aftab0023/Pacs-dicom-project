import { useParams, useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { worklistApi } from '../services/api'
import Layout from '../components/Layout'

export default function StudyViewer() {
  const { studyId } = useParams<{ studyId: string }>()
  const navigate = useNavigate()

  const { data: study, isLoading } = useQuery({
    queryKey: ['study', studyId],
    queryFn: () => worklistApi.getStudyDetail(Number(studyId)),
    enabled: !!studyId
  })

  if (isLoading) {
    return (
      <Layout>
        <div className="text-center py-12">Loading study...</div>
      </Layout>
    )
  }

  if (!study) {
    return (
      <Layout>
        <div className="text-center py-12">Study not found</div>
      </Layout>
    )
  }

  const orthancUrl = `http://localhost:8042/dicom-web`

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold">Study Viewer</h1>
          <button
            onClick={() => navigate('/worklist')}
            className="px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg"
          >
            Back to Worklist
          </button>
        </div>

        <div className="bg-medical-dark p-6 rounded-lg shadow-lg">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            <div>
              <div className="text-sm text-gray-400">Patient</div>
              <div className="font-semibold">{study.patient.firstName} {study.patient.lastName}</div>
            </div>
            <div>
              <div className="text-sm text-gray-400">MRN</div>
              <div className="font-semibold">{study.patient.mrn}</div>
            </div>
            <div>
              <div className="text-sm text-gray-400">Study Date</div>
              <div className="font-semibold">{new Date(study.studyDate).toLocaleDateString()}</div>
            </div>
            <div>
              <div className="text-sm text-gray-400">Modality</div>
              <div className="font-semibold">{study.modality}</div>
            </div>
          </div>

          <div className="mb-4">
            <div className="text-sm text-gray-400">Description</div>
            <div>{study.description}</div>
          </div>

          <div className="mb-4">
            <div className="text-sm text-gray-400 mb-2">Series ({study.series.length})</div>
            <div className="space-y-2">
              {study.series.map((series: any) => (
                <div key={series.seriesId} className="bg-medical-darker p-3 rounded">
                  <div className="flex justify-between">
                    <span>Series {series.seriesNumber}: {series.description}</span>
                    <span className="text-gray-400">{series.instanceCount} images</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="bg-medical-dark rounded-lg shadow-lg overflow-hidden" style={{ height: '600px' }}>
          <div className="h-full flex items-center justify-center text-gray-400">
            <div className="text-center">
              <p className="mb-4">OHIF Viewer Integration</p>
              <p className="text-sm">DICOMweb URL: {orthancUrl}</p>
              <p className="text-sm">Study UID: {study.studyInstanceUID}</p>
              <button
                onClick={() => window.open(`http://localhost:3000/viewer?StudyInstanceUIDs=${study.studyInstanceUID}`, '_blank')}
                className="mt-4 px-6 py-3 bg-medical-accent hover:bg-blue-600 rounded-lg"
              >
                Open in OHIF Viewer
              </button>
            </div>
          </div>
        </div>

        <div className="flex space-x-4">
          <button
            onClick={() => navigate(`/report/${studyId}`)}
            className="px-6 py-3 bg-green-600 hover:bg-green-700 rounded-lg font-semibold"
          >
            Create Report
          </button>
        </div>
      </div>
    </Layout>
  )
}
