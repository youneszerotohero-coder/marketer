import React, { useRef, useState } from 'react';
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
  Download
} from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const data = [
  { name: 'Jan', sales: 4000 },
  { name: 'Feb', sales: 3000 },
  { name: 'Mar', sales: 2000 },
  { name: 'Apr', sales: 2780 },
  { name: 'May', sales: 1890 },
  { name: 'Jun', sales: 2390 },
  { name: 'Jul', sales: 3490 },
];

const StatCard = ({ title, value, icon: Icon, trend, colorClass }: any) => (
  <div className="bg-surface rounded-2xl p-6 border border-border shadow-sm flex flex-col gap-4 hover:-translate-y-1 transition-transform duration-300 h-full">
    <div className="flex justify-between items-start">
      <div className={`p-3 rounded-xl ${colorClass}`}>
        <Icon className="w-6 h-6" />
      </div>
      {trend && (
        <span className={`text-sm font-medium ${trend > 0 ? 'text-success' : 'text-danger'}`}>
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

export const Dashboard: React.FC = () => {
  const scrollContainerRef = useRef<HTMLDivElement>(null);
  const [selectedPeriod, setSelectedPeriod] = useState<string>('Last 30 Days');
  const [customRange, setCustomRange] = useState({ start: '', end: '' });

  const scroll = (direction: 'left' | 'right') => {
    if (scrollContainerRef.current) {
      const scrollAmount = 340;
      scrollContainerRef.current.scrollBy({
        left: direction === 'left' ? -scrollAmount : scrollAmount,
        behavior: 'smooth'
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
          {/* Interval Date Picker */}
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
            <div className="flex items-center gap-2 bg-surface border border-border rounded-xl px-3 py-1.5 shadow-sm transition-all duration-300">
              <input 
                type="date" 
                value={customRange.start}
                onChange={(e) => setCustomRange({ ...customRange, start: e.target.value })}
                className="bg-transparent text-xs text-text outline-none"
              />
              <span className="text-xs text-text-muted font-medium">to</span>
              <input 
                type="date" 
                value={customRange.end}
                onChange={(e) => setCustomRange({ ...customRange, end: e.target.value })}
                className="bg-transparent text-xs text-text outline-none"
              />
            </div>
          )}

          <button className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-xl text-sm font-medium hover:bg-primary-hover transition-colors shadow-md shadow-primary/20 cursor-pointer">
            <Download className="w-4 h-4" />
            Download Report
          </button>
        </div>
      </div>

      <div className="relative group/scroll">
        {/* Left scroll button */}
        <button 
          onClick={() => scroll('left')}
          className="absolute -left-4 top-1/2 -translate-y-1/2 z-10 w-10 h-10 bg-surface border border-border shadow-md rounded-full flex items-center justify-center text-text hover:text-primary transition-all duration-200 opacity-0 group-hover/scroll:opacity-100 cursor-pointer hover:scale-105"
        >
          <ChevronLeft className="w-5 h-5" />
        </button>

        {/* Scrollable container */}
        <div 
          ref={scrollContainerRef}
          className="flex gap-6 overflow-x-auto hide-scrollbar scroll-smooth pb-4 snap-x snap-mandatory"
        >
          <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
            <StatCard title="Total Sales" value="$124,563" icon={TrendingUp} trend={12.5} colorClass="bg-primary/10 text-primary" />
          </div>
          <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
            <StatCard title="Total Marketers" value="1,245" icon={Users} trend={5.2} colorClass="bg-blue-500/10 text-blue-500" />
          </div>
          <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
            <StatCard title="Total Products" value="854" icon={Package} trend={2.4} colorClass="bg-purple-500/10 text-purple-500" />
          </div>
          <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
            <StatCard title="Failed Orders" value="23" icon={XCircle} trend={-1.5} colorClass="bg-danger/10 text-danger" />
          </div>
          <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
            <StatCard title="Withdrawals" value="$45,231" icon={CreditCard} trend={8.1} colorClass="bg-success/10 text-success" />
          </div>
          <div className="min-w-[280px] sm:min-w-[300px] flex-1 snap-start">
            <StatCard title="Net Profit" value="$79,332" icon={DollarSign} trend={15.4} colorClass="bg-emerald-500/10 text-emerald-500" />
          </div>
        </div>

        {/* Right scroll button */}
        <button 
          onClick={() => scroll('right')}
          className="absolute -right-4 top-1/2 -translate-y-1/2 z-10 w-10 h-10 bg-surface border border-border shadow-md rounded-full flex items-center justify-center text-text hover:text-primary transition-all duration-200 opacity-0 group-hover/scroll:opacity-100 cursor-pointer hover:scale-105"
        >
          <ChevronRight className="w-5 h-5" />
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-surface rounded-2xl border border-border p-6 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-bold text-text">Sales Analytics</h2>
            <select className="bg-background border border-border rounded-lg px-3 py-1 text-sm outline-none focus:border-primary">
              <option>This Year</option>
              <option>Last Year</option>
            </select>
          </div>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={0}>
              <AreaChart data={data}>
                <defs>
                  <linearGradient id="colorSales" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#F97316" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#F97316" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: '#5F5E5E', fontSize: 12}} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: '#5F5E5E', fontSize: 12}} dx={-10} />
                <Tooltip 
                  contentStyle={{borderRadius: '12px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)'}}
                  cursor={{stroke: '#F97316', strokeWidth: 1, strokeDasharray: '3 3'}}
                />
                <Area type="monotone" dataKey="sales" stroke="#F97316" strokeWidth={3} fillOpacity={1} fill="url(#colorSales)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-surface rounded-2xl border border-border p-6 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-bold text-text">Top Performers</h2>
            <button className="text-text-muted hover:text-primary transition-colors">
              <MoreHorizontal className="w-5 h-5" />
            </button>
          </div>
          <div className="space-y-4">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="flex items-center justify-between p-3 rounded-xl hover:bg-background transition-colors">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold">
                    M{i}
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-text">Marketer {i}</p>
                    <p className="text-xs text-text-muted">{120 - i * 10} sales</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-bold text-success">${(5000 - i * 400).toLocaleString()}</p>
                  <p className="text-xs text-text-muted">Commission</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
