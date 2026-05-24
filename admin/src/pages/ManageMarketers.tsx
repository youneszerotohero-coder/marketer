import React, { useState, useEffect, useCallback } from 'react';
import { Search, Plus, Edit, Ban, Loader2, CheckCircle, Activity, DollarSign } from 'lucide-react';
import { Modal } from '../components/ui/Modal';
import { usersApi } from '../services/api';

export const ManageMarketers: React.FC = () => {
  const [marketers, setMarketers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [actionModal, setActionModal] = useState<'add' | 'edit' | 'suspend' | 'performance' | 'commissions' | null>(null);
  const [selectedMarketer, setSelectedMarketer] = useState<any>(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState<any>(null);
  const [saving, setSaving] = useState(false);
  const [stats, setStats] = useState<any>(null);
  const [statsLoading, setStatsLoading] = useState(false);

  // Form state
  const [form, setForm] = useState({ name: '', email: '', password: '', phone: '', status: 'active' });

  const loadMarketers = useCallback((p = 1) => {
    setLoading(true);
    const params: any = { role: 'marketer', page: p, per_page: 20 };
    if (statusFilter) params.status = statusFilter;
    usersApi.list(params)
      .then(({ data }) => { setMarketers(data.data ?? data); setMeta(data.meta ?? null); setPage(p); })
      .catch(() => setError('Failed to load marketers.'))
      .finally(() => setLoading(false));
  }, [statusFilter]);

  useEffect(() => { loadMarketers(); }, [loadMarketers]);

  const openModal = (type: any, marketer?: any) => {
    setSelectedMarketer(marketer || null);
    if (marketer) setForm({ name: marketer.name, email: marketer.email, password: '', phone: marketer.phone ?? '', status: marketer.status });
    else setForm({ name: '', email: '', password: '', phone: '', status: 'active' });
    setActionModal(type);

    if ((type === 'performance' || type === 'commissions') && marketer) {
      setStatsLoading(true);
      usersApi.getStats(marketer.id)
        .then(({ data }) => setStats(data))
        .catch(() => alert('Failed to load stats'))
        .finally(() => setStatsLoading(false));
    } else {
      setStats(null);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const payload: any = { ...form, role: 'marketer' };
      if (!payload.password) delete payload.password;
      if (selectedMarketer) {
        await usersApi.update(selectedMarketer.id, payload);
      } else {
        await usersApi.create(payload);
      }
      setActionModal(null);
      loadMarketers(page);
    } catch (e: any) {
      alert(e.response?.data?.message || Object.values(e.response?.data?.errors ?? {}).flat().join('\n') || 'Save failed.');
    } finally {
      setSaving(false);
    }
  };

  const handleSuspend = async () => {
    setSaving(true);
    try {
      const newStatus = selectedMarketer.status === 'active' ? 'suspended' : 'active';
      await usersApi.update(selectedMarketer.id, { status: newStatus });
      setActionModal(null);
      loadMarketers(page);
    } catch {
      alert('Action failed.');
    } finally {
      setSaving(false);
    }
  };

  const filtered = marketers.filter(
    (m) => !search || m.name.toLowerCase().includes(search.toLowerCase()) || m.email.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Manage Marketers</h1>
          <p className="text-sm text-text-muted mt-1">View, edit, and manage marketer accounts.</p>
        </div>
        <button onClick={() => openModal('add')} className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors shadow-md shadow-primary/20">
          <Plus className="w-4 h-4" /> Add Marketer
        </button>
      </div>

      <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
        <div className="p-4 border-b border-border flex flex-wrap items-center gap-4 bg-background/50">
          <div className="relative flex-1 min-w-[250px]">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
            <input type="text" placeholder="Search by name or email..." value={search} onChange={(e) => setSearch(e.target.value)} className="w-full pl-10 pr-4 py-2 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary" />
          </div>
          <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); loadMarketers(1); }} className="bg-surface border border-border rounded-lg px-3 py-2 text-sm outline-none focus:border-primary">
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
          </select>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-16"><Loader2 className="w-8 h-8 text-primary animate-spin" /></div>
        ) : error ? (
          <div className="p-6 text-sm text-danger">{error}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider">
                  <th className="p-4 font-medium">Marketer</th>
                  <th className="p-4 font-medium">Phone</th>
                  <th className="p-4 font-medium">Status</th>
                  <th className="p-4 font-medium">Tier</th>
                  <th className="p-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filtered.length === 0 ? (
                  <tr><td colSpan={5} className="p-8 text-center text-sm text-text-muted">No marketers found.</td></tr>
                ) : filtered.map((m) => (
                  <tr key={m.id} className="hover:bg-background/50 transition-colors group">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold">{m.name.charAt(0)}</div>
                        <div>
                          <p className="text-sm font-semibold text-text">{m.name}</p>
                          <p className="text-xs text-text-muted">{m.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="p-4 text-sm text-text-muted">{m.phone ?? '—'}</td>
                    <td className="p-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${m.status === 'active' ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'}`}>
                        {m.status}
                      </span>
                    </td>
                    <td className="p-4 text-sm text-text-muted">{m.tier ?? '—'}</td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button onClick={() => openModal('performance', m)} className="p-1.5 text-text-muted hover:text-primary hover:bg-primary/10 rounded-md transition-colors" title="Performance">
                          <Activity className="w-4 h-4" />
                        </button>
                        <button onClick={() => openModal('commissions', m)} className="p-1.5 text-text-muted hover:text-primary hover:bg-primary/10 rounded-md transition-colors" title="Commissions">
                          <DollarSign className="w-4 h-4" />
                        </button>
                        <button onClick={() => openModal('edit', m)} className="p-1.5 text-text-muted hover:text-blue-500 hover:bg-blue-500/10 rounded-md transition-colors" title="Edit"><Edit className="w-4 h-4" /></button>
                        <button onClick={() => openModal('suspend', m)} className="p-1.5 text-text-muted hover:text-danger hover:bg-danger/10 rounded-md transition-colors" title={m.status === 'active' ? 'Suspend' : 'Activate'}>
                          {m.status === 'active' ? <Ban className="w-4 h-4" /> : <CheckCircle className="w-4 h-4" />}
                        </button>
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
            <p className="text-xs text-text-muted">Page {meta.current_page} of {meta.last_page} — {meta.total} total</p>
            <div className="flex gap-2">
              <button disabled={meta.current_page <= 1} onClick={() => loadMarketers(page - 1)} className="px-3 py-1.5 border border-border text-sm rounded-lg disabled:opacity-40">Prev</button>
              <button disabled={meta.current_page >= meta.last_page} onClick={() => loadMarketers(page + 1)} className="px-3 py-1.5 border border-border text-sm rounded-lg disabled:opacity-40">Next</button>
            </div>
          </div>
        )}
      </div>

      {/* Add / Edit Modal */}
      <Modal isOpen={actionModal === 'add' || actionModal === 'edit'} onClose={() => setActionModal(null)} title={actionModal === 'edit' ? 'Edit Marketer' : 'Add New Marketer'}>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-text mb-1">Full Name</label>
            <input type="text" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="Ahmed Benali" />
          </div>
          <div>
            <label className="block text-sm font-medium text-text mb-1">Email</label>
            <input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="ahmed@example.com" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-text mb-1">{actionModal === 'edit' ? 'New Password (optional)' : 'Password'}</label>
              <input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="••••••••" />
            </div>
            <div>
              <label className="block text-sm font-medium text-text mb-1">Phone</label>
              <input type="text" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="+213..." />
            </div>
          </div>
          <div className="flex justify-end gap-3 pt-4 mt-2 border-t border-border">
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm">Cancel</button>
            <button type="button" onClick={handleSave} disabled={saving} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors flex items-center gap-2">
              {saving && <Loader2 className="w-4 h-4 animate-spin" />}
              {actionModal === 'edit' ? 'Save Changes' : 'Create Marketer'}
            </button>
          </div>
        </div>
      </Modal>

      {/* Suspend / Activate Modal */}
      <Modal isOpen={actionModal === 'suspend'} onClose={() => setActionModal(null)} title={selectedMarketer?.status === 'active' ? 'Suspend Marketer' : 'Activate Marketer'}>
        <div className="space-y-4">
          <p className="text-sm text-text">
            Are you sure you want to <strong>{selectedMarketer?.status === 'active' ? 'suspend' : 'activate'}</strong> <strong>{selectedMarketer?.name}</strong>?
            {selectedMarketer?.status === 'active' && ' They will lose access to their dashboard.'}
          </p>
          <div className="flex justify-end gap-3 pt-4 border-t border-border">
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm">Cancel</button>
            <button type="button" onClick={handleSuspend} disabled={saving} className={`px-4 py-2 text-white rounded-lg text-sm font-medium flex items-center gap-2 ${selectedMarketer?.status === 'active' ? 'bg-danger hover:bg-danger/90' : 'bg-success hover:bg-success/90'}`}>
              {saving && <Loader2 className="w-4 h-4 animate-spin" />}
              {selectedMarketer?.status === 'active' ? 'Suspend Account' : 'Activate Account'}
            </button>
          </div>
        </div>
      </Modal>

      {/* Performance Modal */}
      <Modal isOpen={actionModal === 'performance'} onClose={() => setActionModal(null)} title={`${selectedMarketer?.name} - Performance`}>
        {statsLoading ? (
          <div className="flex justify-center p-8"><Loader2 className="w-8 h-8 text-primary animate-spin" /></div>
        ) : stats ? (
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
               <div className="p-4 bg-background border border-border rounded-xl">
                 <p className="text-xs text-text-muted mb-1">Total Orders</p>
                 <p className="text-xl font-bold text-text">{stats.performance.total_orders}</p>
               </div>
               <div className="p-4 bg-background border border-border rounded-xl">
                 <p className="text-xs text-text-muted mb-1">Conversion Rate</p>
                 <p className="text-xl font-bold text-success">{stats.performance.conversion_rate}%</p>
               </div>
            </div>
            <div>
              <h3 className="text-sm font-bold text-text mb-3">Top Products</h3>
              <div className="space-y-2">
                 {stats.performance.top_products.length === 0 ? (
                   <p className="text-sm text-text-muted">No sales yet.</p>
                 ) : stats.performance.top_products.map((p: any, i: number) => (
                   <div key={i} className="flex justify-between text-sm p-2 bg-background rounded-lg">
                     <span>{p.product_name}</span>
                     <span className="font-medium text-text">{p.sales} Sales</span>
                   </div>
                 ))}
              </div>
            </div>
          </div>
        ) : (
          <p className="text-center text-sm text-text-muted p-4">No data available.</p>
        )}
      </Modal>

      {/* Commissions Modal */}
      <Modal isOpen={actionModal === 'commissions'} onClose={() => setActionModal(null)} title={`${selectedMarketer?.name} - Commissions`}>
        {statsLoading ? (
           <div className="flex justify-center p-8"><Loader2 className="w-8 h-8 text-primary animate-spin" /></div>
        ) : stats ? (
          <div className="space-y-4">
            <div className="p-4 bg-primary/10 border border-primary/20 rounded-xl flex justify-between items-center">
              <div>
                <p className="text-xs text-primary font-medium mb-1">Unpaid Balance</p>
                <p className="text-2xl font-bold text-primary">DZD {stats.commissions.unpaid_balance}</p>
              </div>
              <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors shadow-sm">
                Pay Now
              </button>
            </div>
            <div>
              <h3 className="text-sm font-bold text-text mb-3">Recent Earnings</h3>
              <div className="space-y-2">
                 {stats.commissions.recent_earnings.length === 0 ? (
                   <p className="text-sm text-text-muted">No recent earnings.</p>
                 ) : stats.commissions.recent_earnings.map((e: any) => (
                   <div key={e.id} className="flex justify-between text-sm p-3 border border-border rounded-lg">
                     <div>
                       <p className="font-medium text-text">
                         {e.type === 'return_fee' ? 'Return Fee' : 'Order'} #{e.order_reference}
                       </p>
                       <p className="text-xs text-text-muted">{new Date(e.date).toLocaleString()}</p>
                     </div>
                     <span className={`font-bold ${e.amount >= 0 ? 'text-success' : 'text-danger'}`}>
                       {e.amount >= 0 ? '+' : '-'}DZD {Math.abs(e.amount)}
                     </span>
                   </div>
                 ))}
              </div>
            </div>
          </div>
        ) : (
          <p className="text-center text-sm text-text-muted p-4">No data available.</p>
        )}
      </Modal>
    </div>
  );
};
