import React from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Users, 
  Package, 
  ShoppingCart, 
  Wallet,
  Settings,
  LogOut,
  Truck
} from 'lucide-react';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { useLanguage } from '../../context/LanguageContext';

export function cn(...inputs: (string | undefined | null | false)[]) {
  return twMerge(clsx(inputs));
}

type SidebarProps = {
  isMobileMenuOpen?: boolean;
  onCloseMobileMenu?: () => void;
};

export const Sidebar: React.FC<SidebarProps> = ({
  isMobileMenuOpen = false,
  onCloseMobileMenu,
}) => {
  const location = useLocation();
  const userStr = localStorage.getItem('user');
  const user = userStr ? JSON.parse(userStr) : {};
  const userRole = user?.role || 'admin';
  const { t } = useLanguage();

  const navItems = [
    { name: t('nav.dashboard'), path: '/', icon: LayoutDashboard, roles: ['admin', 'confirmatrice'] },
    { name: t('nav.marketers'), path: '/marketers', icon: Users, roles: ['admin'] },
    { name: t('nav.products'), path: '/products', icon: Package, roles: ['admin'] },
    { name: t('nav.orders'), path: '/orders', icon: ShoppingCart, roles: ['admin', 'confirmatrice'] },
    { name: t('nav.wallet'), path: '/wallet', icon: Wallet, roles: ['admin'] },
    { name: t('nav.shippingRates'), path: '/shipping-rates', icon: Truck, roles: ['admin'] },
  ];

  return (
    <aside
      className={cn(
        "w-64 bg-surface border-e border-border h-screen flex flex-col justify-between",
        "fixed inset-y-0 start-0 z-50 transform transition-transform duration-200 ease-out md:sticky md:top-0 md:z-auto md:flex",
        isMobileMenuOpen ? "translate-x-0" : "max-md:-translate-x-full max-md:rtl:translate-x-full",
        "md:translate-x-0"
      )}
    >
      <div>
        <div className="h-16 flex items-center px-6 border-b border-border">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
              <span className="text-white font-bold text-xl">A</span>
            </div>
            <span className="text-xl font-bold text-text">{t('nav.title')}</span>
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
                onClick={onCloseMobileMenu}
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
            onClick={onCloseMobileMenu}
            className={({ isActive }) => cn(
              "flex w-full items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200 text-sm font-medium",
              isActive 
                ? "bg-primary text-white shadow-md shadow-primary/20" 
                : "text-text-muted hover:bg-background hover:text-text"
            )}
          >
            <Settings className="w-5 h-5" />
            {t('nav.settings')}
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
          {t('common.logout')}
        </button>
      </div>
    </aside>
  );
};
