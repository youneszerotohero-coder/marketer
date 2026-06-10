import React, { useState, useEffect, useCallback, useRef } from 'react';
import { Truck, Search, Save, ToggleLeft, ToggleRight, Home, Store, AlertTriangle, CheckCircle, XCircle, RefreshCw } from 'lucide-react';
import { shippingRatesApi } from '../services/api';

interface ShippingRate {
  id: number;
  wilaya_code: string;
  wilaya_name: string;
  wilaya_name_ar: string;
  home_price: number;
  desk_price: number;
  is_active: boolean;
  home_active: boolean;
  desk_active: boolean;
}

type ToastType = 'success' | 'error';

interface Toast {
  id: number;
  type: ToastType;
  message: string;
}

export const ShippingRates: React.FC = () => {
  const [rates, setRates] = useState<ShippingRate[]>([]);
  const [localRates, setLocalRates] = useState<ShippingRate[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [search, setSearch] = useState('');
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [hasChanges, setHasChanges] = useState(false);
  const toastIdRef = useRef(0);

  const addToast = useCallback((type: ToastType, message: string) => {
    const id = ++toastIdRef.current;
    setToasts((prev) => [...prev, { id, type, message }]);
    setTimeout(() => setToasts((prev) => prev.filter((t) => t.id !== id)), 4000);
  }, []);

  const fetchRates = useCallback(async () => {
    setLoading(true);
    try {
      const res = await shippingRatesApi.list();
      const data: ShippingRate[] = res.data.data || res.data;
      setRates(data);
      setLocalRates(data.map((r) => ({ ...r })));
      setHasChanges(false);
    } catch {
      addToast('error', 'Failed to load shipping rates');
    } finally {
      setLoading(false);
    }
  }, [addToast]);

  useEffect(() => {
    fetchRates();
  }, [fetchRates]);

  const updateLocal = (id: number, changes: Partial<ShippingRate>) => {
    setLocalRates((prev) =>
      prev.map((r) => (r.id === id ? { ...r, ...changes } : r))
    );
    setHasChanges(true);
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await shippingRatesApi.bulkUpdate(
        localRates.map((r) => ({
          id: r.id,
          home_price: r.home_price,
          desk_price: r.desk_price,
          is_active: r.is_active,
          home_active: r.home_active,
          desk_active: r.desk_active,
        }))
      );
      setRates(localRates.map((r) => ({ ...r })));
      setHasChanges(false);
      addToast('success', 'Shipping rates saved successfully!');
    } catch {
      addToast('error', 'Failed to save shipping rates');
    } finally {
      setSaving(false);
    }
  };

  const handleDiscard = () => {
    setLocalRates(rates.map((r) => ({ ...r })));
    setHasChanges(false);
  };

  const filtered = localRates.filter((r) => {
    const q = search.toLowerCase();
    return (
      r.wilaya_name.toLowerCase().includes(q) ||
      r.wilaya_name_ar.includes(search) ||
      r.wilaya_code.includes(q)
    );
  });

  const activeCount = localRates.filter((r) => r.is_active).length;
  const inactiveCount = localRates.length - activeCount;

  return (
    <div className="space-y-6">
      {/* Toast Notifications */}
      <div className="fixed top-6 right-6 z-50 space-y-2 pointer-events-none">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={`flex items-center gap-3 px-4 py-3 rounded-xl shadow-lg text-sm font-medium text-white transition-all duration-300 animate-in slide-in-from-right-4 ${
              t.type === 'success' ? 'bg-emerald-500' : 'bg-red-500'
            }`}
          >
            {t.type === 'success' ? (
              <CheckCircle className="w-4 h-4 flex-shrink-0" />
            ) : (
              <XCircle className="w-4 h-4 flex-shrink-0" />
            )}
            {t.message}
          </div>
        ))}
      </div>

      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Shipping Rates</h1>
          <p className="text-sm text-text-muted mt-1">
            Manage delivery prices and availability for each wilaya across Algeria.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={fetchRates}
            disabled={loading}
            className="flex items-center gap-2 px-3 py-2 border border-border text-text-muted bg-surface hover:bg-background rounded-lg text-sm font-medium transition-colors"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          {hasChanges && (
            <button
              onClick={handleDiscard}
              className="flex items-center gap-2 px-4 py-2 border border-border text-text-muted bg-surface hover:bg-background rounded-lg text-sm font-medium transition-colors"
            >
              Discard
            </button>
          )}
          <button
            onClick={handleSave}
            disabled={saving || !hasChanges}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors shadow-md shadow-primary/20 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Save className="w-4 h-4" />
            {saving ? 'Saving...' : 'Save All Changes'}
          </button>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="bg-surface border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
            <Truck className="w-5 h-5 text-primary" />
          </div>
          <div>
            <p className="text-xs text-text-muted font-medium">Total Wilayas</p>
            <p className="text-xl font-bold text-text">{localRates.length}</p>
          </div>
        </div>
        <div className="bg-surface border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-success/10 flex items-center justify-center">
            <CheckCircle className="w-5 h-5 text-success" />
          </div>
          <div>
            <p className="text-xs text-text-muted font-medium">Active</p>
            <p className="text-xl font-bold text-text">{activeCount}</p>
          </div>
        </div>
        <div className="bg-surface border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-danger/10 flex items-center justify-center">
            <XCircle className="w-5 h-5 text-danger" />
          </div>
          <div>
            <p className="text-xs text-text-muted font-medium">Disabled</p>
            <p className="text-xl font-bold text-text">{inactiveCount}</p>
          </div>
        </div>
        <div className="bg-surface border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center">
            <AlertTriangle className="w-5 h-5 text-amber-500" />
          </div>
          <div>
            <p className="text-xs text-text-muted font-medium">Unsaved</p>
            <p className="text-xl font-bold text-text">{hasChanges ? 'Yes' : 'No'}</p>
          </div>
        </div>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
        <input
          type="text"
          placeholder="Search by wilaya name, Arabic name, or code..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full pl-10 pr-4 py-2.5 bg-surface border border-border rounded-xl text-sm focus:outline-none focus:border-primary text-text"
        />
      </div>

      {/* Table */}
      <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
        {loading ? (
          <div className="flex justify-center items-center p-16">
            <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-primary border-r-2 border-transparent" />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider border-b border-border">
                  <th className="p-4 font-semibold w-16">Code</th>
                  <th className="p-4 font-semibold">Wilaya</th>
                  <th className="p-4 font-semibold text-center w-28">Active</th>
                  <th className="p-4 font-semibold">
                    <div className="flex items-center gap-1.5">
                      <Home className="w-3.5 h-3.5" />
                      Home Price (DZD)
                    </div>
                  </th>
                  <th className="p-4 font-semibold w-28 text-center">Home Active</th>
                  <th className="p-4 font-semibold">
                    <div className="flex items-center gap-1.5">
                      <Store className="w-3.5 h-3.5" />
                      Desk Price (DZD)
                    </div>
                  </th>
                  <th className="p-4 font-semibold w-28 text-center">Desk Active</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filtered.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="p-8 text-center text-text-muted">
                      No wilayas found matching "{search}"
                    </td>
                  </tr>
                ) : (
                  filtered.map((rate) => {
                    const isDisabled = !rate.is_active;
                    return (
                      <tr
                        key={rate.id}
                        className={`transition-colors group ${
                          isDisabled
                            ? 'bg-danger/3 hover:bg-danger/5'
                            : 'hover:bg-background/40'
                        }`}
                      >
                        {/* Code */}
                        <td className="p-4">
                          <span className="inline-flex items-center px-2.5 py-1 rounded-lg bg-primary/10 text-primary font-bold text-xs">
                            {rate.wilaya_code}
                          </span>
                        </td>

                        {/* Name */}
                        <td className="p-4">
                          <div>
                            <p className={`font-semibold text-sm ${isDisabled ? 'text-text-muted line-through' : 'text-text'}`}>
                              {rate.wilaya_name}
                            </p>
                            <p className="text-xs text-text-muted mt-0.5" dir="rtl">
                              {rate.wilaya_name_ar}
                            </p>
                          </div>
                        </td>

                        {/* Wilaya Active Toggle */}
                        <td className="p-4 text-center">
                          <button
                            onClick={() => updateLocal(rate.id, { is_active: !rate.is_active })}
                            title={rate.is_active ? 'Disable this wilaya' : 'Enable this wilaya'}
                            className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-semibold transition-all duration-200 ${
                              rate.is_active
                                ? 'bg-success/10 text-success hover:bg-success/20'
                                : 'bg-danger/10 text-danger hover:bg-danger/20'
                            }`}
                          >
                            {rate.is_active ? (
                              <>
                                <ToggleRight className="w-4 h-4" /> Active
                              </>
                            ) : (
                              <>
                                <ToggleLeft className="w-4 h-4" /> Off
                              </>
                            )}
                          </button>
                        </td>

                        {/* Home Price */}
                        <td className="p-4">
                          <div className="relative max-w-[140px]">
                            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-xs font-medium">DZD</span>
                            <input
                              type="number"
                              min="0"
                              step="50"
                              value={rate.home_price}
                              disabled={isDisabled || !rate.home_active}
                              onChange={(e) =>
                                updateLocal(rate.id, { home_price: parseFloat(e.target.value) || 0 })
                              }
                              className="w-full pl-11 pr-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary disabled:opacity-40 disabled:cursor-not-allowed text-text"
                            />
                          </div>
                        </td>

                        {/* Home Active */}
                        <td className="p-4 text-center">
                          <button
                            disabled={isDisabled}
                            onClick={() => updateLocal(rate.id, { home_active: !rate.home_active })}
                            title={rate.home_active ? 'Disable home delivery' : 'Enable home delivery'}
                            className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-semibold transition-all duration-200 disabled:opacity-30 disabled:cursor-not-allowed ${
                              rate.home_active
                                ? 'bg-blue-500/10 text-blue-500 hover:bg-blue-500/20'
                                : 'bg-border/50 text-text-muted hover:bg-border'
                            }`}
                          >
                            {rate.home_active ? (
                              <><ToggleRight className="w-4 h-4" /> On</>
                            ) : (
                              <><ToggleLeft className="w-4 h-4" /> Off</>
                            )}
                          </button>
                        </td>

                        {/* Desk Price */}
                        <td className="p-4">
                          <div className="relative max-w-[140px]">
                            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-xs font-medium">DZD</span>
                            <input
                              type="number"
                              min="0"
                              step="50"
                              value={rate.desk_price}
                              disabled={isDisabled || !rate.desk_active}
                              onChange={(e) =>
                                updateLocal(rate.id, { desk_price: parseFloat(e.target.value) || 0 })
                              }
                              className="w-full pl-11 pr-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary disabled:opacity-40 disabled:cursor-not-allowed text-text"
                            />
                          </div>
                        </td>

                        {/* Desk Active */}
                        <td className="p-4 text-center">
                          <button
                            disabled={isDisabled}
                            onClick={() => updateLocal(rate.id, { desk_active: !rate.desk_active })}
                            title={rate.desk_active ? 'Disable desk delivery' : 'Enable desk delivery'}
                            className={`inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-semibold transition-all duration-200 disabled:opacity-30 disabled:cursor-not-allowed ${
                              rate.desk_active
                                ? 'bg-purple-500/10 text-purple-500 hover:bg-purple-500/20'
                                : 'bg-border/50 text-text-muted hover:bg-border'
                            }`}
                          >
                            {rate.desk_active ? (
                              <><ToggleRight className="w-4 h-4" /> On</>
                            ) : (
                              <><ToggleLeft className="w-4 h-4" /> Off</>
                            )}
                          </button>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        )}

        {/* Footer summary */}
        {!loading && filtered.length > 0 && (
          <div className="p-4 border-t border-border bg-background/20 flex items-center justify-between text-xs text-text-muted">
            <span>Showing {filtered.length} of {localRates.length} wilayas</span>
            {hasChanges && (
              <span className="flex items-center gap-1.5 text-amber-500 font-medium">
                <AlertTriangle className="w-3.5 h-3.5" />
                You have unsaved changes
              </span>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
