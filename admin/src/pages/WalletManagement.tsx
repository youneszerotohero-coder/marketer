import React, { useState } from 'react';
import { CreditCard, History, Edit3 } from 'lucide-react';
import { Modal } from '../components/ui/Modal';

const mockRequests = [
  { id: 'WR-001', marketer: 'Ahmed User', amount: '$450.00', method: 'BaridiMob', date: '2026-05-17', status: 'Pending' },
  { id: 'WR-002', marketer: 'Sara Smith', amount: '$120.00', method: 'Bank Transfer', date: '2026-05-16', status: 'Pending' },
  { id: 'WR-003', marketer: 'Fatima Zohra', amount: '$850.00', method: 'BaridiMob', date: '2026-05-15', status: 'Approved' },
];

const WalletStatusSelect = ({ status }: { status: string }) => {
  const [currentStatus, setCurrentStatus] = useState(status);
  
  const styles: any = {
    'Pending': 'bg-yellow-500/10 text-yellow-600 border-yellow-500/20',
    'Approved': 'bg-success/10 text-success border-success/20',
    'Rejected': 'bg-danger/10 text-danger border-danger/20',
  };
  
  return (
    <select 
      value={currentStatus}
      onChange={(e) => setCurrentStatus(e.target.value)}
      className={`appearance-none outline-none pl-3 pr-8 py-1 rounded-full text-xs font-bold border transition-colors cursor-pointer ${styles[currentStatus]}`}
      style={{ backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`, backgroundPosition: 'right 0.25rem center', backgroundRepeat: 'no-repeat', backgroundSize: '1.25em 1.25em' }}
    >
      <option value="Pending">Pending</option>
      <option value="Approved">Approved</option>
      <option value="Rejected">Rejected</option>
    </select>
  );
};

export const WalletManagement: React.FC = () => {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [limit, setLimit] = useState(20);

  const requestsList = Array.from({ length: 25 }, (_, i) => ({
    ...mockRequests[i % mockRequests.length],
    id: `WR-${String(i + 1).padStart(3, '0')}`,
    marketer: `${mockRequests[i % mockRequests.length].marketer} ${i + 1}`
  }));

  const visibleRequests = requestsList.slice(0, limit);

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Wallet Management</h1>
          <p className="text-sm text-text-muted mt-1">Manage withdrawal requests and manual adjustments.</p>
        </div>
        <button 
          onClick={() => setIsModalOpen(true)}
          className="flex items-center gap-2 px-4 py-2 border border-primary text-primary rounded-lg text-sm font-medium hover:bg-primary/5 transition-colors"
        >
          <Edit3 className="w-4 h-4" />
          Manual Adjustment
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-surface rounded-2xl p-6 border border-border shadow-sm flex flex-col gap-2">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-yellow-500/10 text-yellow-600 rounded-xl">
              <History className="w-6 h-6" />
            </div>
            <div>
              <p className="text-sm font-medium text-text-muted">Pending Requests</p>
              <h3 className="text-2xl font-bold text-text">2 requests</h3>
            </div>
          </div>
        </div>
        <div className="bg-surface rounded-2xl p-6 border border-border shadow-sm flex flex-col gap-2">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-primary/10 text-primary rounded-xl">
              <CreditCard className="w-6 h-6" />
            </div>
            <div>
              <p className="text-sm font-medium text-text-muted">Total Paid Out (This Month)</p>
              <h3 className="text-2xl font-bold text-text">$12,450.00</h3>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
        <div className="p-4 border-b border-border bg-background/50">
          <h2 className="text-lg font-bold text-text">Withdrawal Requests</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="text-text-muted text-xs uppercase tracking-wider">
                <th className="p-4 font-medium">Request ID</th>
                <th className="p-4 font-medium">Marketer</th>
                <th className="p-4 font-medium">Amount</th>
                <th className="p-4 font-medium">Method</th>
                <th className="p-4 font-medium">Date</th>
                <th className="p-4 font-medium">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {visibleRequests.map((req, index) => (
                <tr key={index} className="hover:bg-background/50 transition-colors group">
                  <td className="p-4 text-sm font-mono text-text-muted">{req.id}</td>
                  <td className="p-4 text-sm font-semibold text-text">{req.marketer}</td>
                  <td className="p-4 text-sm font-bold text-primary">{req.amount}</td>
                  <td className="p-4 text-sm text-text-muted">{req.method}</td>
                  <td className="p-4 text-sm text-text-muted">{req.date}</td>
                  <td className="p-4">
                    <WalletStatusSelect status={req.status} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {limit < requestsList.length && (
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

      <Modal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title="Manual Wallet Adjustment">
        <form className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-text mb-1">Select Marketer</label>
            <select className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
              <option>Ahmed User</option>
              <option>Sara Smith</option>
              <option>Fatima Zohra</option>
            </select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-text mb-1">Adjustment Type</label>
              <select className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
                <option>Credit (+)</option>
                <option>Debit (-)</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-text mb-1">Amount</label>
              <input type="text" className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="$0.00" />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-text mb-1">Reason for Adjustment</label>
            <textarea 
              className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary resize-none" 
              rows={3}
              placeholder="e.g. Compensation for lost package"
            ></textarea>
          </div>
          <div className="flex justify-end gap-3 pt-4 mt-6 border-t border-border">
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm font-medium hover:bg-background transition-colors">
              Cancel
            </button>
            <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors">
              Confirm Adjustment
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
