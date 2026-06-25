import React, { useState } from 'react';
import { LogIn, Eye, EyeOff, TrendingUp, Globe } from 'lucide-react';
import { authApi } from '../services/api';
import { Link } from 'react-router-dom';
import { useLanguage } from '../context/LanguageContext';

export const LoginPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const { t, language, setLanguage } = useLanguage();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const { data } = await authApi.login(email, password);
      // Ensure only admin / confirmatrice can access the panel
      if (!['admin', 'confirmatrice'].includes(data.user?.role)) {
        setError(t('auth.accessDenied'));
        return;
      }
      localStorage.setItem('access_token', data.access_token);
      localStorage.setItem('user', JSON.stringify(data.user));
      window.location.href = '/';
    } catch (err: any) {
      setError(err.response?.data?.message ? (err.response.data.message.includes('credentials') ? t('auth.invalidCredentials') : err.response.data.message) : t('auth.invalidCredentials'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4 relative">
      {/* Floating Language Switcher */}
      <div className="absolute top-4 end-4 flex items-center gap-1.5 bg-surface border border-border px-3 py-1.5 rounded-xl shadow-sm">
        <Globe className="w-4 h-4 text-text-muted" />
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

      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-primary/10 rounded-2xl mb-4">
            <TrendingUp className="w-8 h-8 text-primary" />
          </div>
          <h1 className="text-2xl font-bold text-text">{t('nav.title')}</h1>
          <p className="text-sm text-text-muted mt-1">{t('auth.loginSub')}</p>
        </div>

        <div className="bg-surface border border-border rounded-2xl p-8 shadow-sm">
          <form onSubmit={handleLogin} className="space-y-5">
            {error && (
              <div className="p-3 bg-danger/10 border border-danger/20 text-danger text-sm rounded-lg">
                {error}
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-text mb-1.5">{t('auth.emailLabel')}</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-2.5 bg-background border border-border rounded-xl text-sm focus:outline-none focus:border-primary transition-colors"
                placeholder={t('auth.emailPlaceholder')}
                required
              />
            </div>

            <div>
              <div className="flex justify-between items-center mb-1.5">
                <label className="block text-sm font-medium text-text">{t('auth.passwordLabel')}</label>
                <Link to="/forgot-password" className="text-xs font-semibold text-primary hover:text-primary-hover transition-colors">
                  {t('auth.forgotPassLink')}
                </Link>
              </div>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pe-10 ps-4 py-2.5 bg-background border border-border rounded-xl text-sm focus:outline-none focus:border-primary transition-colors"
                  placeholder={t('auth.passwordPlaceholder')}
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute end-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-text transition-colors"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full flex items-center justify-center gap-2 px-4 py-3 bg-primary text-white rounded-xl text-sm font-semibold hover:bg-primary-hover transition-colors shadow-md shadow-primary/20 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {loading ? (
                <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <LogIn className="w-4 h-4" />
              )}
              {loading ? t('auth.signingIn') : t('auth.signInBtn')}
            </button>
          </form>

          <p className="text-center text-xs text-text-muted mt-6">
            {t('auth.defaultCredentials')}: <span className="font-mono text-text">admin@marketer.local</span> / <span className="font-mono text-text">password</span>
          </p>
        </div>
      </div>
    </div>
  );
};
