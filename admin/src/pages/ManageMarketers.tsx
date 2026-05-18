import React, { useState } from 'react';
import { Search, Plus, Edit, Ban, DollarSign, Activity } from 'lucide-react';
import { Modal } from '../components/ui/Modal';

const mockMarketers = [
  { id: '1', name: 'Ahmed User', email: 'ahmed@example.com', status: 'Active', sales: 145, commission: '$1,250' },
  { id: '2', name: 'Sara Smith', email: 'sara@example.com', status: 'Active', sales: 89, commission: '$890' },
  { id: '3', name: 'Omar Ali', email: 'omar@example.com', status: 'Suspended', sales: 12, commission: '$120' },
  { id: '4', name: 'Fatima Zohra', email: 'fatima@example.com', status: 'Active', sales: 234, commission: '$3,100' },
  { id: '5', name: 'Youssef B.', email: 'youssef@example.com', status: 'Active', sales: 56, commission: '$450' },
];

export const ManageMarketers: React.FC = () => {
  const [actionModal, setActionModal] = useState<'add' | 'performance' | 'commissions' | 'edit' | 'suspend' | null>(null);
  const [selectedMarketer, setSelectedMarketer] = useState<any>(null);
  const [limit, setLimit] = useState(20);

  const marketersList = Array.from({ length: 25 }, (_, i) => ({
    ...mockMarketers[i % mockMarketers.length],
    id: String(i + 1),
    name: `${mockMarketers[i % mockMarketers.length].name} ${i + 1}`,
    email: `${mockMarketers[i % mockMarketers.length].email.split('@')[0]}_${i + 1}@example.com`
  }));

  const visibleMarketers = marketersList.slice(0, limit);

  const openModal = (type: any, marketer?: any) => {
    setSelectedMarketer(marketer || null);
    setActionModal(type);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Manage Marketers</h1>
          <p className="text-sm text-text-muted mt-1">View, edit, and suspend marketers on the platform.</p>
        </div>
        <button 
          onClick={() => openModal('add')}
          className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors shadow-md shadow-primary/20"
        >
          <Plus className="w-4 h-4" />
          Add Marketer
        </button>
      </div>

      <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
        <div className="p-4 border-b border-border flex items-center justify-between bg-background/50">
          <div className="relative w-full max-w-md">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
            <input 
              type="text" 
              placeholder="Search marketers by name or email..." 
              className="w-full pl-10 pr-4 py-2 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary transition-colors"
            />
          </div>
          <div className="flex items-center gap-2">
            <select className="bg-surface border border-border rounded-lg px-3 py-2 text-sm outline-none focus:border-primary">
              <option>All Status</option>
              <option>Active</option>
              <option>Suspended</option>
            </select>
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider">
                <th className="p-4 font-medium">Marketer</th>
                <th className="p-4 font-medium">Status</th>
                <th className="p-4 font-medium">Total Sales</th>
                <th className="p-4 font-medium">Commission</th>
                <th className="p-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {visibleMarketers.map((marketer) => (
                <tr key={marketer.id} className="hover:bg-background/50 transition-colors group">
                  <td className="p-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold">
                        {marketer.name.charAt(0)}
                      </div>
                      <div>
                        <p className="text-sm font-semibold text-text">{marketer.name}</p>
                        <p className="text-xs text-text-muted">{marketer.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="p-4">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      marketer.status === 'Active' 
                        ? 'bg-success/10 text-success' 
                        : 'bg-danger/10 text-danger'
                    }`}>
                      {marketer.status}
                    </span>
                  </td>
                  <td className="p-4 text-sm text-text font-medium">{marketer.sales}</td>
                  <td className="p-4 text-sm text-success font-bold">{marketer.commission}</td>
                  <td className="p-4 text-right">
                    <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button onClick={() => openModal('performance', marketer)} className="p-1.5 text-text-muted hover:text-primary hover:bg-primary/10 rounded-md transition-colors" title="Performance">
                        <Activity className="w-4 h-4" />
                      </button>
                      <button onClick={() => openModal('commissions', marketer)} className="p-1.5 text-text-muted hover:text-primary hover:bg-primary/10 rounded-md transition-colors" title="Commissions">
                        <DollarSign className="w-4 h-4" />
                      </button>
                      <button onClick={() => openModal('edit', marketer)} className="p-1.5 text-text-muted hover:text-blue-500 hover:bg-blue-500/10 rounded-md transition-colors" title="Edit">
                        <Edit className="w-4 h-4" />
                      </button>
                      <button onClick={() => openModal('suspend', marketer)} className="p-1.5 text-text-muted hover:text-danger hover:bg-danger/10 rounded-md transition-colors" title="Suspend">
                        <Ban className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {limit < marketersList.length && (
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

      <Modal isOpen={actionModal === 'add' || actionModal === 'edit'} onClose={() => setActionModal(null)} title={actionModal === 'edit' ? "Edit Marketer" : "Add New Marketer"}>
        <form className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-text mb-1">Full Name</label>
            <input type="text" defaultValue={selectedMarketer?.name} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="John Doe" />
          </div>
          <div>
            <label className="block text-sm font-medium text-text mb-1">Email Address</label>
            <input type="email" defaultValue={selectedMarketer?.email} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="john@example.com" />
          </div>
          <div>
            <label className="block text-sm font-medium text-text mb-1">Status</label>
            <select defaultValue={selectedMarketer?.status || 'Active'} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
              <option>Active</option>
              <option>Suspended</option>
            </select>
          </div>
          <div className="flex justify-end gap-3 pt-4 mt-6 border-t border-border">
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm font-medium hover:bg-background transition-colors">
              Cancel
            </button>
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors">
              {actionModal === 'edit' ? 'Save Changes' : 'Save Marketer'}
            </button>
          </div>
        </form>
      </Modal>

      <Modal isOpen={actionModal === 'suspend'} onClose={() => setActionModal(null)} title="Suspend Marketer">
        <div className="space-y-4">
          <p className="text-sm text-text">Are you sure you want to suspend <strong>{selectedMarketer?.name}</strong>? They will lose access to their dashboard.</p>
          <div className="flex justify-end gap-3 pt-4 mt-6 border-t border-border">
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm font-medium hover:bg-background transition-colors">
              Cancel
            </button>
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 bg-danger text-white rounded-lg text-sm font-medium hover:bg-danger/90 transition-colors">
              Suspend Account
            </button>
          </div>
        </div>
      </Modal>

      <Modal isOpen={actionModal === 'performance'} onClose={() => setActionModal(null)} title={`${selectedMarketer?.name} - Performance`}>
        <div className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
             <div className="p-4 bg-background border border-border rounded-xl">
               <p className="text-xs text-text-muted mb-1">Total Clicks</p>
               <p className="text-xl font-bold text-text">12,450</p>
             </div>
             <div className="p-4 bg-background border border-border rounded-xl">
               <p className="text-xs text-text-muted mb-1">Conversion Rate</p>
               <p className="text-xl font-bold text-success">3.2%</p>
             </div>
          </div>
          <div>
            <h3 className="text-sm font-bold text-text mb-3">Top Products</h3>
            <div className="space-y-2">
               <div className="flex justify-between text-sm p-2 bg-background rounded-lg">
                 <span>Wireless Headphones</span>
                 <span className="font-medium text-text">45 Sales</span>
               </div>
               <div className="flex justify-between text-sm p-2 bg-background rounded-lg">
                 <span>Smart Watch Series 5</span>
                 <span className="font-medium text-text">22 Sales</span>
               </div>
            </div>
          </div>
        </div>
      </Modal>

      <Modal isOpen={actionModal === 'commissions'} onClose={() => setActionModal(null)} title={`${selectedMarketer?.name} - Commissions`}>
        <div className="space-y-4">
          <div className="p-4 bg-primary/10 border border-primary/20 rounded-xl flex justify-between items-center">
            <div>
              <p className="text-xs text-primary font-medium mb-1">Unpaid Balance</p>
              <p className="text-2xl font-bold text-primary">{selectedMarketer?.commission}</p>
            </div>
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors shadow-sm">
              Pay Now
            </button>
          </div>
          <div>
            <h3 className="text-sm font-bold text-text mb-3">Recent Earnings</h3>
            <div className="space-y-2">
               <div className="flex justify-between text-sm p-3 border border-border rounded-lg">
                 <div>
                   <p className="font-medium text-text">Order #ORD-7391</p>
                   <p className="text-xs text-text-muted">Today at 14:30</p>
                 </div>
                 <span className="font-bold text-success">+$15.00</span>
               </div>
               <div className="flex justify-between text-sm p-3 border border-border rounded-lg">
                 <div>
                   <p className="font-medium text-text">Order #ORD-7389</p>
                   <p className="text-xs text-text-muted">Yesterday</p>
                 </div>
                 <span className="font-bold text-success">+$8.90</span>
               </div>
            </div>
          </div>
        </div>
      </Modal>
    </div>
  );
};
