import React from 'react';
import { Search, Bell, Menu } from 'lucide-react';

export const Header: React.FC = () => {
  return (
    <header className="h-16 bg-surface border-b border-border flex items-center justify-between px-4 lg:px-8 sticky top-0 z-10 glass">
      <div className="flex items-center gap-4">
        <button className="md:hidden text-text-muted hover:text-text">
          <Menu className="w-6 h-6" />
        </button>
        <div className="relative hidden sm:block">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
          <input 
            type="text" 
            placeholder="Search anything..." 
            className="pl-10 pr-4 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary transition-colors w-64 lg:w-96"
          />
        </div>
      </div>
      
      <div className="flex items-center gap-4">
        <button className="relative p-2 text-text-muted hover:text-text transition-colors rounded-full hover:bg-background">
          <Bell className="w-5 h-5" />
          <span className="absolute top-1 right-1 w-2 h-2 bg-primary rounded-full border border-surface"></span>
        </button>
        
        <div className="flex items-center gap-3 pl-4 border-l border-border">
          <div className="hidden md:block text-right">
            <p className="text-sm font-semibold text-text">Admin User</p>
            <p className="text-xs text-text-muted">Superadmin</p>
          </div>
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-primary to-primary-hover flex items-center justify-center shadow-sm">
            <span className="text-white text-sm font-bold">AD</span>
          </div>
        </div>
      </div>
    </header>
  );
};
