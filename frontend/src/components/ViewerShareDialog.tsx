import { useState } from 'react'
import { viewerSharingApi } from '../services/api'

interface ViewerShareDialogProps {
  studyInstanceUID: string
  patientEmail?: string
  onClose: () => void
}

export default function ViewerShareDialog({ studyInstanceUID, patientEmail, onClose }: ViewerShareDialogProps) {
  const [email, setEmail] = useState(patientEmail || '')
  const [message, setMessage] = useState('')
  const [expiresIn, setExpiresIn] = useState(24)
  const [shareLink, setShareLink] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const handleGenerateLink = async () => {
    setLoading(true)
    setError('')
    try {
      const response = await viewerSharingApi.createShareLink(studyInstanceUID, expiresIn)
      setShareLink(response.shareUrl)
      setSuccess('Share link generated successfully!')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to generate share link')
    } finally {
      setLoading(false)
    }
  }

  const handleSendToPatient = async () => {
    if (!email) {
      setError('Please enter patient email')
      return
    }

    setLoading(true)
    setError('')
    try {
      await viewerSharingApi.sendToPatient(studyInstanceUID, email, message)
      setSuccess('Study link sent to patient successfully!')
      setTimeout(() => onClose(), 2000)
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to send to patient')
    } finally {
      setLoading(false)
    }
  }

  const handleCopyLink = () => {
    navigator.clipboard.writeText(shareLink)
    setSuccess('Link copied to clipboard!')
    setTimeout(() => setSuccess(''), 2000)
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-gray-800 rounded-lg p-6 max-w-2xl w-full mx-4">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-2xl font-bold text-white">Share OHIF Viewer</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-white"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-900 border border-red-700 text-red-200 rounded">
            {error}
          </div>
        )}

        {success && (
          <div className="mb-4 p-3 bg-green-900 border border-green-700 text-green-200 rounded">
            {success}
          </div>
        )}

        <div className="space-y-6">
          {/* Generate Share Link Section */}
          <div className="border border-gray-700 rounded-lg p-4">
            <h3 className="text-lg font-semibold text-white mb-4">Generate Share Link</h3>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Link Expires In (hours)
              </label>
              <select
                value={expiresIn}
                onChange={(e) => setExpiresIn(Number(e.target.value))}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
              >
                <option value={1}>1 hour</option>
                <option value={6}>6 hours</option>
                <option value={12}>12 hours</option>
                <option value={24}>24 hours</option>
                <option value={48}>48 hours</option>
                <option value={168}>7 days</option>
              </select>
            </div>

            <button
              onClick={handleGenerateLink}
              disabled={loading}
              className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded disabled:opacity-50"
            >
              {loading ? 'Generating...' : 'Generate Link'}
            </button>

            {shareLink && (
              <div className="mt-4">
                <label className="block text-sm font-medium text-gray-300 mb-2">
                  Share Link
                </label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={shareLink}
                    readOnly
                    className="flex-1 px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                  />
                  <button
                    onClick={handleCopyLink}
                    className="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded"
                  >
                    Copy
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Send to Patient Section */}
          <div className="border border-gray-700 rounded-lg p-4">
            <h3 className="text-lg font-semibold text-white mb-4">Send to Patient</h3>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Patient Email *
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="patient@example.com"
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
              />
            </div>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Message (Optional)
              </label>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Add a personal message for the patient..."
                rows={3}
                className="w-full px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
              />
            </div>

            <button
              onClick={handleSendToPatient}
              disabled={loading || !email}
              className="w-full px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded disabled:opacity-50"
            >
              {loading ? 'Sending...' : 'Send to Patient'}
            </button>

            <p className="mt-3 text-sm text-gray-400">
              The patient will receive an email with a secure link to view their study in the OHIF viewer.
              The link will expire in {expiresIn} hours.
            </p>
          </div>
        </div>

        <div className="mt-6 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  )
}
