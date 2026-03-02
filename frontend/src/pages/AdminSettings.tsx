import { useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { systemSettingsApi } from '../services/api'
import Layout from '../components/Layout'
import { HiSave, HiRefresh } from 'react-icons/hi'

export default function AdminSettings() {
  const queryClient = useQueryClient()
  const [activeTab, setActiveTab] = useState('report')
  const [logoPreview, setLogoPreview] = useState<string | null>(null)

  const { data: reportSettings, isLoading } = useQuery({
    queryKey: ['report-settings'],
    queryFn: systemSettingsApi.getReportSettings
  })

  const [formData, setFormData] = useState(reportSettings || {})

  // Update form when data loads
  useEffect(() => {
    if (reportSettings) {
      setFormData(reportSettings)
      setLogoPreview(reportSettings.logoUrl || null)
    }
  }, [reportSettings])

  const updateMutation = useMutation({
    mutationFn: systemSettingsApi.updateReportSettings,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['report-settings'] })
      alert('Settings saved successfully!')
    },
    onError: () => {
      alert('Failed to save settings')
    }
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    updateMutation.mutate(formData)
  }

  const handleReset = () => {
    setFormData(reportSettings)
    setLogoPreview(reportSettings?.logoUrl || null)
  }

  const handleLogoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      // Validate file type
      if (!file.type.startsWith('image/')) {
        alert('Please upload an image file')
        return
      }

      // Validate file size (max 2MB)
      if (file.size > 2 * 1024 * 1024) {
        alert('Image size should be less than 2MB')
        return
      }

      // Convert to base64
      const reader = new FileReader()
      reader.onloadend = () => {
        const base64String = reader.result as string
        setLogoPreview(base64String)
        setFormData({ ...formData, logoUrl: base64String })
      }
      reader.readAsDataURL(file)
    }
  }

  const handleRemoveLogo = () => {
    setLogoPreview(null)
    setFormData({ ...formData, logoUrl: '' })
  }

  if (isLoading) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="max-w-5xl mx-auto space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-white">System Settings</h1>
          <p className="text-slate-400 mt-1">Configure system-wide settings and report customization</p>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 border-b border-slate-800">
          <button
            onClick={() => setActiveTab('report')}
            className={`px-6 py-3 font-semibold transition-colors ${
              activeTab === 'report'
                ? 'text-blue-400 border-b-2 border-blue-400'
                : 'text-slate-400 hover:text-slate-300'
            }`}
          >
            Report Settings
          </button>
        </div>

        {/* Report Settings Tab */}
        {activeTab === 'report' && (
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
              <h2 className="text-xl font-bold text-white mb-6">Institution Information</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Institution Name *
                  </label>
                  <input
                    type="text"
                    value={formData.institutionName || ''}
                    onChange={(e) => setFormData({ ...formData, institutionName: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
                    placeholder="Life Relief Medical PACS"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Report Title *
                  </label>
                  <input
                    type="text"
                    value={formData.reportTitle || ''}
                    onChange={(e) => setFormData({ ...formData, reportTitle: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
                    placeholder="Radiology Report"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Department Name
                  </label>
                  <input
                    type="text"
                    value={formData.departmentName || ''}
                    onChange={(e) => setFormData({ ...formData, departmentName: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
                    placeholder="Department of Radiology"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Institution Email
                  </label>
                  <input
                    type="email"
                    value={formData.institutionEmail || ''}
                    onChange={(e) => setFormData({ ...formData, institutionEmail: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
                    placeholder="radiology@hospital.com"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Institution Phone
                  </label>
                  <input
                    type="tel"
                    value={formData.institutionPhone || ''}
                    onChange={(e) => setFormData({ ...formData, institutionPhone: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
                    placeholder="+1 (555) 123-4567"
                  />
                </div>

                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Institution Logo
                  </label>
                  
                  {/* Logo Preview */}
                  {logoPreview && (
                    <div className="mb-4 p-4 bg-slate-800 border border-slate-700 rounded-lg">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-xs text-slate-400">Current Logo</span>
                        <button
                          type="button"
                          onClick={handleRemoveLogo}
                          className="text-xs text-red-400 hover:text-red-300"
                        >
                          Remove
                        </button>
                      </div>
                      <div className="flex justify-center p-4 bg-white rounded">
                        <img
                          src={logoPreview}
                          alt="Logo preview"
                          className="max-h-24 max-w-full object-contain"
                        />
                      </div>
                    </div>
                  )}

                  {/* Upload Button */}
                  <div className="flex items-center gap-3">
                    <label className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-lg text-white cursor-pointer transition-colors">
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                      </svg>
                      Upload Logo
                      <input
                        type="file"
                        accept="image/*"
                        onChange={handleLogoUpload}
                        className="hidden"
                      />
                    </label>
                    <span className="text-xs text-slate-500">
                      PNG, JPG or GIF (max 2MB)
                    </span>
                  </div>
                  <p className="text-xs text-slate-500 mt-2">
                    Logo will be displayed on reports and documents
                  </p>
                </div>
              </div>

              <div className="mt-6">
                <label className="block text-sm font-medium text-slate-300 mb-2">
                  Institution Address
                </label>
                <textarea
                  value={formData.institutionAddress || ''}
                  onChange={(e) => setFormData({ ...formData, institutionAddress: e.target.value })}
                  rows={2}
                  className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
                  placeholder="123 Medical Center Drive, Healthcare City"
                />
              </div>
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
              <h2 className="text-xl font-bold text-white mb-6">Report Customization</h2>
              
              <div className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Digital Signature Text
                  </label>
                  <input
                    type="text"
                    value={formData.digitalSignatureText || ''}
                    onChange={(e) => setFormData({ ...formData, digitalSignatureText: e.target.value })}
                    className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
                    placeholder="Electronically signed by"
                  />
                  <p className="text-xs text-slate-500 mt-1">
                    This text appears before the radiologist name in the signature section
                  </p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-300 mb-2">
                    Footer Text
                  </label>
                  <textarea
                    value={formData.footerText || ''}
                    onChange={(e) => setFormData({ ...formData, footerText: e.target.value })}
                    rows={3}
                    className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
                    placeholder="This report is confidential..."
                  />
                </div>

                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    id="showWatermark"
                    checked={formData.showWatermark || false}
                    onChange={(e) => setFormData({ ...formData, showWatermark: e.target.checked })}
                    className="w-5 h-5 rounded border-slate-700 bg-slate-800 text-blue-600"
                  />
                  <label htmlFor="showWatermark" className="text-sm font-medium text-slate-300">
                    Show watermark on reports
                  </label>
                </div>

                {formData.showWatermark && (
                  <div>
                    <label className="block text-sm font-medium text-slate-300 mb-2">
                      Watermark Text
                    </label>
                    <input
                      type="text"
                      value={formData.watermarkText || ''}
                      onChange={(e) => setFormData({ ...formData, watermarkText: e.target.value })}
                      className="w-full px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white"
                      placeholder="CONFIDENTIAL"
                    />
                  </div>
                )}
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={handleReset}
                className="flex items-center gap-2 px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-semibold transition-colors"
              >
                <HiRefresh size={20} />
                Reset
              </button>
              <button
                type="submit"
                disabled={updateMutation.isPending}
                className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-semibold transition-colors disabled:opacity-50"
              >
                <HiSave size={20} />
                {updateMutation.isPending ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </form>
        )}
      </div>
    </Layout>
  )
}
