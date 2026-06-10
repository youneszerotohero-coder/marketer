import React, { useState, useEffect, useRef } from 'react';
import { CreditCard, History, Loader2, CheckCircle, XCircle, Receipt, Printer } from 'lucide-react';
import { Modal } from '../components/ui/Modal';
import { walletApi } from '../services/api';

const fmt = (n: number | string) =>
  'DZD ' + new Intl.NumberFormat('fr-DZ').format(Math.round(Number(n)));

const statusStyle: Record<string, string> = {
  pending: 'bg-yellow-500/10 text-yellow-600 border-yellow-500/20',
  approved: 'bg-success/10 text-success border-success/20',
  rejected: 'bg-danger/10 text-danger border-danger/20',
};

const PaymentReceipt: React.FC<{ withdrawal: any }> = ({ withdrawal }) => {
  const receiptRef = useRef<HTMLDivElement>(null);

  const handlePrint = () => {
    const content = receiptRef.current?.innerHTML;
    if (!content) return;
    const printWindow = window.open('', '_blank', 'width=600,height=800');
    if (!printWindow) return;
    printWindow.document.write(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Reçu de paiement #${withdrawal.id}</title>
          <meta charset="utf-8" />
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: 'Courier New', monospace; background: #fff; color: #111; padding: 32px; }
            .receipt { max-width: 420px; margin: 0 auto; }
            .header { text-align: center; border-bottom: 2px dashed #ccc; padding-bottom: 16px; margin-bottom: 16px; }
            .logo { font-size: 22px; font-weight: bold; letter-spacing: 2px; }
            .sub { font-size: 11px; color: #666; margin-top: 4px; }
            .title { font-size: 14px; font-weight: bold; margin-top: 8px; text-transform: uppercase; letter-spacing: 1px; }
            .row { display: flex; justify-content: space-between; padding: 5px 0; font-size: 12px; border-bottom: 1px solid #f0f0f0; }
            .row .label { color: #555; }
            .row .value { font-weight: 600; }
            .amount-row { margin-top: 12px; padding: 10px 0; border-top: 2px dashed #ccc; border-bottom: 2px dashed #ccc; }
            .amount-row .label { font-size: 14px; font-weight: bold; }
            .amount-row .value { font-size: 18px; font-weight: bold; }
            .status-badge { display: inline-block; padding: 2px 10px; border-radius: 20px; font-size: 11px; font-weight: bold; border: 1px solid currentColor; }
            .status-approved { color: #16a34a; }
            .status-pending { color: #ca8a04; }
            .status-rejected { color: #dc2626; }
            .footer { text-align: center; margin-top: 20px; font-size: 10px; color: #999; }
            .qr-placeholder { text-align: center; margin: 16px 0; font-size: 10px; color: #bbb; }
          </style>
        </head>
        <body>${content}</body>
      </html>
    `);
    printWindow.document.close();
    printWindow.focus();
    setTimeout(() => { printWindow.print(); printWindow.close(); }, 400);
  };

  const payoutDetails = withdrawal.payout_details || {};

  return (
    <div>
      {/* Printable content */}
      <div ref={receiptRef} className="receipt">
        <div className="header" style={{ textAlign: 'center', borderBottom: '2px dashed #ccc', paddingBottom: '16px', marginBottom: '16px' }}>
          <div className="logo" style={{ fontSize: '22px', fontWeight: 'bold', letterSpacing: '2px' }}>AFILIAT</div>
          <div className="sub" style={{ fontSize: '11px', color: '#666', marginTop: '4px' }}>Plateforme d'affiliation</div>
          <div className="title" style={{ fontSize: '14px', fontWeight: 'bold', marginTop: '8px', textTransform: 'uppercase', letterSpacing: '1px' }}>
            Reçu de paiement
          </div>
        </div>

        {[
          ['N° Transaction', `#${withdrawal.id}`],
          ['Date', new Date(withdrawal.created_at).toLocaleString('fr-DZ')],
          ['Marketeur', withdrawal.marketer?.name ?? '—'],
          ['Email', withdrawal.marketer?.email ?? '—'],
          ['Méthode de paiement', withdrawal.payment_method ?? '—'],
          ...(payoutDetails.operator ? [['Opérateur', payoutDetails.operator]] : []),
          ...(payoutDetails.phone ? [['N° Téléphone (Flexy)', payoutDetails.phone]] : []),
          ...(payoutDetails.bank_number ? [['N° Compte / CCP / RIP', payoutDetails.bank_number]] : []),
          ...(payoutDetails.account ? [['Compte / IBAN', payoutDetails.account]] : []),
          ...(payoutDetails.bank ? [['Banque', payoutDetails.bank]] : []),
          ['Notes', withdrawal.notes || '—'],
        ].map(([label, value]) => (
          <div key={label} className="row" style={{ display: 'flex', justifyContent: 'space-between', padding: '5px 0', fontSize: '12px', borderBottom: '1px solid #f0f0f0' }}>
            <span className="label" style={{ color: '#555' }}>{label}</span>
            <span className="value" style={{ fontWeight: 600, maxWidth: '55%', textAlign: 'right', wordBreak: 'break-all' }}>{value}</span>
          </div>
        ))}

        <div className="amount-row" style={{ marginTop: '12px', padding: '10px 0', borderTop: '2px dashed #ccc', borderBottom: '2px dashed #ccc', display: 'flex', justifyContent: 'space-between' }}>
          <span className="label" style={{ fontSize: '14px', fontWeight: 'bold' }}>MONTANT</span>
          <span className="value" style={{ fontSize: '18px', fontWeight: 'bold' }}>{fmt(withdrawal.amount)}</span>
        </div>

        <div style={{ marginTop: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ fontSize: '12px', color: '#555' }}>Statut :</span>
          <span className={`status-badge status-${withdrawal.status}`} style={{
            display: 'inline-block', padding: '2px 10px', borderRadius: '20px', fontSize: '11px', fontWeight: 'bold',
            color: withdrawal.status === 'approved' ? '#16a34a' : withdrawal.status === 'rejected' ? '#dc2626' : '#ca8a04'
          }}>
            {withdrawal.status.toUpperCase()}
          </span>
        </div>

        <div className="footer" style={{ textAlign: 'center', marginTop: '20px', fontSize: '10px', color: '#999' }}>
          <p>Ce reçu est généré automatiquement par le système Afiliat.</p>
          <p>Conservez ce document pour vos archives.</p>
        </div>
      </div>

      {/* Action buttons — hidden during print */}
      <div className="flex gap-3 mt-6 pt-4 border-t border-border print:hidden">
        <button
          onClick={handlePrint}
          className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-primary text-white rounded-xl text-sm font-semibold hover:bg-primary-hover transition-colors"
        >
          <Printer className="w-4 h-4" />
          Imprimer / Télécharger PDF
        </button>
      </div>
    </div>
  );
};

export const WalletManagement: React.FC = () => {
  const [withdrawals, setWithdrawals] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [actionLoading, setActionLoading] = useState<number | null>(null);
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState<any>(null);
  const [receiptModal, setReceiptModal] = useState<any>(null);

  const loadData = (p = 1, status = statusFilter) => {
    setLoading(true);
    const params: any = { page: p, per_page: 20 };
    if (status) params.status = status;
    walletApi
      .listWithdrawals(params)
      .then(({ data }) => {
        setWithdrawals(data.data ?? data);
        setMeta(data.meta ?? null);
        setPage(p);
      })
      .catch(() => setError('Failed to load withdrawal requests.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => { loadData(); }, []);

  const handleApprove = async (id: number) => {
    setActionLoading(id);
    try {
      await walletApi.approve(id);
      loadData(page);
    } catch (e: any) {
      alert(e.response?.data?.message || 'Failed to approve.');
    } finally {
      setActionLoading(null);
    }
  };

  const handleReject = async (id: number) => {
    const reason = prompt('Reason for rejection (optional):');
    if (reason === null) return;
    setActionLoading(id);
    try {
      await walletApi.reject(id, reason || undefined);
      loadData(page);
    } catch (e: any) {
      alert(e.response?.data?.message || 'Failed to reject.');
    } finally {
      setActionLoading(null);
    }
  };

  const pendingCount = withdrawals.filter((w) => w.status === 'pending').length;

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Wallet Management</h1>
          <p className="text-sm text-text-muted mt-1">Review and process marketer withdrawal requests.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-surface rounded-2xl p-6 border border-border shadow-sm flex flex-col gap-2">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-yellow-500/10 text-yellow-600 rounded-xl">
              <History className="w-6 h-6" />
            </div>
            <div>
              <p className="text-sm font-medium text-text-muted">Pending Requests</p>
              <h3 className="text-2xl font-bold text-text">
                {loading ? '...' : `${pendingCount} request${pendingCount !== 1 ? 's' : ''}`}
              </h3>
            </div>
          </div>
        </div>
        <div className="bg-surface rounded-2xl p-6 border border-border shadow-sm flex flex-col gap-2">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-primary/10 text-primary rounded-xl">
              <CreditCard className="w-6 h-6" />
            </div>
            <div>
              <p className="text-sm font-medium text-text-muted">Total Approved Amount</p>
              <h3 className="text-2xl font-bold text-text">
                {loading ? '...' : fmt(withdrawals.filter((w) => w.status === 'approved').reduce((s, w) => s + Number(w.amount), 0))}
              </h3>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
        <div className="p-4 border-b border-border bg-background/50 flex items-center justify-between">
          <h2 className="text-lg font-bold text-text">Withdrawal Requests</h2>
          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); loadData(1, e.target.value); }}
            className="bg-surface border border-border rounded-lg px-3 py-2 text-sm outline-none focus:border-primary"
          >
            <option value="">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
          </select>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-16">
            <Loader2 className="w-8 h-8 text-primary animate-spin" />
          </div>
        ) : error ? (
          <div className="p-6 text-sm text-danger">{error}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="text-text-muted text-xs uppercase tracking-wider bg-background/50">
                  <th className="p-4 font-medium">ID</th>
                  <th className="p-4 font-medium">Marketer</th>
                  <th className="p-4 font-medium">Amount</th>
                  <th className="p-4 font-medium">Method</th>
                  <th className="p-4 font-medium">Date</th>
                  <th className="p-4 font-medium">Status</th>
                  <th className="p-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {withdrawals.length === 0 ? (
                  <tr><td colSpan={7} className="p-8 text-center text-sm text-text-muted">No withdrawal requests found.</td></tr>
                ) : withdrawals.map((w) => (
                  <tr key={w.id} className="hover:bg-background/50 transition-colors">
                    <td className="p-4 text-sm font-mono text-text-muted">#{w.id}</td>
                    <td className="p-4 text-sm font-semibold text-text">{w.marketer?.name ?? '—'}</td>
                    <td className="p-4 text-sm font-bold text-primary">{fmt(w.amount)}</td>
                    <td className="p-4 text-sm text-text-muted">{w.payment_method ?? '—'}</td>
                    <td className="p-4 text-sm text-text-muted">{new Date(w.created_at).toLocaleDateString()}</td>
                    <td className="p-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold border ${statusStyle[w.status] ?? ''}`}>
                        {w.status}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        {/* Receipt button — always visible */}
                        <button
                          onClick={() => setReceiptModal(w)}
                          className="p-1.5 text-text-muted hover:text-primary hover:bg-primary/10 rounded-md transition-colors"
                          title="Voir le reçu"
                        >
                          <Receipt className="w-4 h-4" />
                        </button>

                        {w.status === 'pending' && (
                          <>
                            <button
                              onClick={() => handleApprove(w.id)}
                              disabled={actionLoading === w.id}
                              className="p-1.5 text-success hover:bg-success/10 rounded-md transition-colors"
                              title="Approve"
                            >
                              {actionLoading === w.id ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle className="w-4 h-4" />}
                            </button>
                            <button
                              onClick={() => handleReject(w.id)}
                              disabled={actionLoading === w.id}
                              className="p-1.5 text-danger hover:bg-danger/10 rounded-md transition-colors"
                              title="Reject"
                            >
                              <XCircle className="w-4 h-4" />
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {meta && meta.last_page > 1 && (
          <div className="p-4 border-t border-border flex items-center justify-between bg-background/20">
            <p className="text-xs text-text-muted">Page {meta.current_page} of {meta.last_page}</p>
            <div className="flex gap-2">
              <button disabled={meta.current_page <= 1} onClick={() => loadData(page - 1)} className="px-3 py-1.5 border border-border text-sm rounded-lg disabled:opacity-40">Prev</button>
              <button disabled={meta.current_page >= meta.last_page} onClick={() => loadData(page + 1)} className="px-3 py-1.5 border border-border text-sm rounded-lg disabled:opacity-40">Next</button>
            </div>
          </div>
        )}
      </div>

      {/* Receipt Modal */}
      <Modal isOpen={!!receiptModal} onClose={() => setReceiptModal(null)} title={`Reçu de transaction #${receiptModal?.id}`}>
        {receiptModal && <PaymentReceipt withdrawal={receiptModal} />}
      </Modal>
    </div>
  );
};
