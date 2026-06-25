import React, { useState, useEffect, useCallback } from 'react';
import { Search, Plus, Edit, Ban, Loader2, CheckCircle, Activity, DollarSign } from 'lucide-react';
import { Modal } from '../components/ui/Modal';
import { usersApi } from '../services/api';
import { useLanguage } from '../context/LanguageContext';

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
  const { t } = useLanguage();

  // Form state
  const [form, setForm] = useState({ name: '', email: '', password: '', phone: '', status: 'active' });

  const loadMarketers = useCallback((p = 1, append = false) => {
    setLoading(true);
    const params: any = { role: 'marketer', page: p, per_page: 20 };
    if (statusFilter) params.status = statusFilter;
    usersApi.list(params)
      .then(({ data }) => {
        setMarketers(prev => append ? [...prev, ...(data.data ?? data)] : (data.data ?? data));
        const metaObj = data.meta ?? {
          current_page: data.current_page ?? 1,
          last_page: data.last_page ?? 1,
          total: data.total ?? 0
        };
        setMeta(metaObj);
        setPage(p);
      })
      .catch(() => setError(t('marketers.failedToLoad')))
      .finally(() => setLoading(false));
  }, [statusFilter, t]);

  useEffect(() => { loadMarketers(1, false); }, [loadMarketers]);

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
      loadMarketers(1, false);
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
      loadMarketers(1, false);
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
          <h1 className="text-2xl font-bold text-text">{t('marketers.title')}</h1>
          <p className="text-sm text-text-muted mt-1">{t('marketers.subtitle')}</p>
        </div>
        <button onClick={() => openModal('add')} className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors shadow-md shadow-primary/20 cursor-pointer">
          <Plus className="w-4 h-4" /> {t('marketers.addMarketer')}
        </button>
      </div>

      <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
        <div className="p-4 border-b border-border flex flex-wrap items-center gap-4 bg-background/50">
          <div className="relative flex-1 min-w-[250px]">
            <Search className="w-4 h-4 absolute start-3 top-1/2 -translate-y-1/2 text-text-muted" />
            <input type="text" placeholder={t('marketers.searchPlaceholder')} value={search} onChange={(e) => setSearch(e.target.value)} className="w-full ps-10 pe-4 py-2 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary" />
          </div>
          <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); }} className="bg-surface border border-border rounded-lg px-3 py-2 text-sm outline-none focus:border-primary">
            <option value="">{t('marketers.allStatus')}</option>
            <option value="active">{t('common.active')}</option>
            <option value="suspended">{t('common.suspended')}</option>
          </select>
        </div>

        {loading && marketers.length === 0 ? (
          <div className="flex items-center justify-center py-16"><Loader2 className="w-8 h-8 text-primary animate-spin" /></div>
        ) : error ? (
          <div className="p-6 text-sm text-danger">{error}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-start border-collapse">
              <thead>
                <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider">
                  <th className="p-4 font-medium text-start">{t('marketers.tableMarketer')}</th>
                  <th className="p-4 font-medium text-start">{t('marketers.tablePhone')}</th>
                  <th className="p-4 font-medium text-start">{t('marketers.tableStatus')}</th>
                  <th className="p-4 font-medium text-start">{t('marketers.tableTier')}</th>
                  <th className="p-4 font-medium text-end">{t('marketers.tableActions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filtered.length === 0 ? (
                  <tr><td colSpan={5} className="p-8 text-center text-sm text-text-muted">{t('marketers.noMarketers')}</td></tr>
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
                        {m.status === 'active' ? t('common.active') : t('common.suspended')}
                      </span>
                    </td>
                    <td className="p-4 text-sm text-text-muted">{m.tier ?? '—'}</td>
                    <td className="p-4 text-end">
                      <div className="flex items-center justify-end gap-2">
                        <button onClick={() => openModal('performance', m)} className="p-1.5 text-text-muted hover:text-primary hover:bg-primary/10 rounded-md transition-colors cursor-pointer" title="Performance">
                          <Activity className="w-4 h-4" />
                        </button>
                        <button onClick={() => openModal('commissions', m)} className="p-1.5 text-text-muted hover:text-primary hover:bg-primary/10 rounded-md transition-colors cursor-pointer" title="Commissions">
                          <DollarSign className="w-4 h-4" />
                        </button>
                        <button onClick={() => openModal('edit', m)} className="p-1.5 text-text-muted hover:text-blue-500 hover:bg-blue-500/10 rounded-md transition-colors cursor-pointer" title="Edit"><Edit className="w-4 h-4" /></button>
                        <button onClick={() => openModal('suspend', m)} className="p-1.5 text-text-muted hover:text-danger hover:bg-danger/10 rounded-md transition-colors cursor-pointer" title={m.status === 'active' ? 'Suspend' : 'Activate'}>
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

        {meta && meta.last_page > page && (
          <div className="p-4 border-t border-border flex justify-center bg-background/20">
            <button
              onClick={() => loadMarketers(page + 1, true)}
              disabled={loading}
              className="flex items-center gap-2 px-5 py-2 border border-border bg-surface text-text hover:bg-background text-sm font-semibold rounded-xl transition-all duration-200 cursor-pointer shadow-sm disabled:opacity-40"
            >
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              {t('common.loadMore')}
            </button>
          </div>
        )}
      </div>

      {/* Add / Edit Modal */}
      <Modal isOpen={actionModal === 'add' || actionModal === 'edit'} onClose={() => setActionModal(null)} title={actionModal === 'edit' ? t('marketers.editTitle') : t('marketers.addTitle')}>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-text mb-1">{t('marketers.fullName')}</label>
            <input type="text" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="Ahmed Benali" />
          </div>
          <div>
            <label className="block text-sm font-medium text-text mb-1">{t('marketers.email')}</label>
            <input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="ahmed@example.com" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-text mb-1">{actionModal === 'edit' ? t('marketers.newPasswordOptional') : t('marketers.password')}</label>
              <input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="••••••••" />
            </div>
            <div>
              <label className="block text-sm font-medium text-text mb-1">{t('marketers.phone')}</label>
              <input type="text" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="+213..." />
            </div>
          </div>
          <div className="flex justify-end gap-3 pt-4 mt-2 border-t border-border">
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm cursor-pointer">{t('common.cancel')}</button>
            <button type="button" onClick={handleSave} disabled={saving} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors flex items-center gap-2 cursor-pointer">
              {saving && <Loader2 className="w-4 h-4 animate-spin" />}
              {actionModal === 'edit' ? t('common.saveChanges') : t('marketers.createBtn')}
            </button>
          </div>
        </div>
      </Modal>

      {/* Suspend / Activate Modal */}
      <Modal isOpen={actionModal === 'suspend'} onClose={() => setActionModal(null)} title={selectedMarketer?.status === 'active' ? t('marketers.suspendTitle') : t('marketers.activateTitle')}>
        <div className="space-y-4">
          <p className="text-sm text-text">
            {t(selectedMarketer?.status === 'active' ? 'marketers.suspendConfirm' : 'marketers.activateConfirm', { name: selectedMarketer?.name })}
          </p>
          <div className="flex justify-end gap-3 pt-4 border-t border-border">
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm cursor-pointer">{t('common.cancel')}</button>
            <button type="button" onClick={handleSuspend} disabled={saving} className={`px-4 py-2 text-white rounded-lg text-sm font-medium flex items-center gap-2 cursor-pointer ${selectedMarketer?.status === 'active' ? 'bg-danger hover:bg-danger/90' : 'bg-success hover:bg-success/90'}`}>
              {saving && <Loader2 className="w-4 h-4 animate-spin" />}
              {selectedMarketer?.status === 'active' ? t('marketers.suspendAccountBtn') : t('marketers.activateAccountBtn')}
            </button>
          </div>
        </div>
      </Modal>

      {/* Performance Modal */}
      <Modal isOpen={actionModal === 'performance'} onClose={() => setActionModal(null)} title={t('marketers.performanceTitle', { name: selectedMarketer?.name })}>
        {statsLoading ? (
          <div className="flex justify-center p-8"><Loader2 className="w-8 h-8 text-primary animate-spin" /></div>
        ) : stats ? (
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
               <div className="p-4 bg-background border border-border rounded-xl">
                 <p className="text-xs text-text-muted mb-1">{t('marketers.totalOrders')}</p>
                 <p className="text-xl font-bold text-text">{stats.performance.total_orders}</p>
               </div>
               <div className="p-4 bg-background border border-border rounded-xl">
                 <p className="text-xs text-text-muted mb-1">{t('marketers.conversionRate')}</p>
                 <p className="text-xl font-bold text-success">{stats.performance.conversion_rate}%</p>
               </div>
            </div>
            <div>
              <h3 className="text-sm font-bold text-text mb-3">{t('marketers.topProducts')}</h3>
              <div className="space-y-2">
                 {stats.performance.top_products.length === 0 ? (
                   <p className="text-sm text-text-muted">{t('marketers.noSales')}</p>
                 ) : stats.performance.top_products.map((p: any, i: number) => (
                   <div key={i} className="flex justify-between text-sm p-2 bg-background rounded-lg">
                     <span>{p.product_name}</span>
                     <span className="font-medium text-text">{t('marketers.salesCount', { count: p.sales })}</span>
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
      <Modal isOpen={actionModal === 'commissions'} onClose={() => setActionModal(null)} title={t('marketers.commissionsTitle', { name: selectedMarketer?.name })}>
        {statsLoading ? (
           <div className="flex justify-center p-8"><Loader2 className="w-8 h-8 text-primary animate-spin" /></div>
        ) : stats ? (
          <div className="space-y-4">
            <div className="p-4 bg-primary/10 border border-primary/20 rounded-xl flex justify-between items-center">
              <div>
                <p className="text-xs text-primary font-medium mb-1">{t('marketers.unpaidBalance')}</p>
                <p className="text-2xl font-bold text-primary">DZD {stats.commissions.unpaid_balance}</p>
              </div>
              <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors shadow-sm cursor-pointer">
                {t('marketers.payNow')}
              </button>
            </div>
            <div>
              <h3 className="text-sm font-bold text-text mb-3">{t('marketers.recentEarnings')}</h3>
              <div className="space-y-2">
                 {stats.commissions.recent_earnings.length === 0 ? (
                   <p className="text-sm text-text-muted">{t('marketers.noRecentEarnings')}</p>
                 ) : stats.commissions.recent_earnings.map((e: any) => (
                   <div key={e.id} className="flex justify-between text-sm p-3 border border-border rounded-lg">
                     <div>
                       <p className="font-medium text-text">
                         {e.type === 'return_fee' ? t('marketers.returnFeeEarning') : t('marketers.orderEarning')} #{e.order_reference}
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
