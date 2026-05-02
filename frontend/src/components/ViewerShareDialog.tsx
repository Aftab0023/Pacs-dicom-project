import { useState } from 'react'
import { viewerSharingApi } from '../services/api'
import { HiX, HiLink, HiMail, HiClipboardCopy, HiCheck } from 'react-icons/hi'

interface ViewerShareDialogProps {
  studyInstanceUID: string
  patientEmail?: string
  onClose: () => void
}

export default function ViewerShareDialog({ studyInstanceUID, patientEmail, onClose }: ViewerShareDialogProps) {
  const [email, setEmail]         = useState(patientEmail || '')
  const [message, setMessage]     = useState('')
  const [expiresIn, setExpiresIn] = useState(24)
  const [shareLink, setShareLink] = useState('')
  const [loading, setLoading]     = useState(false)
  const [copied, setCopied]       = useState(false)
  const [error, setError]         = useState('')
  const [success, setSuccess]     = useState('')

  const handleGenerateLink = async () => {
    setLoading(true); setError('')
    try {
      const res = await viewerSharingApi.createShareLink(studyInstanceUID, expiresIn)
      setShareLink(res.shareUrl)
      setSuccess('Share link generated!')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to generate link')
    } finally { setLoading(false) }
  }

  const handleSendToPatient = async () => {
    if (!email) { setError('Please enter patient email'); return }
    setLoading(true); setError('')
    try {
      await viewerSharingApi.sendToPatient(studyInstanceUID, email, message)
      setSuccess('Study link sent to patient!')
      setTimeout(() => onClose(), 2000)
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to send to patient')
    } finally { setLoading(false) }
  }

  const handleCopy = () => {
    navigator.clipboard.writeText(shareLink)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    // Backdrop
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/70 backdrop-blur-sm p-0 sm:p-4"
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      {/* Dialog — full screen on mobile, modal on sm+ */}
      <div className="relative w-full sm:max-w-lg bg-slate-900 border border-slate-700 rounded-t-3xl sm:rounded-3xl shadow-2xl flex flex-col max-h-[92dvh] sm:max-h-[90vh] overflow-hidden">

        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-800 shrink-0">
          <h2 className="text-lg font-bold text-white">Share Study</h2>
          <button
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
          >
            <HiX size={20} />
          </button>
        </div>

        {/* Scrollable body */}
        <div className="overflow-y-auto flex-1 px-5 py-4 space-y-4">

          {/* Alerts */}
          {error && (
            <div className="p-3 bg-red-500/10 border border-red-500/30 text-red-400 rounded-xl text-sm">{error}</div>
          )}
          {success && (
            <div className="p-3 bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 rounded-xl text-sm">{success}</div>
          )}

          {/* Generate Link */}
          <div className="bg-slate-800/50 border border-slate-700 rounded-2xl p-4 space-y-3">
            <div className="flex items-center gap-2 mb-1">
              <HiLink className="text-blue-400" size={18} />
              <h3 className="text-sm font-bold text-white">Generate Share Link</h3>
            </div>

            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1.5">Expires in</label>
              <select
                value={expiresIn}
                onChange={(e) => setExpiresIn(Number(e.target.value))}
                className="w-full px-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-white text-sm focus:ring-2 focus:ring-blue-500/50 outline-none"
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
              className="w-full py-2.5 bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white rounded-xl text-sm font-bold transition-colors"
            >
              {loading ? 'Generating...' : 'Generate Link'}
            </button>

            {shareLink && (
              <div className="space-y-1.5">
                <label className="block text-xs font-medium text-slate-400">Share Link</label>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={shareLink}
                    readOnly
                    className="flex-1 min-w-0 px-3 py-2 bg-slate-900 border border-slate-700 rounded-xl text-slate-300 text-xs font-mono outline-none"
                  />
                  <button
                    onClick={handleCopy}
                    className="shrink-0 px-3 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-xl transition-colors"
                    title="Copy"
                  >
                    {copied ? <HiCheck size={16} className="text-emerald-400" /> : <HiClipboardCopy size={16} />}
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Send to Patient */}
          <div className="bg-slate-800/50 border border-slate-700 rounded-2xl p-4 space-y-3">
            <div className="flex items-center gap-2 mb-1">
              <HiMail className="text-emerald-400" size={18} />
              <h3 className="text-sm font-bold text-white">Send to Patient</h3>
            </div>

            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1.5">Patient Email *</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="patient@example.com"
                className="w-full px-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-white text-sm focus:ring-2 focus:ring-emerald-500/50 outline-none"
              />
            </div>

            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1.5">Message (optional)</label>
              <textarea
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Add a personal message..."
                rows={3}
                className="w-full px-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-white text-sm focus:ring-2 focus:ring-emerald-500/50 outline-none resize-none"
              />
            </div>

            <button
              onClick={handleSendToPatient}
              disabled={loading || !email}
              className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-50 text-white rounded-xl text-sm font-bold transition-colors"
            >
              {loading ? 'Sending...' : 'Send to Patient'}
            </button>

            <p className="text-xs text-slate-500 leading-relaxed">
              Patient receives a secure link valid for {expiresIn}h to view their study.
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="px-5 py-3 border-t border-slate-800 shrink-0">
          <button
            onClick={onClose}
            className="w-full py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-sm font-medium transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  )
}
