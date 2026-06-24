import React, { useState, useEffect, useCallback } from 'react';
import { Search, Download, Loader2, RefreshCw, Calendar, LayoutGrid } from 'lucide-react';
import { Modal } from '../components/ui/Modal';
import { ordersApi, usersApi, deliveryApi, STORAGE_URL } from '../services/api';

const STATUS_STYLES: Record<string, string> = {
  pending: 'bg-yellow-500/10 text-yellow-600 border-yellow-500/20',
  confirmed: 'bg-blue-500/10 text-blue-500 border-blue-500/20',
  shipped: 'bg-purple-500/10 text-purple-500 border-purple-500/20',
  delivered: 'bg-success/10 text-success border-success/20',
  retour_facture: 'bg-rose-600/10 text-rose-700 border-rose-600/20',
  retour_exonere: 'bg-orange-600/10 text-orange-700 border-orange-600/20',
  cancelled: 'bg-gray-500/10 text-gray-500 border-gray-500/20',
  appel_1: 'bg-orange-400/10 text-orange-500 border-orange-400/20',
  appel_2: 'bg-orange-500/10 text-orange-600 border-orange-500/20',
  appel_3: 'bg-rose-500/10 text-rose-600 border-rose-500/20',
  reporte: 'bg-indigo-500/10 text-indigo-600 border-indigo-500/20',
};

const STATUS_LABELS: Record<string, string> = {
  pending: 'Pending',
  confirmed: 'Confirmed',
  shipped: 'Shipped',
  delivered: 'Delivered',
  retour_facture: 'Retour Facturé',
  retour_exonere: 'Retour Exonéré',
  cancelled: 'Cancelled',
  appel_1: 'Appel 1',
  appel_2: 'Appel 2',
  appel_3: 'Appel 3',
  reporte: 'Reporté',
};

const ALL_STATUSES = [
  'pending', 'confirmed', 'shipped', 'delivered', 'retour_facture', 'retour_exonere', 'cancelled',
  'appel_1', 'appel_2', 'appel_3', 'reporte'
];

const fmt = (n: number | string) =>
  'DZD ' + new Intl.NumberFormat('fr-DZ').format(Math.round(Number(n)));

const formatDateOnly = (dateStr: string) => {
  if (!dateStr) return '';
  const parts = dateStr.slice(0, 10).split('-');
  if (parts.length !== 3) return dateStr;
  return `${parts[2]}/${parts[1]}/${parts[0]}`;
};

