import React, { useState } from 'react';
import { Search, Download } from 'lucide-react';
import { Modal } from '../components/ui/Modal';

const mockOrders = [
  { id: '#ORD-7391', date: '2026-05-17', customer: 'John Doe', total: '$149.00', status: 'Pending', marketer: 'Ahmed User' },
  { id: '#ORD-7390', date: '2026-05-16', customer: 'Alice Smith', total: '$299.00', status: 'Confirmed', marketer: 'Sara Smith' },
  { id: '#ORD-7389', date: '2026-05-16', customer: 'Bob Jones', total: '$89.00', status: 'Shipped', marketer: 'Ahmed User' },
  { id: '#ORD-7388', date: '2026-05-15', customer: 'Charlie Brown', total: '$45.00', status: 'Delivered', marketer: 'Fatima Zohra' },
  { id: '#ORD-7387', date: '2026-05-15', customer: 'Diana Prince', total: '$199.00', status: 'Failed', marketer: 'Omar Ali' },
];

const StatusSelect = ({ status }: { status: string }) => {
  const [currentStatus, setCurrentStatus] = useState(status);
  
  const styles: any = {
    'Pending': 'bg-yellow-500/10 text-yellow-600 border-yellow-500/20',
    'Confirmed': 'bg-blue-500/10 text-blue-500 border-blue-500/20',
    'Shipped': 'bg-purple-500/10 text-purple-500 border-purple-500/20',
    'Delivered': 'bg-success/10 text-success border-success/20',
    'Failed': 'bg-danger/10 text-danger border-danger/20',
  };
  
  return (
    <select 
      value={currentStatus}
      onChange={(e) => setCurrentStatus(e.target.value)}
      onClick={(e) => e.stopPropagation()}
      className={`appearance-none outline-none pl-3 pr-8 py-1 rounded-full text-xs font-bold border transition-colors cursor-pointer ${styles[currentStatus]}`}
      style={{ backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`, backgroundPosition: 'right 0.25rem center', backgroundRepeat: 'no-repeat', backgroundSize: '1.25em 1.25em' }}
    >
      <option value="Pending">Pending</option>
      <option value="Confirmed">Confirmed</option>
      <option value="Shipped">Shipped</option>
      <option value="Delivered">Delivered</option>
      <option value="Failed">Failed</option>
    </select>
  );
};

export const OrdersManagement: React.FC = () => {
  const [actionModal, setActionModal] = useState<'view' | 'assign' | null>(null);
  const [selectedOrder, setSelectedOrder] = useState<any>(null);
  const [limit, setLimit] = useState(20);

  const ordersList = Array.from({ length: 25 }, (_, i) => ({
    ...mockOrders[i % mockOrders.length],
    id: `#ORD-${7391 - i}`,
    customer: `${mockOrders[i % mockOrders.length].customer} ${i + 1}`
  }));

  const visibleOrders = ordersList.slice(0, limit);

  const openModal = (type: any, order: any) => {
    setSelectedOrder(order);
    setActionModal(type);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Orders Management</h1>
          <p className="text-sm text-text-muted mt-1">Track orders, update statuses, and assign confirmatrices.</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 border border-border rounded-lg text-sm font-medium text-text-muted hover:bg-background transition-colors">
          <Download className="w-4 h-4" />
          Export CSV
        </button>
      </div>

      <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
        <div className="p-4 border-b border-border flex flex-wrap items-center gap-4 bg-background/50">
          <div className="relative flex-1 min-w-[250px]">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
            <input 
              type="text" 
              placeholder="Search by Order ID, Customer, or Marketer..." 
              className="w-full pl-10 pr-4 py-2 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary transition-colors"
            />
          </div>
          <div className="flex gap-2">
            <select className="bg-surface border border-border rounded-lg px-3 py-2 text-sm outline-none focus:border-primary">
              <option>All Statuses</option>
              <option>Pending</option>
              <option>Confirmed</option>
              <option>Shipped</option>
              <option>Delivered</option>
              <option>Failed</option>
            </select>
          </div>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider">
                <th className="p-4 font-medium">Order ID</th>
                <th className="p-4 font-medium">Date</th>
                <th className="p-4 font-medium">Customer</th>
                <th className="p-4 font-medium">Marketer</th>
                <th className="p-4 font-medium">Total</th>
                <th className="p-4 font-medium">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {visibleOrders.map((order) => (
                <tr 
                  key={order.id} 
                  onClick={() => openModal('view', order)}
                  className="hover:bg-background/50 transition-colors group cursor-pointer"
                >
                  <td className="p-4 text-sm font-bold text-text">{order.id}</td>
                  <td className="p-4 text-sm text-text-muted">{order.date}</td>
                  <td className="p-4 text-sm font-medium text-text">{order.customer}</td>
                  <td className="p-4 text-sm text-text-muted">{order.marketer}</td>
                  <td className="p-4 text-sm font-bold text-text">{order.total}</td>
                  <td className="p-4"><StatusSelect status={order.status} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {limit < ordersList.length && (
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

      <Modal isOpen={actionModal === 'view'} onClose={() => setActionModal(null)} title={`Order Details - ${selectedOrder?.id}`}>
        <div className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-text-muted mb-1">Customer</p>
              <p className="text-sm font-semibold text-text">{selectedOrder?.customer}</p>
            </div>
            <div>
              <p className="text-xs text-text-muted mb-1">Date</p>
              <p className="text-sm font-semibold text-text">{selectedOrder?.date}</p>
            </div>
            <div>
              <p className="text-xs text-text-muted mb-1">Marketer</p>
              <p className="text-sm font-semibold text-text">{selectedOrder?.marketer}</p>
            </div>
            <div>
              <p className="text-xs text-text-muted mb-1">Total Amount</p>
              <p className="text-sm font-bold text-primary">{selectedOrder?.total}</p>
            </div>
          </div>
          <div>
            <h3 className="text-sm font-bold text-text mb-3">Order Items</h3>
            <div className="space-y-2">
               <div className="flex justify-between text-sm p-3 bg-background border border-border rounded-lg">
                 <span>1x Wireless Headphones</span>
                 <span className="font-medium text-text">$99.00</span>
               </div>
               <div className="flex justify-between text-sm p-3 bg-background border border-border rounded-lg">
                 <span>1x Delivery Fee</span>
                 <span className="font-medium text-text">$50.00</span>
               </div>
            </div>
          </div>
          <div className="pt-4 border-t border-border flex justify-between items-center">
            <div>
              <p className="text-xs text-text-muted">Confirmatrice Agent</p>
              <p className="text-sm font-semibold text-text">Not Assigned</p>
            </div>
            <button 
              onClick={() => openModal('assign', selectedOrder)}
              className="px-3 py-1.5 bg-primary/10 text-primary hover:bg-primary/20 rounded-lg text-xs font-semibold transition-colors"
            >
              Assign Agent
            </button>
          </div>
        </div>
      </Modal>

      <Modal isOpen={actionModal === 'assign'} onClose={() => setActionModal(null)} title={`Assign Confirmatrice for ${selectedOrder?.id}`}>
        <form className="space-y-4">
          <p className="text-sm text-text-muted">Select an agent to handle the confirmation process for this order.</p>
          <div>
            <label className="block text-sm font-medium text-text mb-1">Select Agent</label>
            <select className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
              <option>Agent Amira</option>
              <option>Agent Youssef</option>
              <option>Agent Khadija</option>
            </select>
          </div>
          <div className="flex justify-end gap-3 pt-4 mt-6 border-t border-border">
            <button type="button" onClick={() => openModal('view', selectedOrder)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm font-medium hover:bg-background transition-colors">
              Cancel
            </button>
            <button type="button" onClick={() => openModal('view', selectedOrder)} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors">
              Assign Agent
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
