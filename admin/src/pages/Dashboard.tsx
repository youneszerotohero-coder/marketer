import React, { useRef, useState, useEffect } from 'react';
import {
  TrendingUp,
  Users,
  Package,
  XCircle,
  CreditCard,
  MoreHorizontal,
  ChevronLeft,
  ChevronRight,
  DollarSign,
  Calendar,
  Download,
  Loader2,
  Clock,
  CheckCircle,
  Truck,
  ShoppingBag,
} from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { dashboardApi } from '../services/api';

const getDates = (period: string, custom: { start: string, end: string }) => {
  const end = new Date();
  let start = new Date();
  
  if (period === 'Today') {
    // start is today
  } else if (period === 'Yesterday') {
    start.setDate(start.getDate() - 1);
    end.setDate(end.getDate() - 1);
  } else if (period === 'Last 7 Days') {
    start.setDate(start.getDate() - 7);
  } else if (period === 'Last 30 Days') {
    start.setDate(start.getDate() - 30);
  } else if (period === 'This Month') {
    start.setDate(1);
  } else if (period === 'Custom') {
    return {
      start_date: custom.start || undefined,
      end_date: custom.end || undefined
    };
  }

  return {
    start_date: start.toISOString().split('T')[0],
    end_date: end.toISOString().split('T')[0]
  };
};

const StatCard = ({ title, value, icon: Icon, trend, colorClass }: any) => (
  <div className="bg-surface rounded-2xl p-6 border border-border shadow-sm flex flex-col gap-4 hover:-translate-y-1 transition-transform duration-300 h-full">
    <div className="flex justify-between items-start">
      <div className={`p-3 rounded-xl ${colorClass}`}>
        <Icon className="w-6 h-6" />
      </div>
      {trend !== undefined && (
        <span className={`text-sm font-medium ${trend > 0 ? 'text-success' : trend < 0 ? 'text-danger' : 'text-text-muted'}`}>
          {trend > 0 ? '+' : ''}{trend}%
        </span>
      )}
    </div>
    <div>
      <h3 className="text-text-muted text-sm font-medium">{title}</h3>
      <p className="text-2xl font-bold text-text mt-1">{value}</p>
    </div>
  </div>
);

const fmt = (n: number) => new Intl.NumberFormat('fr-DZ').format(Math.round(n));

