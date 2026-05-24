import React, { useState, useEffect } from 'react';
import { CreditCard, History, Loader2, CheckCircle, XCircle } from 'lucide-react';
import { walletApi } from '../services/api';

const fmt = (n: number | string) =>
  'DZD ' + new Intl.NumberFormat('fr-DZ').format(Math.round(Number(n)));

const statusStyle: Record<string, string> = {
  pending: 'bg-yellow-500/10 text-yellow-600 border-yellow-500/20',
  approved: 'bg-success/10 text-success border-success/20',
  rejected: 'bg-danger/10 text-danger border-danger/20',
};

export const WalletManagement: React.FC = () => {
  const [withdrawals, setWithdrawals] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [actionLoading, setActionLoading] = useState<number | null>(null);
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState<any>(null);

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
                      {w.status === 'pending' && (
                        <div className="flex items-center justify-end gap-2">
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
                        </div>
                      )}
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
    </div>
  );
};
