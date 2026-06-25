import React from 'react';
import { Search, Bell, Menu, X, Globe } from 'lucide-react';
import { useLanguage } from '../../context/LanguageContext';

type HeaderProps = {
  onMenuClick?: () => void;
  isMobileMenuOpen?: boolean;
};

export const Header: React.FC<HeaderProps> = ({
  onMenuClick,
  isMobileMenuOpen = false,
}) => {
  const userStr = localStorage.getItem('user');
  const user = userStr ? JSON.parse(userStr) : { name: 'Admin User', role: 'admin' };
  const initials = user.name ? user.name.substring(0, 2).toUpperCase() : 'AD';
  const { t, language, setLanguage } = useLanguage();

  const getRoleLabel = (role: string) => {
    if (role === 'admin') return t('header.adminUser');
    if (role === 'confirmatrice') return t('orders.confirmatriceLabel');
    return role;
  };

  return (
    <header className="h-16 bg-surface border-b border-border flex items-center justify-between px-4 lg:px-8 sticky top-0 z-10 glass">
      <div className="flex items-center gap-4">
        <button
          type="button"
          onClick={onMenuClick}
          aria-label={isMobileMenuOpen ? 'Close navigation menu' : 'Open navigation menu'}
          aria-expanded={isMobileMenuOpen}
          className="md:hidden text-text-muted hover:text-text transition-colors"
        >
          {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
        </button>
        <div className="relative hidden sm:block">
          <Search className="w-4 h-4 absolute start-3 top-1/2 -translate-y-1/2 text-text-muted" />
          <input 
            type="text" 
            placeholder={t('header.searchPlaceholder')}
            className="ps-10 pe-4 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary transition-colors w-64 lg:w-96"
          />
        </div>
      </div>
      
      <div className="flex items-center gap-4">
        {/* Compact Language Selector */}
        <div className="flex items-center gap-1 bg-background border border-border px-2.5 py-1 rounded-xl shadow-sm">
          <Globe className="w-3.5 h-3.5 text-text-muted" />
          <button
            onClick={() => setLanguage('fr')}
            className={`text-xs font-semibold px-2 py-0.5 rounded-md transition-colors ${language === 'fr' ? 'bg-primary text-white' : 'text-text-muted hover:text-text'}`}
          >
            FR
          </button>
          <span className="text-border">|</span>
          <button
            onClick={() => setLanguage('ar')}
            className={`text-xs font-semibold px-2 py-0.5 rounded-md transition-colors ${language === 'ar' ? 'bg-primary text-white font-cairo' : 'text-text-muted hover:text-text font-cairo'}`}
          >
            العربية
          </button>
        </div>

        <button className="relative p-2 text-text-muted hover:text-text transition-colors rounded-full hover:bg-background">
          <Bell className="w-5 h-5" />
          <span className="absolute top-1 end-1 w-2 h-2 bg-primary rounded-full border border-surface"></span>
        </button>
        
        <div className="flex items-center gap-3 ps-4 border-s border-border">
          <div className="hidden md:block text-end">
            <p className="text-sm font-semibold text-text">{user.name}</p>
            <p className="text-xs text-text-muted capitalize">{getRoleLabel(user.role)}</p>
          </div>
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-primary to-primary-hover flex items-center justify-center shadow-sm">
            <span className="text-white text-sm font-bold">{initials}</span>
          </div>
        </div>
      </div>
    </header>
  );
};
