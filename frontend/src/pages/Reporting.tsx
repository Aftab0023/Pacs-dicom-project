import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery, useMutation } from '@tanstack/react-query'
import { worklistApi, reportApi } from '../services/api'
import Layout from '../components/Layout'
import { 
  HiOutlineDocumentText, HiOutlineSave, HiArrowLeft, 
  HiOutlineUserCircle, HiOutlineClock, HiCheckCircle,
  HiOutlineEye
} from 'react-icons/hi'
import { MdOutlineDescription, MdHistoryEdu } from 'react-icons/md'

import { HiOutlinePrinter } from 'react-icons/hi';


export default function Reporting() {
  const { studyId } = useParams<{ studyId: string }>()
  const navigate = useNavigate()
  
  const [reportText, setReportText] = useState('')
  const [findings, setFindings] = useState('')
  const [impression, setImpression] = useState('')

  // 1. Fetch Study Data
  const { data: study, isLoading: studyLoading } = useQuery({
    queryKey: ['study', studyId],
    queryFn: () => worklistApi.getStudyDetail(Number(studyId)),
    enabled: !!studyId
  })

  // 2. Fetch Reports for this Study - Added refetchReports
  const { data: reports, refetch: refetchReports } = useQuery({
    queryKey: ['reports', studyId],
    queryFn: () => reportApi.getStudyReports(Number(studyId)),
    enabled: !!studyId
  })

  // 3. Mutation to Save Draft
  const createMutation = useMutation({
    mutationFn: (data: any) => reportApi.createReport(data),
    onSuccess: () => {
        alert('Draft saved successfully');
        refetchReports(); // CRITICAL: Refresh reports to get the new reportId
    }
  })

  // 4. Mutation to Finalize
  const finalizeMutation = useMutation({
    mutationFn: ({ reportId, digitalSignature }: { reportId: number, digitalSignature: string }) => 
      reportApi.finalizeReport(reportId, digitalSignature),
    onSuccess: () => {
      alert('Report finalized successfully');
      refetchReports();
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
    // Look specifically for the draft we just saved in the reports list
    const currentReport = reports?.find((r: any) => r.status === 'Draft' || r.status === 'InProgress');
    
    if (!currentReport) {
      alert("Please save a draft before finalizing. The system needs to create a record first.");
      return;
    }

    if (!window.confirm('Finalize this report?')) return;

    try {
      await finalizeMutation.mutateAsync({
        reportId: currentReport.reportId,
        digitalSignature: 'Digital Signature'
      });

      // Give the server a moment to update before triggering download
      setTimeout(() => handleDownload(), 1000); 
    } catch (err) {
      console.error("Finalize error:", err);
    }
  };

  const handleDownload = async () => {
    try {
      // Logic for finding the Finalized report
      const finalizedReport = reports?.find((r: any) => r.status === 'Final' || r.status === 'Reported');

      if (!finalizedReport) {
         // If not found, try to refetch once and try again
         const { data: updatedReports } = await refetchReports();
         const retryReport = updatedReports?.find((r: any) => r.status === 'Final' || r.status === 'Reported');
         
         if (!retryReport) {
            alert("Finalized report not found. Try clicking Print PDF again in a moment.");
            return;
         }
         return executeDownload(retryReport.reportId);
      }

      executeDownload(finalizedReport.reportId);
    } catch (err) {
      alert("Could not generate PDF. Ensure the server is running.");
    }
  };

  // Helper to keep the download logic clean
  const executeDownload = async (reportId: number) => {
      const blob = await reportApi.downloadPdf(reportId);
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Report-${reportId}.txt`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
  }

  // ... rest of your JSX

  if (studyLoading) return <Layout><div className="py-20 text-center animate-pulse text-slate-500">Loading Patient Data...</div></Layout>

  return (
    <Layout>
      <div className="max-w-[1400px] mx-auto space-y-6 pb-10">
        
        {/* Top Header Actions */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div className="flex items-center gap-4">
            <button onClick={() => navigate(-1)} className="p-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl transition-all">
              <HiArrowLeft size={20} />
            </button>
            <h1 className="text-2xl font-black text-white tracking-tight flex items-center gap-2">
              <MdHistoryEdu className="text-blue-500" size={28} />
              Reporting Suite
            </h1>
          </div>
          
          <div className="flex gap-2 w-full md:w-auto">
            <button 
              onClick={() => navigate(`/viewer/${studyId}`)}
              className="flex-1 md:flex-none flex items-center justify-center gap-2 px-4 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl font-bold transition-all border border-slate-700"
            >
              <HiOutlineEye size={20} /> View Images
            </button>
            <button 
              onClick={handleFinalize}
              disabled={createMutation.isPending || !findings || !impression}
              className="flex-1 md:flex-none flex items-center justify-center gap-2 px-6 py-2.5 bg-emerald-600 hover:bg-emerald-500 disabled:opacity-30 text-white rounded-xl font-bold shadow-lg shadow-emerald-900/20 transition-all"
            >
              <HiCheckCircle size={20} /> Finalize
            </button>

            <button
              onClick={handleDownload}
              className="flex items-center gap-2 px-6 py-2.5 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-bold border border-slate-700 transition-all"
            >
              <HiOutlinePrinter size={20} />
              Print PDF
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          
          {/* Sidebar: Patient Info & History */}
          <div className="lg:col-span-4 space-y-6">
            <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 shadow-xl">
              <h3 className="text-slate-500 text-[10px] font-black uppercase tracking-widest mb-6">Patient Context</h3>
              <div className="flex items-center gap-4 mb-6">
                <div className="p-3 bg-blue-500/10 rounded-2xl">
                  <HiOutlineUserCircle size={32} className="text-blue-500" />
                </div>
                <div>
                  <p className="text-white text-lg font-bold leading-tight">{study?.patient.firstName} {study?.patient.lastName}</p>
                  <p className="text-xs text-slate-500 font-mono">MRN: {study?.patient.mrn}</p>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800/50">
                  <p className="text-[10px] text-slate-500 font-bold uppercase mb-1">Date</p>
                  <p className="text-slate-200">{new Date(study?.studyDate).toLocaleDateString()}</p>
                </div>
                <div className="bg-slate-950 p-3 rounded-xl border border-slate-800/50">
                  <p className="text-[10px] text-slate-500 font-bold uppercase mb-1">Modality</p>
                  <p className="text-blue-400 font-bold">{study?.modality}</p>
                </div>
              </div>
            </div>

            {/* Previous Reports Section */}
            {reports && reports.length > 0 && (
              <div className="space-y-4">
                <h3 className="text-slate-500 text-[10px] font-black uppercase tracking-widest px-2">Historical Reports</h3>
                <div className="space-y-3 max-h-[400px] overflow-y-auto pr-2 scrollbar-thin">
                  {reports.map((report: any) => (
                    <div key={report.reportId} className="bg-slate-900/50 border border-slate-800 p-4 rounded-2xl hover:border-slate-700 transition-all">
                      <div className="flex justify-between items-center mb-2">
                        <span className="text-xs font-bold text-blue-400">{report.radiologistName}</span>
                        <span className={`text-[10px] px-2 py-0.5 rounded-full font-black uppercase ${
                          report.status === 'Final' ? 'bg-emerald-500/10 text-emerald-500' : 'bg-amber-500/10 text-amber-500'
                        }`}>
                          {report.status}
                        </span>
                      </div>
                      <p className="text-[10px] text-slate-500 mb-2 flex items-center gap-1">
                        <HiOutlineClock /> {new Date(report.createdAt).toLocaleString()}
                      </p>
                      <p className="text-xs text-slate-400 line-clamp-2 italic">"{report.impression}"</p>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Main Editor Area */}
          <div className="lg:col-span-8 space-y-6">
            <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 md:p-8 shadow-2xl space-y-8">
              
              <EditorSection 
                label="Clinical History / Indication" 
                value={reportText} 
                onChange={setReportText} 
                rows={3} 
                placeholder="Patient history and reason for exam..."
              />

              <EditorSection 
                label="Detailed Findings" 
                value={findings} 
                onChange={setFindings} 
                rows={10} 
                placeholder="Describe your observations..."
                icon={<MdOutlineDescription className="text-blue-500" />}
              />

              <EditorSection 
                label="Impression" 
                value={impression} 
                onChange={setImpression} 
                rows={4} 
                placeholder="Your final diagnostic conclusion..."
                icon={<HiOutlineDocumentText className="text-emerald-500" />}
                isBold
              />

              <div className="pt-6 border-t border-slate-800 flex justify-between items-center">
                <p className="text-xs text-slate-500 italic flex items-center gap-2">
                  <HiOutlineSave className="animate-bounce" /> Auto-drafting enabled
                </p>
                <div className="space-x-3">
                  <button onClick={() => navigate('/worklist')} className="px-6 py-2 text-slate-400 hover:text-white transition-colors">Cancel</button>
                  <button 
                    onClick={handleSaveDraft}
                    disabled={createMutation.isPending}
                    className="px-8 py-2.5 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-bold transition-all border border-slate-700"
                  >
                    Save Draft
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  )
}

// Sub-component for Editor fields
function EditorSection({ label, value, onChange, rows, placeholder, icon, isBold }: any) {
  return (
    <div className="space-y-3">
      <label className="flex items-center gap-2 text-xs font-black uppercase tracking-[0.15em] text-slate-500 ml-1">
        {icon} {label}
      </label>
      <textarea
        value={value}
        onChange={(e) => onChange(e.target.value)}
        rows={rows}
        placeholder={placeholder}
        className={`w-full bg-slate-950 border border-slate-800 rounded-2xl p-5 text-slate-200 focus:ring-2 focus:ring-blue-500/50 outline-none transition-all resize-none shadow-inner leading-relaxed ${isBold ? 'font-bold' : 'font-normal'}`}
      />
    </div>
  )
}