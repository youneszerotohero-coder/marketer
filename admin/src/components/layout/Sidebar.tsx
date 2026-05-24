import React from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Users, 
  Package, 
  ShoppingCart, 
  Wallet,
  Settings,
  LogOut
} from 'lucide-react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: (string | undefined | null | false)[]) {
  return twMerge(clsx(inputs));
}

const navItems = [
  { name: 'Dashboard', path: '/', icon: LayoutDashboard, roles: ['admin', 'confirmatrice'] },
  { name: 'Marketers', path: '/marketers', icon: Users, roles: ['admin'] },
  { name: 'Products', path: '/products', icon: Package, roles: ['admin'] },
  { name: 'Orders', path: '/orders', icon: ShoppingCart, roles: ['admin', 'confirmatrice'] },
  { name: 'Wallet', path: '/wallet', icon: Wallet, roles: ['admin'] },
];

export const Sidebar: React.FC = () => {
  const location = useLocation();
  const userStr = localStorage.getItem('user');
  const user = userStr ? JSON.parse(userStr) : {};
  const userRole = user?.role || 'admin';

  return (
    <aside className="w-64 bg-surface border-r border-border h-screen sticky top-0 flex flex-col justify-between hidden md:flex">
      <div>
        <div className="h-16 flex items-center px-6 border-b border-border">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
              <span className="text-white font-bold text-xl">A</span>
            </div>
            <span className="text-xl font-bold text-text">Afiliat Admin</span>
          </div>
        </div>
        <nav className="p-4 space-y-1">
          {navItems.filter(item => item.roles.includes(userRole)).map((item) => {
            const isActive = location.pathname === item.path || 
                             (item.path !== '/' && location.pathname.startsWith(item.path));
            return (
              <NavLink
                key={item.name}
                to={item.path}
                className={cn(
                  "flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200 text-sm font-medium",
                  isActive 
                    ? "bg-primary text-white shadow-md shadow-primary/20" 
                    : "text-text-muted hover:bg-background hover:text-text"
                )}
              >
                <item.icon className="w-5 h-5" />
                {item.name}
              </NavLink>
            );
          })}
        </nav>
      </div>

      <div className="p-4 border-t border-border">
        {userRole === 'admin' && (
          <NavLink 
            to="/settings"
            className={({ isActive }) => cn(
              "flex w-full items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200 text-sm font-medium",
              isActive 
                ? "bg-primary text-white shadow-md shadow-primary/20" 
                : "text-text-muted hover:bg-background hover:text-text"
            )}
          >
            <Settings className="w-5 h-5" />
            Settings
          </NavLink>
        )}
        <button 
          onClick={async () => {
            try {
              const { authApi } = await import('../../services/api');
              await authApi.logout();
            } catch (e) {
              console.error('Logout error', e);
            } finally {
              localStorage.removeItem('access_token');
              localStorage.removeItem('user');
              window.location.href = '/login';
            }
          }}
          className="flex w-full items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200 text-sm font-medium text-danger hover:bg-danger/10 mt-1"
        >
          <LogOut className="w-5 h-5" />
          Logout
        </button>
      </div>
    </aside>
  );
};
