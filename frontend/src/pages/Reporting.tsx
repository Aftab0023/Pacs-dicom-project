import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery, useMutation } from '@tanstack/react-query'
import { worklistApi, reportApi } from '../services/api'
import Layout from '../components/Layout'

export default function Reporting() {
  const { studyId } = useParams<{ studyId: string }>()
  const navigate = useNavigate()
  
  const [reportText, setReportText] = useState('')
  const [findings, setFindings] = useState('')
  const [impression, setImpression] = useState('')

  const { data: study } = useQuery({
    queryKey: ['study', studyId],
    queryFn: () => worklistApi.getStudyDetail(Number(studyId)),
    enabled: !!studyId
  })

  const { data: reports } = useQuery({
    queryKey: ['reports', studyId],
    queryFn: () => reportApi.getStudyReports(Number(studyId)),
    enabled: !!studyId
  })

  const createMutation = useMutation({
    mutationFn: (data: any) => reportApi.createReport(data),
    onSuccess: () => {
      alert('Report saved successfully')
    }
  })

  const handleSaveDraft = () => {
    createMutation.mutate({
      studyId: Number(studyId),
      reportText,
      findings,
      impression
    })
  }

  const handleFinalize = async () => {
    if (!window.confirm('Are you sure you want to finalize this report? This action cannot be undone.')) {
      return
    }

    const report = await createMutation.mutateAsync({
      studyId: Number(studyId),
      reportText,
      findings,
      impression
    })

    await reportApi.finalizeReport(report.reportId, 'Digital Signature')
    alert('Report finalized successfully')
    navigate('/worklist')
  }

  return (
    <Layout>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold">Radiology Report</h1>
          <button
            onClick={() => navigate(`/viewer/${studyId}`)}
            className="px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg"
          >
            View Images
          </button>
        </div>

        {study && (
          <div className="bg-medical-dark p-6 rounded-lg shadow-lg">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
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
          </div>
        )}

        <div className="bg-medical-dark p-6 rounded-lg shadow-lg space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Clinical History / Indication
            </label>
            <textarea
              value={reportText}
              onChange={(e) => setReportText(e.target.value)}
              rows={3}
              className="w-full px-4 py-2 bg-medical-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-medical-accent"
              placeholder="Enter clinical history..."
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Findings
            </label>
            <textarea
              value={findings}
              onChange={(e) => setFindings(e.target.value)}
              rows={8}
              className="w-full px-4 py-2 bg-medical-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-medical-accent"
              placeholder="Enter detailed findings..."
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">
              Impression
            </label>
            <textarea
              value={impression}
              onChange={(e) => setImpression(e.target.value)}
              rows={4}
              className="w-full px-4 py-2 bg-medical-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-medical-accent"
              placeholder="Enter impression/conclusion..."
            />
          </div>

          <div className="flex space-x-4">
            <button
              onClick={handleSaveDraft}
              disabled={createMutation.isPending}
              className="px-6 py-3 bg-blue-600 hover:bg-blue-700 rounded-lg font-semibold disabled:opacity-50"
            >
              Save Draft
            </button>
            <button
              onClick={handleFinalize}
              disabled={createMutation.isPending || !findings || !impression}
              className="px-6 py-3 bg-green-600 hover:bg-green-700 rounded-lg font-semibold disabled:opacity-50"
            >
              Finalize Report
            </button>
            <button
              onClick={() => navigate('/worklist')}
              className="px-6 py-3 bg-gray-700 hover:bg-gray-600 rounded-lg"
            >
              Cancel
            </button>
          </div>
        </div>

        {reports && reports.length > 0 && (
          <div className="bg-medical-dark p-6 rounded-lg shadow-lg">
            <h2 className="text-xl font-semibold mb-4">Previous Reports</h2>
            <div className="space-y-4">
              {reports.map((report: any) => (
                <div key={report.reportId} className="bg-medical-darker p-4 rounded-lg">
                  <div className="flex justify-between mb-2">
                    <span className="font-semibold">{report.radiologistName}</span>
                    <span className={`px-2 py-1 text-xs rounded ${
                      report.status === 'Final' ? 'bg-green-900 text-green-200' : 'bg-yellow-900 text-yellow-200'
                    }`}>
                      {report.status}
                    </span>
                  </div>
                  <div className="text-sm text-gray-400 mb-2">
                    {new Date(report.createdAt).toLocaleString()}
                  </div>
                  <div className="text-sm">
                    <div className="mb-2">
                      <strong>Findings:</strong> {report.findings}
                    </div>
                    <div>
                      <strong>Impression:</strong> {report.impression}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </Layout>
  )
}
