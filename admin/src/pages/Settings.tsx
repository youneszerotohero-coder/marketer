import React, { useState, useEffect } from 'react';
import { Save, Plus, Edit, Trash2, Key, Users, Truck } from 'lucide-react';
import { Modal } from '../components/ui/Modal';
import api from '../services/api';

export const Settings: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'delivery' | 'accounts'>('delivery');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedAccount, setSelectedAccount] = useState<any>(null);
  const [limit, setLimit] = useState(20);

  const [accountsList, setAccountsList] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [zrEnabled, setZrEnabled] = useState(true);
  const [zrCredentials, setZrCredentials] = useState({ tenantId: '', secretKey: '', baseUrl: '', version: '1' });
  const [returnFee, setReturnFee] = useState('400');

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'accounts') {
        const response = await api.get('/admin/users');
        setAccountsList(response.data.data || response.data);
      } else {
        const response = await api.get('/admin/settings');
        const data = response.data.data || response.data || {};
        setZrEnabled((data.delivery_provider || data['delivery.provider'] || 'zr_express') === 'zr_express');
        setZrCredentials({
          tenantId: data.zr_express_tenant_id || '',
          secretKey: data.zr_express_secret_key || '',
          baseUrl: data.zr_express_base_url || 'https://app.zrexpress.fr/api',
          version: data.zr_express_api_version || '1',
        });
        setReturnFee(data.return_fee || '400');
      }
    } catch (error) {
      console.error('Failed to fetch data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveSettings = async () => {
    try {
      await api.patch('/admin/settings', {
        settings: [
          { key: 'delivery.provider', value: zrEnabled ? 'zr_express' : 'mock' },
          { key: 'zr_express_tenant_id', value: zrCredentials.tenantId },
          { key: 'zr_express_secret_key', value: zrCredentials.secretKey },
          { key: 'zr_express_base_url', value: zrCredentials.baseUrl },
          { key: 'zr_express_api_version', value: zrCredentials.version },
          { key: 'return_fee', value: returnFee }
        ]
      });
      alert("Settings saved!");
    } catch (error) {
      console.error('Failed to save settings', error);
      alert("Failed to save settings");
    }
  };

  const visibleAccounts = accountsList.slice(0, limit);

  const openModal = (account?: any) => {
    setSelectedAccount(account || null);
    setIsModalOpen(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Platform Settings</h1>
          <p className="text-sm text-text-muted mt-1">Configure delivery integrations and manage admin accounts.</p>
        </div>
        {activeTab === 'accounts' && (
          <button 
            onClick={() => openModal()}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors shadow-md shadow-primary/20"
          >
            <Plus className="w-4 h-4" />
            Add Account
          </button>
        )}
      </div>

      <div className="flex border-b border-border">
        <button 
          onClick={() => setActiveTab('delivery')}
          className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === 'delivery' ? 'border-primary text-primary' : 'border-transparent text-text-muted hover:text-text'}`}
        >
          <Truck className="w-4 h-4" />
          Delivery APIs
        </button>
        <button 
          onClick={() => setActiveTab('accounts')}
          className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === 'accounts' ? 'border-primary text-primary' : 'border-transparent text-text-muted hover:text-text'}`}
        >
          <Users className="w-4 h-4" />
          Accounts Management
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center p-8">
          <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary border-r-2 border-transparent"></div>
        </div>
      ) : activeTab === 'delivery' ? (
        <div className="space-y-6">
          <div className="bg-surface border border-border rounded-2xl shadow-sm p-6">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-blue-500/10 text-blue-500 rounded-xl">
                  <Truck className="w-6 h-6" />
                </div>
                <div>
                  <h2 className="text-lg font-bold text-text">ZR Express</h2>
                  <p className="text-sm text-text-muted">Configure ZR Express API credentials for automated shipping, tracking, wilayas, and rates.</p>
                </div>
              </div>
              <label className="relative inline-flex items-center cursor-pointer">
                <input type="checkbox" className="sr-only peer" checked={zrEnabled} onChange={() => setZrEnabled(!zrEnabled)} />
                <div className="w-11 h-6 bg-border peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-success"></div>
              </label>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-text mb-1">Tenant ID</label>
                <div className="relative">
                  <Key className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
                  <input type="text" value={zrCredentials.tenantId} onChange={(e) => setZrCredentials({...zrCredentials, tenantId: e.target.value})} placeholder="e10b8c86-54ab-4d46-ace7-62b4590e733b" className="w-full pl-10 pr-4 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Secret Key</label>
                <div className="relative">
                  <Key className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
                  <input type="password" value={zrCredentials.secretKey} onChange={(e) => setZrCredentials({...zrCredentials, secretKey: e.target.value})} placeholder="************************" className="w-full pl-10 pr-4 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Base URL</label>
                <div className="relative">
                  <Key className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
                  <input type="text" value={zrCredentials.baseUrl} onChange={(e) => setZrCredentials({...zrCredentials, baseUrl: e.target.value})} placeholder="https://app.zrexpress.fr/api" className="w-full pl-10 pr-4 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-text mb-1">API Version</label>
                <div className="relative">
                  <Key className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
                  <input type="text" value={zrCredentials.version} onChange={(e) => setZrCredentials({...zrCredentials, version: e.target.value})} placeholder="1" className="w-full pl-10 pr-4 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" />
                </div>
              </div>
            </div>
            <div className="mt-4 flex justify-end">
              <button onClick={handleSaveSettings} className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors">
                <Save className="w-4 h-4" />
                Save Changes
              </button>
            </div>
          </div>

          <div className="bg-surface border border-border rounded-2xl shadow-sm p-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="p-3 bg-red-500/10 text-red-500 rounded-xl">
                <Truck className="w-6 h-6" />
              </div>
              <div>
                <h2 className="text-lg font-bold text-text">Return Settings</h2>
                <p className="text-sm text-text-muted">Configure the default penalty fee applied to marketer wallets for returned orders.</p>
              </div>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-text mb-1">Return Tariff (DZD)</label>
                <div className="relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-sm font-medium">DZD</span>
                  <input type="number" value={returnFee} onChange={(e) => setReturnFee(e.target.value)} placeholder="400" className="w-full pl-12 pr-4 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" />
                </div>
              </div>
            </div>
            <div className="mt-4 flex justify-end">
              <button onClick={handleSaveSettings} className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors">
                <Save className="w-4 h-4" />
                Save Changes
              </button>
            </div>
          </div>
        </div>
      ) : (
        <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider">
                  <th className="p-4 font-medium">User</th>
                  <th className="p-4 font-medium">Role</th>
                  <th className="p-4 font-medium">Status</th>
                  <th className="p-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {visibleAccounts.map((account) => (
                  <tr key={account.id} className="hover:bg-background/50 transition-colors group">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold">
                          {account.name.charAt(0)}
                        </div>
                        <div>
                          <p className="text-sm font-semibold text-text">{account.name}</p>
                          <p className="text-xs text-text-muted">{account.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        account.role === 'admin' ? 'bg-purple-500/10 text-purple-500' : 'bg-blue-500/10 text-blue-500'
                      }`}>
                        {account.role}
                      </span>
                    </td>
                    <td className="p-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        account.status === 'Active' || account.status === 'active' ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'
                      }`}>
                        {account.status || 'Active'}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button onClick={() => openModal(account)} className="p-1.5 text-text-muted hover:text-blue-500 hover:bg-blue-500/10 rounded-md transition-colors" title="Edit">
                          <Edit className="w-4 h-4" />
                        </button>
                        <button className="p-1.5 text-text-muted hover:text-danger hover:bg-danger/10 rounded-md transition-colors" title="Delete">
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {visibleAccounts.length === 0 && (
                  <tr>
                    <td colSpan={4} className="p-4 text-center text-text-muted">No accounts found.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {limit < accountsList.length && (
            <div className="p-4 border-t border-border flex justify-center bg-background/20">
              <button 
                onClick={() => setLimit(prev => prev + 20)}
                className="px-5 py-2 border border-border bg-surface text-text hover:bg-background text-sm font-semibold rounded-xl transition-all duration-200 cursor-pointer shadow-sm hover:scale-102"
              >
                Load More
              </button>
            </div>
          )}
        </div>
      )}

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title={selectedAccount ? "Edit Account" : "Add New Account"}>
        <form className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-text mb-1">Full Name</label>
            <input type="text" defaultValue={selectedAccount?.name} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="John Doe" />
          </div>
          <div>
            <label className="block text-sm font-medium text-text mb-1">Email Address</label>
            <input type="email" defaultValue={selectedAccount?.email} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="john@example.com" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-text mb-1">{selectedAccount ? "New Password (Optional)" : "Password"}</label>
              <input type="password" placeholder="••••••••" className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" />
            </div>
            <div>
              <label className="block text-sm font-medium text-text mb-1">Confirm Password</label>
              <input type="password" placeholder="••••••••" className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-text mb-1">Role</label>
              <select defaultValue={selectedAccount?.role || 'confirmatrice'} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
                <option value="admin">Admin</option>
                <option value="confirmatrice">Confirmatrice</option>
                <option value="marketer">Marketer</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-text mb-1">Status</label>
              <select defaultValue={selectedAccount?.status || 'Active'} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
                <option value="Active">Active</option>
                <option value="Inactive">Inactive</option>
              </select>
            </div>
          </div>
          <div className="flex justify-end gap-3 pt-4 mt-6 border-t border-border">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm font-medium hover:bg-background transition-colors">
              Cancel
            </button>
            <button type="button" onClick={() => {
              // Add API call here later
              setIsModalOpen(false);
              fetchData();
            }} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors">
              {selectedAccount ? "Save Changes" : "Create Account"}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