const getLocalTodayString = () => {
  const d = new Date();
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

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
  // For inline postpone date picker
  const [postponeDateMap, setPostponeDateMap] = useState<Record<number, string>>({});

  const [territories, setTerritories] = useState<any[]>([]);
  const [isEditingOrder, setIsEditingOrder] = useState(false);
  const [editClientName, setEditClientName] = useState('');
  const [editClientPhone, setEditClientPhone] = useState('');
  const [editWilaya, setEditWilaya] = useState('');
  const [editCommune, setEditCommune] = useState('');
  const [editAddress, setEditAddress] = useState('');
  const [editDeliveryType, setEditDeliveryType] = useState<'home' | 'desk'>('home');
  const [editNotes, setEditNotes] = useState('');
  const [isSavingAddress, setIsSavingAddress] = useState(false);
  const [addressError, setAddressError] = useState('');

  const [selectedIds, setSelectedIds] = useState<number[]>([]);

  useEffect(() => {
    setSelectedIds([]);
  }, [search, statusFilter, page]);

  const userStr = localStorage.getItem('user');
  const userRole = userStr ? JSON.parse(userStr).role : 'admin';

  const loadOrders = useCallback((p = 1, status = statusFilter, s = search, append = false) => {
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
        setOrders((prev: any[]) => append ? [...prev, ...ordersWithMethods] : ordersWithMethods);
        const metaObj = data.meta ?? {
          current_page: data.current_page ?? 1,
          last_page: data.last_page ?? 1,
          total: data.total ?? 0
        };
        setMeta(metaObj);
        setPage(p);
      })
      .catch(() => setError('Failed to load orders.'))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      loadOrders(1, statusFilter, search, false);
    }, 300);
    return () => clearTimeout(timer);
  }, [search, statusFilter, loadOrders]);

  useEffect(() => {
    usersApi.list({ role: 'confirmatrice', per_page: 100 })
      .then(({ data }) => setConfirmatrices(data.data ?? data));
    deliveryApi.territories()
      .then(({ data }) => setTerritories(data.data ?? data))
      .catch((err) => console.error('Failed to load territories', err));
  }, []);

  const openModal = (type: any, order: any) => {
    setSelectedOrder(order);
    setSelectedConfirmatrice(order.confirmatrice_id ? String(order.confirmatrice_id) : '');
    setActionModal(type);
    setIsEditingOrder(false);
    setEditClientName(order?.client_name ?? '');
    setEditClientPhone(order?.client_phone ?? '');
    setEditWilaya(order?.wilaya ?? '');
    setEditCommune(order?.commune ?? '');
    setEditAddress(order?.address ?? '');
    setEditDeliveryType(order?.delivery_type ?? 'home');
    setEditNotes(order?.notes ?? '');
    setAddressError('');
    if (type === 'view') syncDeliveryStatus(order);
  };

  const syncDeliveryStatus = async (order: any) => {
    if (!order?.tracking_number) return;
    setTrackingLoading(true);
    try {
      const { data } = await ordersApi.syncDeliveryStatus(order.id);
      const synced = data.order ?? data;
      setSelectedOrder((prev: any) => prev?.id === order.id ? { ...prev, ...synced } : prev);
      setOrders((prev: any[]) => prev.map(o => o.id === order.id ? { ...o, ...synced } : o));
    } catch {
      // Keep existing order details visible if ZR Express is temporarily unavailable.
    } finally {
      setTrackingLoading(false);
    }
  };

  const getSelectedTerritory = (wilayaValue: string) => {
    if (!wilayaValue) return null;
    const codePart = wilayaValue.includes(' - ') ? wilayaValue.split(' - ')[0].trim() : null;
    const namePart = wilayaValue.includes(' - ') ? wilayaValue.split(' - ')[1].trim() : wilayaValue.trim();
    
    return territories.find(t => 
      (codePart && t.code === codePart) || 
      t.name.toLowerCase() === namePart.toLowerCase()
    );
  };

  const handleSaveOrderDetails = async () => {
    if (!selectedOrder) return;
    setIsSavingAddress(true);
    setAddressError('');
    try {
      const res = await ordersApi.update(selectedOrder.id, {
        client_name: editClientName,
        client_phone: editClientPhone,
        wilaya: editWilaya,
        commune: editCommune,
        address: editAddress,
        delivery_type: editDeliveryType,
        notes: editNotes,
      });
      const updatedOrder = res.data;
      setOrders((prev: any[]) => prev.map(o => o.id === selectedOrder.id ? { ...o, ...updatedOrder } : o));
      setSelectedOrder((prev: any) => prev ? { ...prev, ...updatedOrder } : null);
      setIsEditingOrder(false);
    } catch (err: any) {
      console.error(err);
      setAddressError(err.response?.data?.message || 'Failed to update order details');
    } finally {
      setIsSavingAddress(false);
    }
  };

  const handleDeleteOrder = async (orderId: number) => {
    if (!window.confirm("Voulez-vous vraiment supprimer cette commande ?")) return;
    setActionLoading(true);
    try {
      await ordersApi.delete(orderId);
      alert("Commande supprimée avec succès.");
      setActionModal(null);
      loadOrders(page, statusFilter, search);
    } catch (e: any) {
      alert(e.response?.data?.message || "Échec de la suppression de la commande.");
    } finally {
      setActionLoading(false);
    }
  };

  const handleBulkShip = async () => {
    if (selectedIds.length === 0) return;

    // Filter out orders with self_shipping
    const validIds: number[] = [];
    const selfShippingOrders: any[] = [];
    for (const id of selectedIds) {
      const order = orders.find(o => o.id === id);
      if (order?.shipping_method === 'self_shipping') {
        selfShippingOrders.push(order);
      } else {
        validIds.push(id);
      }
    }

    if (selfShippingOrders.length > 0 && validIds.length === 0) {
      alert("Toutes les commandes sélectionnées ont pour méthode de livraison 'Self Shipping'. Aucune commande n'a été envoyée à ZR Express.");
      return;
    }

    let confirmMsg = `Voulez-vous envoyer les ${validIds.length} commandes sélectionnées à ZR Express ?`;
    if (selfShippingOrders.length > 0) {
      confirmMsg += `\n(Note : ${selfShippingOrders.length} commande(s) avec 'Self Shipping' seront exclues)`;
    }

    if (!window.confirm(confirmMsg)) return;

    setActionLoading(true);
    try {
      const res = await ordersApi.bulkShip(validIds);
      const { success_count, errors } = res.data;
      let msg = `${success_count} commande(s) envoyée(s) avec succès.`;
      const errKeys = Object.keys(errors);
      if (errKeys.length > 0) {
        msg += `\nÉchecs : ${errKeys.length} commande(s).`;
        console.error('Bulk ship errors:', errors);
      }
      alert(msg);
      setSelectedIds([]);
      loadOrders(page, statusFilter, search);
    } catch (e: any) {
      alert(e.response?.data?.message || 'Une erreur est survenue lors de l\'envoi en masse.');
    } finally {
      setActionLoading(false);
    }
  };

  const handleBulkDelete = async () => {
    if (selectedIds.length === 0) return;
    if (!window.confirm(`Voulez-vous supprimer les ${selectedIds.length} commandes sélectionnées ?`)) return;
    setActionLoading(true);
    try {
      const res = await ordersApi.bulkDelete(selectedIds);
      const { success_count, errors } = res.data;
      let msg = `${success_count} commande(s) supprimée(s) avec succès.`;
      const errKeys = Object.keys(errors);
      if (errKeys.length > 0) {
        msg += `\nImpossible de supprimer ${errKeys.length} commande(s) car elles sont déjà en livraison.`;
        console.error('Bulk delete errors:', errors);
      }
      alert(msg);
      setSelectedIds([]);
      loadOrders(page, statusFilter, search);
    } catch (e: any) {
      alert(e.response?.data?.message || 'Une erreur est survenue lors de la suppression en masse.');
    } finally {
      setActionLoading(false);
    }
  };

  const handleStatusChange = async (order: any, newStatus: string) => {
    if (newStatus === order.status) return;

    // If setting to reporté, require a date first
    if (newStatus === 'reporte') {
      const dateVal = postponeDateMap[order.id];
      if (!dateVal) {
        // Show date picker — update map to signal user must pick date
        setPostponeDateMap((prev: Record<number, string>) => ({ ...prev, [order.id]: '' }));
        return;
      }
      try {
        await ordersApi.updateStatus(order.id, { status: newStatus, postponed_until: dateVal, shipping_method: order.shipping_method });
        setPostponeDateMap((prev: Record<number, string>) => { const m = { ...prev }; delete m[order.id]; return m; });
        loadOrders(page, statusFilter, search);
        if (selectedOrder?.id === order.id) setSelectedOrder({ ...selectedOrder, status: newStatus });
      } catch (e: any) {
        alert(e.response?.data?.message || 'Status update failed.');
      }
      return;
    }

    try {
      await ordersApi.updateStatus(order.id, { status: newStatus, shipping_method: order.shipping_method });
      // Clear any pending postpone date if status changed away from reporte
      setPostponeDateMap((prev: Record<number, string>) => { const m = { ...prev }; delete m[order.id]; return m; });
      loadOrders(page, statusFilter, search);
      if (selectedOrder?.id === order.id) setSelectedOrder({ ...selectedOrder, status: newStatus });
    } catch (e: any) {
      alert(e.response?.data?.message || 'Status update failed.');
    }
  };

  const handleShippingMethodChange = (order: any, method: string) => {
    setOrders((prev: any[]) => prev.map(o => o.id === order.id ? { ...o, shipping_method: method } : o));
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

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedIds(orders.map(o => o.id));
    } else {
      setSelectedIds([]);
    }
  };

  const handleSelectOne = (id: number, checked: boolean) => {
    if (checked) {
      setSelectedIds(prev => [...prev, id]);
    } else {
      setSelectedIds(prev => prev.filter(x => x !== id));
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
            {ALL_STATUSES.map(s => (
              <option key={s} value={s}>{STATUS_LABELS[s]}</option>
            ))}
          </select>
        </div>

        {selectedIds.length > 0 && (
          <div className="p-3 bg-primary/5 border-b border-border flex items-center justify-between px-4 animate-fadeIn">
            <span className="text-xs font-semibold text-primary">
              {selectedIds.length} commande(s) sélectionnée(s)
            </span>
            <div className="flex gap-2">
              <button
                onClick={handleBulkShip}
                disabled={actionLoading}
                className="px-3 py-1.5 bg-primary hover:bg-primary/95 text-white text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 disabled:opacity-50"
              >
                Envoyer à ZR Express
              </button>
              <button
                onClick={handleBulkDelete}
                disabled={actionLoading}
                className="px-3 py-1.5 bg-danger hover:bg-danger/90 text-white text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 disabled:opacity-50"
              >
                Supprimer
              </button>
            </div>
          </div>
        )}

        {loading ? (
          <div className="flex items-center justify-center py-16"><Loader2 className="w-8 h-8 text-primary animate-spin" /></div>
        ) : error ? (
          <div className="p-6 text-sm text-danger">{error}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider">
                  <th className="p-4 w-10">
                    <input
                      type="checkbox"
                      checked={orders.length > 0 && selectedIds.length === orders.length}
                      onChange={(e) => handleSelectAll(e.target.checked)}
                      className="rounded border-border text-primary focus:ring-primary w-4 h-4 cursor-pointer"
                    />
                  </th>
                  <th className="p-4 font-medium">Order ID</th>
                  <th className="p-4 font-medium">Date</th>
                  <th className="p-4 font-medium">Product</th>
                  <th className="p-4 font-medium">Customer</th>
                  <th className="p-4 font-medium">Marketer</th>
                  <th className="p-4 font-medium">Total</th>
                  <th className="p-4 font-medium">Shipping Method</th>
                  <th className="p-4 font-medium">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {orders.length === 0 ? (
                  <tr><td colSpan={9} className="p-8 text-center text-sm text-text-muted">No orders found.</td></tr>
                ) : orders.map((order) => (
                  <React.Fragment key={order.id}>
                    <tr onClick={() => openModal('view', order)} className="hover:bg-background/50 transition-colors cursor-pointer">
                      <td className="p-4 w-10" onClick={(e) => e.stopPropagation()}>
                        <input
                          type="checkbox"
                          checked={selectedIds.includes(order.id)}
                          onChange={(e) => handleSelectOne(order.id, e.target.checked)}
                          className="rounded border-border text-primary focus:ring-primary w-4 h-4 cursor-pointer"
                        />
                      </td>
                      <td className="p-4 text-sm font-bold text-text">{order.reference}</td>
                      <td className="p-4 text-sm text-text-muted">
                        <div>{new Date(order.created_at).toLocaleDateString()}</div>
                        {order.status === 'reporte' && order.postponed_until && (
                          <div className="text-xs text-indigo-500 mt-0.5 flex items-center gap-1">
                            <Calendar className="w-3 h-3" />
                            Reporté au {formatDateOnly(order.postponed_until)}
                          </div>
                        )}
                      </td>
                      <td className="p-4 text-sm">
                        <div className="flex flex-col gap-1.5 max-w-[200px]">
                          {(order.items ?? []).map((item: any, idx: number) => {
                            const imgPath = item.variant?.image_path || item.variant?.product?.main_image_path;
                            const imgUrl = imgPath
                              ? (imgPath.startsWith('http') ? imgPath : `${STORAGE_URL}/${imgPath}`)
                              : null;
                            return (
                              <div key={item.id || idx} className="flex items-center gap-2">
                                {imgUrl ? (
                                  <img
                                    src={imgUrl}
                                    alt={item.product_name}
                                    className="w-8 h-8 rounded-lg object-cover border border-border shrink-0"
                                  />
                                ) : (
                                  <div className="w-8 h-8 rounded-lg bg-background flex items-center justify-center border border-border shrink-0">
                                    <LayoutGrid className="w-4 h-4 text-text-muted" />
                                  </div>
                                )}
                                <span className="text-xs font-medium text-text line-clamp-1" title={item.product_name}>
                                  {item.product_name}
                                </span>
                              </div>
                            );
                          })}
                        </div>
                      </td>
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
                            <option key={s} value={s}>{STATUS_LABELS[s]}</option>
                          ))}
                        </select>
                      </td>
                    </tr>
                    {/* Postpone date row — appears when admin selects "Reporté" */}
                    {order.id in postponeDateMap && (
                      <tr className="bg-indigo-500/5 border-b border-indigo-500/20" onClick={(e) => e.stopPropagation()}>
                        <td colSpan={9} className="px-4 py-3">
                          <div className="flex items-center gap-3 flex-wrap">
                            <Calendar className="w-4 h-4 text-indigo-500 shrink-0" />
                            <span className="text-sm font-medium text-indigo-600">Date de report requise :</span>
                            <input
                              type="date"
                              className="px-3 py-1.5 border border-indigo-300 rounded-lg text-sm bg-surface focus:outline-none focus:border-indigo-500"
                              value={postponeDateMap[order.id] || ''}
                              min={getLocalTodayString()}
                              onChange={(e) => setPostponeDateMap((prev: Record<number, string>) => ({ ...prev, [order.id]: e.target.value }))}
                            />
                            <button
                              onClick={() => handleStatusChange(order, 'reporte')}
                              disabled={!postponeDateMap[order.id]}
                              className="px-3 py-1.5 bg-indigo-600 text-white text-sm font-medium rounded-lg disabled:opacity-40 hover:bg-indigo-700 transition-colors"
                            >
                              Confirmer le report
                            </button>
                            <button
                              onClick={() => setPostponeDateMap((prev: Record<number, string>) => { const m = { ...prev }; delete m[order.id]; return m; })}
                              className="px-3 py-1.5 border border-border text-sm text-text-muted rounded-lg hover:bg-background transition-colors"
                            >
                              Annuler
                            </button>
                            {order.postponed_until && (
                              <span className="text-xs text-indigo-500">Actuellement reporté au : {formatDateOnly(order.postponed_until)}</span>
                            )}
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {meta && meta.last_page > page && (
          <div className="p-4 border-t border-border flex justify-center bg-background/20">
            <button
              onClick={() => loadOrders(page + 1, statusFilter, search, true)}
              disabled={loading}
              className="flex items-center gap-2 px-5 py-2 border border-border bg-surface text-text hover:bg-background text-sm font-semibold rounded-xl transition-all duration-200 cursor-pointer shadow-sm disabled:opacity-40"
            >
              {loading && <Loader2 className="w-4 h-4 animate-spin" />}
              Load More
            </button>
          </div>
        )}
      </div>

      {/* View Order Modal */}
      <Modal isOpen={actionModal === 'view'} onClose={() => setActionModal(null)} title={`Order — ${selectedOrder?.reference}`}>
        <div className="space-y-4 font-sans">
          <div className="grid grid-cols-2 gap-4">
            <div className="col-span-2 border border-border/60 bg-background/20 p-4 rounded-xl space-y-4">
              <p className="text-xs font-bold text-text-muted uppercase tracking-wider">Order & Customer Details</p>
              {isEditingOrder ? (
                <div className="space-y-3">
                  <div className="space-y-1">
                    <label className="text-xs font-semibold text-text-muted uppercase tracking-wider">Client Name</label>
                    <input
                      type="text"
                      value={editClientName}
                      onChange={(e) => setEditClientName(e.target.value)}
                      className="w-full text-sm p-2 bg-background border border-border rounded-lg text-text focus:outline-none focus:border-primary font-medium"
                    />
                  </div>

                  <div className="space-y-1">
                    <label className="text-xs font-semibold text-text-muted uppercase tracking-wider">Client Phone</label>
                    <input
                      type="text"
                      value={editClientPhone}
                      onChange={(e) => setEditClientPhone(e.target.value)}
                      className="w-full text-sm p-2 bg-background border border-border rounded-lg text-text focus:outline-none focus:border-primary font-medium"
                    />
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                    <div className="space-y-1">
                      <label className="text-xs font-semibold text-text-muted uppercase tracking-wider">Wilaya</label>
                      <select
                        value={editWilaya}
                        onChange={(e) => {
                          const val = e.target.value;
                          setEditWilaya(val);
                          const terr = getSelectedTerritory(val);
                          if (terr && terr.communes && terr.communes.length > 0) {
                            setEditCommune(terr.communes[0].name);
                          } else {
                            setEditCommune('');
                          }
                        }}
                        className="w-full text-sm p-2 bg-background border border-border rounded-lg text-text focus:outline-none focus:border-primary font-medium"
                      >
                        <option value="">Select Wilaya</option>
                        {territories.map((t) => (
                          <option key={t.code} value={`${t.code} - ${t.name}`}>
                            {t.code} - {t.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="space-y-1">
                      <label className="text-xs font-semibold text-text-muted uppercase tracking-wider">Commune</label>
                      <select
                        value={editCommune}
                        onChange={(e) => setEditCommune(e.target.value)}
                        disabled={!editWilaya}
                        className="w-full text-sm p-2 bg-background border border-border rounded-lg text-text focus:outline-none focus:border-primary font-medium disabled:opacity-50"
                      >
                        <option value="">Select Commune</option>
                        {(getSelectedTerritory(editWilaya)?.communes ?? []).map((c: any) => (
                          <option key={c.id} value={c.name}>
                            {c.name}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>

                  <div className="space-y-1">
                    <label className="text-xs font-semibold text-text-muted uppercase tracking-wider">Detailed Address</label>
                    <textarea
                      value={editAddress}
                      onChange={(e) => setEditAddress(e.target.value)}
                      rows={2}
                      className="w-full text-sm p-2 bg-background border border-border rounded-lg text-text focus:outline-none focus:border-primary font-medium"
                    />
                  </div>

                  {editWilaya && (() => {
                    const selectedTerritory = getSelectedTerritory(editWilaya);
                    const homePrice = selectedTerritory?.home_price ?? 0;
                    const deskPrice = selectedTerritory?.desk_price ?? 0;
                    const homeActive = selectedTerritory?.home_active !== false;
                    const deskActive = selectedTerritory?.desk_active !== false;

                    return (
                      <div className="space-y-2">
                        <label className="block text-xs font-semibold text-text-muted uppercase tracking-wider">
                          Delivery Type
                        </label>
                        <div className="grid grid-cols-2 gap-2">
                          <div
                            onClick={() => homeActive && setEditDeliveryType('home')}
                            className={`flex flex-col p-2 rounded-lg border-2 transition-all cursor-pointer select-none ${
                              !homeActive
                                ? 'opacity-40 cursor-not-allowed border-border bg-background/50'
                                : editDeliveryType === 'home'
                                ? 'border-primary bg-primary/5 text-text font-semibold'
                                : 'border-border bg-background hover:bg-background/80 text-text'
                            }`}
                          >
                            <div className="flex items-center justify-between">
                              <span className="text-xs font-bold">To Home</span>
                              <input
                                type="radio"
                                name="edit_delivery_type"
                                checked={editDeliveryType === 'home'}
                                disabled={!homeActive}
                                onChange={() => {}}
                                className="w-3.5 h-3.5 text-primary focus:ring-primary border-border"
                              />
                            </div>
                            <span className="text-xs font-extrabold text-primary mt-1">{fmt(homePrice)}</span>
                            {!homeActive && (
                              <span className="text-[10px] text-danger mt-0.5">Unavailable</span>
                            )}
                          </div>

                          <div
                            onClick={() => deskActive && setEditDeliveryType('desk')}
                            className={`flex flex-col p-2 rounded-lg border-2 transition-all cursor-pointer select-none ${
                              !deskActive
                                ? 'opacity-40 cursor-not-allowed border-border bg-background/50'
                                : editDeliveryType === 'desk'
                                ? 'border-primary bg-primary/5 text-text font-semibold'
                                : 'border-border bg-background hover:bg-background/80 text-text'
                            }`}
                          >
                            <div className="flex items-center justify-between">
                              <span className="text-xs font-bold">Stopdesk</span>
                              <input
                                type="radio"
                                name="edit_delivery_type"
                                checked={editDeliveryType === 'desk'}
                                disabled={!deskActive}
                                onChange={() => {}}
                                className="w-3.5 h-3.5 text-primary focus:ring-primary border-border"
                              />
                            </div>
                            <span className="text-xs font-extrabold text-primary mt-1">{fmt(deskPrice)}</span>
                            {!deskActive && (
                              <span className="text-[10px] text-danger mt-0.5">Unavailable</span>
                            )}
                          </div>
                        </div>

                        <div className="bg-background/60 p-2.5 rounded-lg border border-border space-y-1">
                          <div className="flex justify-between text-xs text-text-muted">
                            <span>Subtotal:</span>
                            <span className="font-semibold text-text">{fmt(selectedOrder?.subtotal ?? 0)}</span>
                          </div>
                          <div className="flex justify-between text-xs text-text-muted">
                            <span>Shipping Fee:</span>
                            <span className="font-bold text-primary">
                              +{fmt(editDeliveryType === 'home' ? homePrice : deskPrice)}
                            </span>
                          </div>
                          <div className="flex justify-between text-xs font-extrabold border-t border-border/40 pt-1 text-text">
                            <span>Estimated Total:</span>
                            <span className="text-primary font-bold">
                              {fmt(Number(selectedOrder?.subtotal ?? 0) + (editDeliveryType === 'home' ? homePrice : deskPrice))}
                            </span>
                          </div>
                        </div>
                      </div>
                    );
                  })()}

                  <div className="space-y-1">
                    <label className="text-xs font-semibold text-text-muted uppercase tracking-wider">Order Notes</label>
                    <textarea
                      value={editNotes}
                      onChange={(e) => setEditNotes(e.target.value)}
                      rows={2}
                      className="w-full text-sm p-2 bg-background border border-border rounded-lg text-text focus:outline-none focus:border-primary font-medium"
                    />
                  </div>

                  {addressError && <p className="text-xs text-danger">{addressError}</p>}

                  <div className="flex gap-2 justify-end">
                    <button
                      onClick={() => setIsEditingOrder(false)}
                      disabled={isSavingAddress}
                      className="px-3 py-1.5 text-xs border border-border text-text-muted hover:bg-background rounded-lg font-medium"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={handleSaveOrderDetails}
                      disabled={isSavingAddress || !editWilaya || !editCommune || !editClientName || !editClientPhone}
                      className="px-3 py-1.5 text-xs bg-primary text-white hover:bg-primary-hover rounded-lg font-semibold flex items-center gap-1"
                    >
                      {isSavingAddress ? 'Saving...' : 'Save Changes'}
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-3">
                  <div className="flex justify-between items-start">
                    <div className="space-y-2">
                      <div>
                        <p className="text-xs text-text-muted uppercase tracking-wider font-bold">Client Name & Phone</p>
                        <p className="text-sm font-semibold text-text font-medium">
                          {selectedOrder?.client_name} ({selectedOrder?.client_phone})
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-text-muted uppercase tracking-wider font-bold">Wilaya & Commune</p>
                        <p className="text-sm font-semibold text-text font-medium">
                          {selectedOrder?.wilaya} / {selectedOrder?.commune}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-text-muted uppercase tracking-wider font-bold">Address</p>
                        <p className="text-sm font-semibold text-text font-medium">
                          {selectedOrder?.address || '—'}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-text-muted uppercase tracking-wider font-bold">Delivery Type</p>
                        <p className="text-sm font-semibold text-text capitalize font-medium">
                          {selectedOrder?.delivery_type === 'desk' ? 'Stopdesk' : 'To Home'}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-text-muted uppercase tracking-wider font-bold">Notes</p>
                        <p className="text-sm text-text font-semibold italic">
                          {selectedOrder?.notes || '—'}
                        </p>
                      </div>
                    </div>
                    {selectedOrder?.status !== 'delivered' && selectedOrder?.status !== 'retour_facture' && selectedOrder?.status !== 'retour_exonere' && selectedOrder?.status !== 'cancelled' && (
                      <button
                        onClick={() => {
                          setEditClientName(selectedOrder?.client_name ?? '');
                          setEditClientPhone(selectedOrder?.client_phone ?? '');
                          setEditWilaya(selectedOrder?.wilaya ?? '');
                          setEditCommune(selectedOrder?.commune ?? '');
                          setEditAddress(selectedOrder?.address ?? '');
                          setEditDeliveryType(selectedOrder?.delivery_type ?? 'home');
                          setEditNotes(selectedOrder?.notes ?? '');
                          setIsEditingOrder(true);
                          setAddressError('');
                        }}
                        className="text-primary hover:text-primary-hover text-xs font-semibold underline shrink-0"
                      >
                        Edit Order Info
                      </button>
                    )}
                  </div>
                </div>
              )}
            </div>
            <div><p className="text-xs text-text-muted mb-1 font-semibold uppercase tracking-wider">Subtotal</p><p className="text-sm font-semibold text-text">{fmt(selectedOrder?.subtotal ?? 0)}</p></div>
            <div><p className="text-xs text-text-muted mb-1 font-semibold uppercase tracking-wider">Shipping Fee</p><p className="text-sm font-semibold text-text">{fmt(selectedOrder?.shipping_fee ?? 0)}</p></div>
            <div><p className="text-xs text-text-muted mb-1 font-semibold uppercase tracking-wider">Total</p><p className="text-sm font-bold text-primary">{fmt(selectedOrder?.total ?? 0)}</p></div>
            <div><p className="text-xs text-text-muted mb-1 font-semibold uppercase tracking-wider">Commission</p><p className="text-sm font-bold text-success">{fmt(selectedOrder?.marketer_commission ?? 0)}</p></div>
            <div><p className="text-xs text-text-muted mb-1 font-semibold uppercase tracking-wider">Marketer</p><p className="text-sm font-semibold text-text">{selectedOrder?.marketer?.name ?? '—'}</p></div>
            <div><p className="text-xs text-text-muted mb-1 font-semibold uppercase tracking-wider">Shipping Method</p><p className="text-sm font-semibold text-text">{selectedOrder?.shipping_method === 'self_shipping' ? 'Self Shipping' : 'ZR Express'}</p></div>
            <div><p className="text-xs text-text-muted mb-1 font-semibold uppercase tracking-wider">Tracking Number</p><p className="text-sm font-semibold text-text">{selectedOrder?.tracking_number ?? '—'}</p></div>
            <div>
              <div className="flex items-center gap-2 mb-1">
                <p className="text-xs text-text-muted font-semibold uppercase tracking-wider">ZR Status</p>
                {selectedOrder?.tracking_number && (
                  <button onClick={() => syncDeliveryStatus(selectedOrder)} className="text-primary hover:text-primary-hover" title="Refresh ZR Express status">
                    <RefreshCw className={`w-3.5 h-3.5 ${trackingLoading ? 'animate-spin' : ''}`} />
                  </button>
                )}
              </div>
              <p className="text-sm font-semibold text-text">{selectedOrder?.delivery_status ?? '—'}</p>
            </div>
            <div><p className="text-xs text-text-muted mb-1 font-semibold uppercase tracking-wider">Current Location</p><p className="text-sm font-semibold text-text">{selectedOrder?.delivery_current_location ?? '—'}</p></div>
            <div><p className="text-xs text-text-muted mb-1 font-semibold uppercase tracking-wider">Last ZR Sync</p><p className="text-sm font-semibold text-text">{selectedOrder?.delivery_last_synced_at ? new Date(selectedOrder.delivery_last_synced_at).toLocaleString() : '—'}</p></div>
            {selectedOrder?.status === 'reporte' && selectedOrder?.postponed_until && (
              <div className="col-span-2">
                <p className="text-xs text-indigo-500 mb-1 flex items-center gap-1 font-semibold uppercase tracking-wider"><Calendar className="w-3 h-3" /> Reporté jusqu'au</p>
                <p className="text-sm font-semibold text-indigo-600">{formatDateOnly(selectedOrder.postponed_until)}</p>
              </div>
            )}
          </div>

          <div>
            <h3 className="text-sm font-bold text-text mb-2">Order Items</h3>
            <div className="space-y-2">
              {(selectedOrder?.items ?? []).map((item: any) => {
                const imgPath = item.variant?.image_path || item.variant?.product?.main_image_path;
                const imgUrl = imgPath
                  ? (imgPath.startsWith('http') ? imgPath : `${STORAGE_URL}/${imgPath}`)
                  : null;
                return (
                  <div key={item.id} className="flex items-center justify-between text-sm p-3 bg-background border border-border rounded-lg">
                    <div className="flex items-center gap-3">
                      {imgUrl ? (
                        <img
                          src={imgUrl}
                          alt={item.product_name}
                          className="w-12 h-12 rounded-lg object-cover border border-border shrink-0"
                        />
                      ) : (
                        <div className="w-12 h-12 rounded-lg bg-background/50 flex items-center justify-center border border-border shrink-0">
                          <LayoutGrid className="w-6 h-6 text-text-muted" />
                        </div>
                      )}
                      <div>
                        <p className="font-semibold text-text">{item.product_name}</p>
                        <p className="text-xs text-text-muted">SKU: {item.sku} • Qty: {item.quantity}</p>
                      </div>
                    </div>
                    <span className="font-semibold text-text">{fmt(item.line_total)}</span>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="pt-4 border-t border-border flex justify-between items-center">
            <div className="flex items-center gap-4">
              <div>
                <p className="text-xs text-text-muted">Confirmatrice</p>
                <p className="text-sm font-semibold text-text">{selectedOrder?.confirmatrice?.name ?? 'Not Assigned'}</p>
              </div>
              {userRole === 'admin' && selectedOrder?.status !== 'delivered' && selectedOrder?.status !== 'retour_facture' && selectedOrder?.status !== 'retour_exonere' && (
                <button
                  onClick={() => handleDeleteOrder(selectedOrder.id)}
                  disabled={actionLoading}
                  className="px-3 py-1.5 bg-danger/10 text-danger hover:bg-danger/25 rounded-lg text-xs font-semibold transition-colors ml-4"
                >
                  Supprimer la commande
                </button>
              )}
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
