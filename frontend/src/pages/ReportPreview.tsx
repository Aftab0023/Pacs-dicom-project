import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../services/api';

interface ReportData {
  reportId: number;
  studyId: number;
  radiologistName: string;
  status: string;
  reportText: string;
  findings: string;
  impression: string;
  createdAt: string;
  finalizedAt?: string;
  study?: {
    studyInstanceUID: string;
    studyDate: string;
    modality: string;
    description: string;
    patient: {
      firstName: string;
      lastName: string;
      mrn: string;
      dateOfBirth: string;
      gender: string;
    };
  };
}

interface SystemSettings {
  institutionName: string;
  institutionAddress: string;
  institutionPhone: string;
  institutionEmail: string;
  departmentName: string;
  reportTitle: string;
  digitalSignatureText: string;
  footerText: string;
  logoUrl: string;
}

export default function ReportPreview() {
  const { reportId } = useParams<{ reportId: string }>();
  const navigate = useNavigate();
  const [report, setReport] = useState<ReportData | null>(null);
  const [settings, setSettings] = useState<SystemSettings | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadReportData();
  }, [reportId]);

  const loadReportData = async () => {
    try {
      // Load report with study and patient data included
      const reportResponse = await api.get(`/report/${reportId}`);
      const reportData = reportResponse.data;

      setReport(reportData);

      // Load system settings
      try {
        const settingsResponse = await api.get('/systemsettings/report');
        setSettings(settingsResponse.data);
      } catch (err) {
        // Use defaults if settings not available
        setSettings({
          institutionName: 'Medical Institution',
          institutionAddress: '',
          institutionPhone: '',
          institutionEmail: '',
          departmentName: 'Radiology Department',
          reportTitle: 'Radiology Report',
          digitalSignatureText: 'Electronically Signed By',
          footerText: 'This is a confidential medical report',
          logoUrl: ''
        });
      }

      setLoading(false);
    } catch (error) {
      console.error('Error loading report:', error);
      alert('Failed to load report. Please check console for details.');
      navigate('/reporting');
    }
  };

  const handlePrint = () => {
    window.print();
  };

  const handleDownloadPDF = () => {
    // Use browser's print to PDF functionality
    window.print();
  };

  if (loading || !report || !settings) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading report...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Action Bar - Hidden when printing */}
      <div className="bg-white border-b border-gray-200 p-4 print:hidden sticky top-0 z-10 shadow-sm">
        <div className="max-w-5xl mx-auto flex justify-between items-center">
          <button
            onClick={() => navigate('/reporting')}
            className="px-4 py-2 text-gray-600 hover:text-gray-800 flex items-center gap-2"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            Back to Reports
          </button>
          <div className="flex gap-3">
            <button
              onClick={handlePrint}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
              </svg>
              Print
            </button>
            <button
              onClick={handleDownloadPDF}
              className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 flex items-center gap-2"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Save as PDF
            </button>
          </div>
        </div>
      </div>

      {/* Report Content - Printable */}
      <div className="max-w-5xl mx-auto bg-white shadow-lg my-8 print:my-0 print:shadow-none">
        <div className="p-12 print:p-8">
          {/* Header */}
          <div className="border-b-4 border-blue-600 pb-6 mb-8">
            <div className="flex justify-between items-start">
              <div>
                <h1 className="text-3xl font-bold text-blue-900 mb-2">
                  {settings.institutionName}
                </h1>
                <p className="text-lg text-gray-700 font-semibold">{settings.departmentName}</p>
                {settings.institutionAddress && (
                  <p className="text-sm text-gray-600 mt-1">{settings.institutionAddress}</p>
                )}
                <div className="flex gap-4 mt-1">
                  {settings.institutionPhone && (
                    <p className="text-sm text-gray-600">Phone: {settings.institutionPhone}</p>
                  )}
                  {settings.institutionEmail && (
                    <p className="text-sm text-gray-600">Email: {settings.institutionEmail}</p>
                  )}
                </div>
              </div>
              {settings.logoUrl && (
                <div className="w-24 h-24 border-2 border-gray-300 rounded flex items-center justify-center">
                  <img src={settings.logoUrl} alt="Logo" className="max-w-full max-h-full" />
                </div>
              )}
            </div>
            <h2 className="text-2xl font-bold text-center text-blue-800 mt-6">
              {settings.reportTitle}
            </h2>
          </div>

          {/* Patient Information */}
          <div className="mb-6">
            <div className="bg-blue-50 border-l-4 border-blue-600 p-4 mb-3">
              <h3 className="text-lg font-bold text-blue-900 mb-3">PATIENT INFORMATION</h3>
            </div>
            <div className="grid grid-cols-2 gap-4 px-4">
              <div>
                <span className="font-semibold text-gray-700">Name:</span>{' '}
                <span className="text-gray-900">
                  {report.study?.patient.firstName} {report.study?.patient.lastName}
                </span>
              </div>
              <div>
                <span className="font-semibold text-gray-700">MRN:</span>{' '}
                <span className="text-gray-900">{report.study?.patient.mrn}</span>
              </div>
              <div>
                <span className="font-semibold text-gray-700">Date of Birth:</span>{' '}
                <span className="text-gray-900">
                  {report.study?.patient.dateOfBirth ? new Date(report.study.patient.dateOfBirth).toLocaleDateString() : 'N/A'}
                </span>
              </div>
              <div>
                <span className="font-semibold text-gray-700">Gender:</span>{' '}
                <span className="text-gray-900">{report.study?.patient.gender}</span>
              </div>
            </div>
          </div>

          {/* Study Information */}
          <div className="mb-6">
            <div className="bg-blue-50 border-l-4 border-blue-600 p-4 mb-3">
              <h3 className="text-lg font-bold text-blue-900 mb-3">STUDY INFORMATION</h3>
            </div>
            <div className="grid grid-cols-2 gap-4 px-4">
              <div>
                <span className="font-semibold text-gray-700">Study Date:</span>{' '}
                <span className="text-gray-900">
                  {report.study?.studyDate ? new Date(report.study.studyDate).toLocaleString() : 'N/A'}
                </span>
              </div>
              <div>
                <span className="font-semibold text-gray-700">Modality:</span>{' '}
                <span className="text-gray-900 font-bold">{report.study?.modality}</span>
              </div>
              <div className="col-span-2">
                <span className="font-semibold text-gray-700">Description:</span>{' '}
                <span className="text-gray-900">{report.study?.description}</span>
              </div>
              <div className="col-span-2">
                <span className="font-semibold text-gray-700 text-xs">Study UID:</span>{' '}
                <span className="text-gray-600 text-xs">{report.study?.studyInstanceUID}</span>
              </div>
            </div>
          </div>

          {/* Clinical History */}
          {report.reportText && (
            <div className="mb-6">
              <div className="bg-blue-50 border-l-4 border-blue-600 p-4 mb-3">
                <h3 className="text-lg font-bold text-blue-900">CLINICAL HISTORY</h3>
              </div>
              <div className="px-4 py-3 border border-gray-200 rounded">
                <p className="text-gray-800 whitespace-pre-wrap">{report.reportText}</p>
              </div>
            </div>
          )}

          {/* Findings */}
          <div className="mb-6">
            <div className="bg-blue-50 border-l-4 border-blue-600 p-4 mb-3">
              <h3 className="text-lg font-bold text-blue-900">FINDINGS</h3>
            </div>
            <div className="px-4 py-3 border border-gray-200 rounded">
              <p className="text-gray-800 whitespace-pre-wrap">
                {report.findings || 'No findings documented.'}
              </p>
            </div>
          </div>

          {/* Impression */}
          <div className="mb-8">
            <div className="bg-blue-50 border-l-4 border-blue-600 p-4 mb-3">
              <h3 className="text-lg font-bold text-blue-900">IMPRESSION</h3>
            </div>
            <div className="px-4 py-3 border border-gray-200 rounded bg-yellow-50">
              <p className="text-gray-900 font-semibold whitespace-pre-wrap">
                {report.impression || 'No impression documented.'}
              </p>
            </div>
          </div>

          {/* Signature */}
          <div className="border-t-2 border-gray-300 pt-6 mt-8">
            <div className="flex justify-between items-start">
              <div>
                <p className="text-sm text-gray-600 mb-2">{settings.digitalSignatureText}:</p>
                <p className="text-lg font-bold text-gray-900">Dr. {report.radiologistName}</p>
                {report.status === 'Final' && report.finalizedAt && (
                  <>
                    <p className="text-sm text-gray-600 mt-2">
                      Finalized: {new Date(report.finalizedAt).toLocaleString()}
                    </p>
                  </>
                )}
                {report.status !== 'Final' && (
                  <p className="text-sm text-red-600 font-bold mt-2">
                    STATUS: DRAFT - NOT FINALIZED
                  </p>
                )}
              </div>
              <div className="text-right text-sm text-gray-600">
                <p>Report ID: {report.reportId}</p>
                <p>Created: {new Date(report.createdAt).toLocaleDateString()}</p>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="mt-8 pt-4 border-t border-gray-200 text-center">
            <p className="text-xs text-gray-500 italic">{settings.footerText}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
