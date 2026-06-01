import React, { useState, useEffect, useCallback } from 'react';
import { Search, Download, Loader2, RefreshCw } from 'lucide-react';
import { Modal } from '../components/ui/Modal';
import { ordersApi, usersApi } from '../services/api';

const STATUS_STYLES: Record<string, string> = {
  pending: 'bg-yellow-500/10 text-yellow-600 border-yellow-500/20',
  confirmed: 'bg-blue-500/10 text-blue-500 border-blue-500/20',
  shipped: 'bg-purple-500/10 text-purple-500 border-purple-500/20',
  delivered: 'bg-success/10 text-success border-success/20',
  failed: 'bg-danger/10 text-danger border-danger/20',
  cancelled: 'bg-gray-500/10 text-gray-500 border-gray-500/20',
};

const ALL_STATUSES = [
  'pending', 'confirmed', 'shipped', 'delivered', 'failed', 'cancelled'
];

const fmt = (n: number | string) =>
  'DZD ' + new Intl.NumberFormat('fr-DZ').format(Math.round(Number(n)));

export const OrdersManagement: React.FC = () => {
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [actionModal, setActionModal] = useState<'view' | 'assign' | null>(null);
  const [selectedOrder, setSelectedOrder] = useState<any>(null);
  const [confirmatrices, setConfirmatrices] = useState<any[]>([]);
  const [selectedConfirmatrice, setSelectedConfirmatrice] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [trackingLoading, setTrackingLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState<any>(null);
  const [search, setSearch] = useState('');

  const userStr = localStorage.getItem('user');
  const userRole = userStr ? JSON.parse(userStr).role : 'admin';

  const loadOrders = useCallback((p = 1, status = statusFilter, s = search) => {
    setLoading(true);
    const params: any = { page: p, per_page: 20 };
    if (status) params.status = status;
    if (s) params.search = s;
    ordersApi.list(params)
      .then(({ data }) => {
        const savedMethods = JSON.parse(localStorage.getItem('admin_shipping_methods') || '{}');
        const ordersWithMethods = (data.data ?? data).map((o: any) => ({
          ...o,
          shipping_method: savedMethods[o.id] || 'delivery_company'
        }));
        setOrders(ordersWithMethods);
        setMeta(data.meta ?? null);
        setPage(p);
      })
      .catch(() => setError('Failed to load orders.'))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      loadOrders(1, statusFilter, search);
    }, 300);
    return () => clearTimeout(timer);
  }, [search, statusFilter, loadOrders]);

  useEffect(() => {
    usersApi.list({ role: 'confirmatrice', per_page: 100 })
      .then(({ data }) => setConfirmatrices(data.data ?? data));
  }, []);

  const openModal = (type: any, order: any) => {
    setSelectedOrder(order);
    setSelectedConfirmatrice(order.confirmatrice_id ? String(order.confirmatrice_id) : '');
    setActionModal(type);
    if (type === 'view') syncDeliveryStatus(order);
  };

  const syncDeliveryStatus = async (order: any) => {
    if (!order?.tracking_number) return;
    setTrackingLoading(true);
    try {
      const { data } = await ordersApi.syncDeliveryStatus(order.id);
      const synced = data.order ?? data;
      setSelectedOrder((prev: any) => prev?.id === order.id ? { ...prev, ...synced } : prev);
      setOrders(prev => prev.map(o => o.id === order.id ? { ...o, ...synced } : o));
    } catch {
      // Keep existing order details visible if ZR Express is temporarily unavailable.
    } finally {
      setTrackingLoading(false);
    }
  };

  const handleStatusChange = async (order: any, newStatus: string) => {
    if (newStatus === order.status) return;
    try {
      await ordersApi.updateStatus(order.id, { status: newStatus });
      loadOrders(page, statusFilter, search);
      if (selectedOrder?.id === order.id) setSelectedOrder({ ...selectedOrder, status: newStatus });
    } catch (e: any) {
      alert(e.response?.data?.message || 'Status update failed.');
    }
  };

  const handleShippingMethodChange = (order: any, method: string) => {
    setOrders(prev => prev.map(o => o.id === order.id ? { ...o, shipping_method: method } : o));
    if (selectedOrder?.id === order.id) {
      setSelectedOrder({ ...selectedOrder, shipping_method: method });
    }
    const savedMethods = JSON.parse(localStorage.getItem('admin_shipping_methods') || '{}');
    savedMethods[order.id] = method;
    localStorage.setItem('admin_shipping_methods', JSON.stringify(savedMethods));
  };

  const handleAssign = async () => {
    if (!selectedConfirmatrice) return;
    setActionLoading(true);
    try {
      await ordersApi.assignConfirmatrice(selectedOrder.id, Number(selectedConfirmatrice));
      setActionModal(null);
      loadOrders(page, statusFilter, search);
    } catch (e: any) {
      alert(e.response?.data?.message || 'Assignment failed.');
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Orders Management</h1>
          <p className="text-sm text-text-muted mt-1">Track orders, update statuses, and assign confirmatrices.</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 border border-border rounded-lg text-sm font-medium text-text-muted hover:bg-background transition-colors">
          <Download className="w-4 h-4" /> Export CSV
        </button>
      </div>

      <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
        <div className="p-4 border-b border-border flex flex-wrap items-center gap-4 bg-background/50">
          <div className="relative flex-1 min-w-[250px]">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
            <input type="text" value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search by Order ID, Customer, or Marketer..." className="w-full pl-10 pr-4 py-2 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary" />
          </div>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="bg-surface border border-border rounded-lg px-3 py-2 text-sm outline-none focus:border-primary">
            <option value="">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="confirmed">Confirmed</option>
            <option value="shipped">Shipped</option>
            <option value="delivered">Delivered</option>
            <option value="failed">Failed</option>
            <option value="cancelled">Cancelled</option>
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
                  <th className="p-4 font-medium">Order ID</th>
                  <th className="p-4 font-medium">Date</th>
                  <th className="p-4 font-medium">Customer</th>
                  <th className="p-4 font-medium">Marketer</th>
                  <th className="p-4 font-medium">Total</th>
                  <th className="p-4 font-medium">Shipping Method</th>
                  <th className="p-4 font-medium">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {orders.length === 0 ? (
                  <tr><td colSpan={7} className="p-8 text-center text-sm text-text-muted">No orders found.</td></tr>
                ) : orders.map((order) => (
                  <tr key={order.id} onClick={() => openModal('view', order)} className="hover:bg-background/50 transition-colors cursor-pointer">
                    <td className="p-4 text-sm font-bold text-text">{order.reference}</td>
                    <td className="p-4 text-sm text-text-muted">{new Date(order.created_at).toLocaleDateString()}</td>
                    <td className="p-4 text-sm font-medium text-text">{order.client_name}</td>
                    <td className="p-4 text-sm text-text-muted">{order.marketer?.name ?? '—'}</td>
                    <td className="p-4 text-sm font-bold text-text">{fmt(order.total)}</td>
                    <td className="p-4" onClick={(e) => e.stopPropagation()}>
                      <select
                        value={order.shipping_method || 'delivery_company'}
                        onChange={(e) => handleShippingMethodChange(order, e.target.value)}
                        className="appearance-none outline-none pl-3 pr-7 py-1 rounded-lg text-xs font-semibold bg-surface border border-border cursor-pointer focus:border-primary"
                        style={{ backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`, backgroundPosition: 'right 0.25rem center', backgroundRepeat: 'no-repeat', backgroundSize: '1.25em 1.25em' }}
                      >
                        <option value="delivery_company">ZR Express</option>
                        <option value="self_shipping">Self Shipping</option>
                      </select>
                    </td>
                    <td className="p-4" onClick={(e) => e.stopPropagation()}>
                      <select
                        value={order.status}
                        onChange={(e) => handleStatusChange(order, e.target.value)}
                        className={`appearance-none outline-none pl-3 pr-7 py-1 rounded-full text-xs font-bold border cursor-pointer ${STATUS_STYLES[order.status] ?? ''}`}
                        style={{ backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`, backgroundPosition: 'right 0.25rem center', backgroundRepeat: 'no-repeat', backgroundSize: '1.25em 1.25em' }}
                      >
                        {ALL_STATUSES.map((s) => (
                          <option key={s} value={s}>{s}</option>
                        ))}
                      </select>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {meta && meta.last_page > 1 && (
          <div className="p-4 border-t border-border flex items-center justify-between bg-background/20">
            <p className="text-xs text-text-muted">Page {meta.current_page} of {meta.last_page} — {meta.total} orders</p>
            <div className="flex gap-2">
              <button disabled={meta.current_page <= 1} onClick={() => loadOrders(page - 1, statusFilter, search)} className="px-3 py-1.5 border border-border text-sm rounded-lg disabled:opacity-40">Prev</button>
              <button disabled={meta.current_page >= meta.last_page} onClick={() => loadOrders(page + 1, statusFilter, search)} className="px-3 py-1.5 border border-border text-sm rounded-lg disabled:opacity-40">Next</button>
            </div>
          </div>
        )}
      </div>

      {/* View Order Modal */}
      <Modal isOpen={actionModal === 'view'} onClose={() => setActionModal(null)} title={`Order — ${selectedOrder?.reference}`}>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div><p className="text-xs text-text-muted mb-1">Customer</p><p className="text-sm font-semibold text-text">{selectedOrder?.client_name}</p></div>
            <div><p className="text-xs text-text-muted mb-1">Phone</p><p className="text-sm font-semibold text-text">{selectedOrder?.client_phone}</p></div>
            <div><p className="text-xs text-text-muted mb-1">Wilaya / Commune</p><p className="text-sm font-semibold text-text">{selectedOrder?.wilaya} / {selectedOrder?.commune}</p></div>
            <div><p className="text-xs text-text-muted mb-1">Total</p><p className="text-sm font-bold text-primary">{fmt(selectedOrder?.total ?? 0)}</p></div>
            <div><p className="text-xs text-text-muted mb-1">Commission</p><p className="text-sm font-bold text-success">{fmt(selectedOrder?.marketer_commission ?? 0)}</p></div>
            <div><p className="text-xs text-text-muted mb-1">Marketer</p><p className="text-sm font-semibold text-text">{selectedOrder?.marketer?.name ?? '—'}</p></div>
            <div><p className="text-xs text-text-muted mb-1">Shipping Method</p><p className="text-sm font-semibold text-text">{selectedOrder?.shipping_method === 'self_shipping' ? 'Self Shipping' : 'ZR Express'}</p></div>
            <div><p className="text-xs text-text-muted mb-1">Tracking Number</p><p className="text-sm font-semibold text-text">{selectedOrder?.tracking_number ?? '—'}</p></div>
            <div>
              <div className="flex items-center gap-2 mb-1">
                <p className="text-xs text-text-muted">ZR Status</p>
                {selectedOrder?.tracking_number && (
                  <button onClick={() => syncDeliveryStatus(selectedOrder)} className="text-primary hover:text-primary-hover" title="Refresh ZR Express status">
                    <RefreshCw className={`w-3.5 h-3.5 ${trackingLoading ? 'animate-spin' : ''}`} />
                  </button>
                )}
              </div>
              <p className="text-sm font-semibold text-text">{selectedOrder?.delivery_status ?? '—'}</p>
            </div>
            <div><p className="text-xs text-text-muted mb-1">Current Location</p><p className="text-sm font-semibold text-text">{selectedOrder?.delivery_current_location ?? '—'}</p></div>
            <div><p className="text-xs text-text-muted mb-1">Last ZR Sync</p><p className="text-sm font-semibold text-text">{selectedOrder?.delivery_last_synced_at ? new Date(selectedOrder.delivery_last_synced_at).toLocaleString() : '—'}</p></div>
          </div>

          <div>
            <h3 className="text-sm font-bold text-text mb-2">Order Items</h3>
            <div className="space-y-2">
              {(selectedOrder?.items ?? []).map((item: any) => (
                <div key={item.id} className="flex justify-between text-sm p-3 bg-background border border-border rounded-lg">
                  <span>{item.quantity}× {item.product_name} ({item.sku})</span>
                  <span className="font-medium">{fmt(item.line_total)}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="pt-4 border-t border-border flex justify-between items-center">
            <div>
              <p className="text-xs text-text-muted">Confirmatrice</p>
              <p className="text-sm font-semibold text-text">{selectedOrder?.confirmatrice?.name ?? 'Not Assigned'}</p>
            </div>
            {userRole === 'admin' && (
              <button onClick={() => setActionModal('assign')} className="px-3 py-1.5 bg-primary/10 text-primary hover:bg-primary/20 rounded-lg text-xs font-semibold transition-colors">
                {selectedOrder?.confirmatrice ? 'Reassign Agent' : 'Assign Agent'}
              </button>
            )}
          </div>
        </div>
      </Modal>

      {/* Assign Confirmatrice Modal */}
      <Modal isOpen={actionModal === 'assign'} onClose={() => setActionModal('view')} title={`Assign Agent — ${selectedOrder?.reference}`}>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-text mb-1">Select Confirmatrice</label>
            <select value={selectedConfirmatrice} onChange={(e) => setSelectedConfirmatrice(e.target.value)} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
              <option value="">— Select an agent —</option>
              {confirmatrices.map((c) => (
                <option key={c.id} value={c.id}>{c.name} ({c.email})</option>
              ))}
            </select>
          </div>
          <div className="flex justify-end gap-3 pt-4 border-t border-border">
            <button type="button" onClick={() => setActionModal('view')} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm">Cancel</button>
            <button type="button" onClick={handleAssign} disabled={actionLoading || !selectedConfirmatrice} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium flex items-center gap-2 disabled:opacity-50">
              {actionLoading && <Loader2 className="w-4 h-4 animate-spin" />}
              Assign Agent
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