export const Dashboard: React.FC = () => {
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const [selectedPeriod, setSelectedPeriod] = useState<string>('Last 30 Days');
  const [customRange, setCustomRange] = useState({ start: '', end: '' });
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const userStr = localStorage.getItem('user');
  const userRole = userStr ? JSON.parse(userStr).role : 'admin';

  useEffect(() => {
    setLoading(true);
    const { start_date, end_date } = getDates(selectedPeriod, customRange);
    dashboardApi.getStats({ start_date, end_date })
      .then(({ data }) => setStats(data))
      .catch(() => setError('Failed to load dashboard data.'))
      .finally(() => setLoading(false));
  }, [selectedPeriod, customRange]);

  const scroll = (direction: 'left' | 'right') => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollBy({
        left: direction === 'left' ? -340 : 340,
        behavior: 'smooth',
      });
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Overview</h1>
          <p className="text-sm text-text-muted mt-1">Real-time platform insights and sales performance.</p>
        </div>
        <div className="flex flex-wrap items-center gap-3 w-full sm:w-auto">
          <div className="flex items-center gap-2 bg-surface border border-border rounded-xl px-3 py-2 shadow-sm">
            <Calendar className="w-4 h-4 text-text-muted" />
            <select
              value={selectedPeriod}
              onChange={(e) => setSelectedPeriod(e.target.value)}
              className="bg-transparent text-sm font-medium text-text outline-none cursor-pointer pr-2"
            >
              <option value="Today">Today</option>
              <option value="Yesterday">Yesterday</option>
              <option value="Last 7 Days">Last 7 Days</option>
              <option value="Last 30 Days">Last 30 Days</option>
              <option value="This Month">This Month</option>
              <option value="Custom">Custom Range</option>
            </select>
          </div>

          {selectedPeriod === 'Custom' && (
            <div className="flex items-center gap-2 bg-surface border border-border rounded-xl px-3 py-1.5 shadow-sm">
              <input type="date" value={customRange.start} onChange={(e) => setCustomRange({ ...customRange, start: e.target.value })} className="bg-transparent text-xs text-text outline-none" />
              <span className="text-xs text-text-muted font-medium">to</span>
              <input type="date" value={customRange.end} onChange={(e) => setCustomRange({ ...customRange, end: e.target.value })} className="bg-transparent text-xs text-text outline-none" />
            </div>
          )}

          <button className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-xl text-sm font-medium hover:bg-primary-hover transition-colors shadow-md shadow-primary/20 cursor-pointer">
            <Download className="w-4 h-4" />
            Download Report
          </button>
        </div>
      </div>

      {/* Stat Cards */}
      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="w-8 h-8 text-primary animate-spin" />
        </div>
      ) : error ? (
        <div className="p-4 bg-danger/10 text-danger rounded-xl text-sm">{error}</div>
      ) : (
        <div className="relative group/scroll">
          <button onClick={() => scroll('left')} className="absolute -left-4 top-1/2 -translate-y-1/2 z-10 w-10 h-10 bg-surface border border-border shadow-md rounded-full flex items-center justify-center text-text hover:text-primary transition-all duration-200 opacity-0 group-hover/scroll:opacity-100 cursor-pointer hover:scale-105">
            <ChevronLeft className="w-5 h-5" />
          </button>
          <div ref={scrollContainerRef} className="flex gap-6 overflow-x-auto hide-scrollbar scroll-smooth pb-4 snap-x snap-mandatory">
            {userRole === 'confirmatrice' ? (
              <>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Total Orders" value={stats?.orders?.total ?? 0} icon={Package} colorClass="bg-primary/10 text-primary" />
                </div>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Pending Orders" value={stats?.orders?.pending ?? 0} icon={Clock} colorClass="bg-yellow-500/10 text-yellow-500" />
                </div>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Confirmed Orders" value={stats?.orders?.confirmed ?? 0} icon={CheckCircle} colorClass="bg-blue-500/10 text-blue-500" />
                </div>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Shipped Orders" value={stats?.orders?.shipped ?? 0} icon={Truck} colorClass="bg-purple-500/10 text-purple-500" />
                </div>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Delivered Orders" value={stats?.orders?.delivered ?? 0} icon={ShoppingBag} colorClass="bg-success/10 text-success" />
                </div>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Failed/Cancelled" value={(stats?.orders?.failed ?? 0) + (stats?.orders?.cancelled ?? 0)} icon={XCircle} colorClass="bg-danger/10 text-danger" />
                </div>
              </>
            ) : (
              <>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Total Revenue (DZD)" value={`DZD ${fmt(stats?.sales?.revenue ?? 0)}`} icon={TrendingUp} colorClass="bg-primary/10 text-primary" />
                </div>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Total Marketers" value={stats?.users?.marketers ?? 0} icon={Users} colorClass="bg-blue-500/10 text-blue-500" />
                </div>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Active Products" value={stats?.products ?? 0} icon={Package} colorClass="bg-purple-500/10 text-purple-500" />
                </div>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Failed Orders" value={stats?.orders?.failed ?? 0} icon={XCircle} colorClass="bg-danger/10 text-danger" />
                </div>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Pending Payouts" value={stats?.pending_payouts ?? 0} icon={CreditCard} colorClass="bg-success/10 text-success" />
                </div>
                <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
                  <StatCard title="Net Profit (DZD)" value={`DZD ${fmt(stats?.sales?.net_profit ?? 0)}`} icon={DollarSign} colorClass="bg-emerald-500/10 text-emerald-500" />
                </div>
              </>
            )}
          </div>
          <button onClick={() => scroll('right')} className="absolute -right-4 top-1/2 -translate-y-1/2 z-10 w-10 h-10 bg-surface border border-border shadow-md rounded-full flex items-center justify-center text-text hover:text-primary transition-all duration-200 opacity-0 group-hover/scroll:opacity-100 cursor-pointer hover:scale-105">
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      )}

      {/* Analytics Chart for Both Roles */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-6">
        <div className={`bg-surface rounded-2xl border border-border p-6 shadow-sm ${userRole === 'admin' ? 'lg:col-span-2' : 'lg:col-span-3'}`}>
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-bold text-text">Orders Analytics</h2>
          </div>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={0}>
              <AreaChart data={stats?.chart_data || []}>
                <defs>
                  <linearGradient id="colorOrders" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: '#5F5E5E', fontSize: 12 }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fill: '#5F5E5E', fontSize: 12 }} dx={-10} />
                <Tooltip contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }} cursor={{ stroke: '#3b82f6', strokeWidth: 1, strokeDasharray: '3 3' }} />
                <Area type="monotone" dataKey="total" name="Total Orders" stroke="#3b82f6" strokeWidth={3} fillOpacity={1} fill="url(#colorOrders)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {userRole === 'admin' && (
          <div className="bg-surface rounded-2xl border border-border p-6 shadow-sm">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-bold text-text">Top Performers</h2>
              <button className="text-text-muted hover:text-primary transition-colors">
                <MoreHorizontal className="w-5 h-5" />
              </button>
            </div>
            <div className="space-y-4">
              {loading
                ? Array.from({ length: 5 }).map((_, i) => (
                    <div key={i} className="h-14 bg-background rounded-xl animate-pulse" />
                  ))
                : (stats?.top_marketers ?? []).map((m: any, i: number) => (
                    <div key={m.id} className="flex items-center justify-between p-3 rounded-xl hover:bg-background transition-colors">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-sm">
                          #{i + 1}
                        </div>
                        <div>
                          <p className="text-sm font-semibold text-text">{m.name}</p>
                          <p className="text-xs text-text-muted">{m.delivered_orders_count ?? 0} delivered</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className={`text-sm font-bold ${m.net_balance >= 0 ? 'text-success' : 'text-danger'}`}>
                          DZD {fmt(m.net_balance ?? 0)}
                        </p>
                        <p className="text-xs text-text-muted">Balance</p>
                      </div>
                    </div>
                  ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
