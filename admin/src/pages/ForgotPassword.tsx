import React, { useState } from 'react';
import { Mail, ArrowLeft, TrendingUp, Globe } from 'lucide-react';
import { authApi } from '../services/api';
import { Link, useNavigate } from 'react-router-dom';
import { useLanguage } from '../context/LanguageContext';

export const ForgotPassword: React.FC = () => {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();
  const { t, language, setLanguage } = useLanguage();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await authApi.forgotPassword(email);
      navigate(`/verify-code?email=${encodeURIComponent(email)}`);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Une erreur est survenue. Veuillez réessayer.');
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
          <h1 className="text-2xl font-bold text-text">{t('auth.forgotTitle')}</h1>
          <p className="text-sm text-text-muted mt-1">{t('auth.forgotSub')}</p>
        </div>

        <div className="bg-surface border border-border rounded-2xl p-8 shadow-sm">
          {error && (
            <div className="mb-5 p-3 bg-danger/10 border border-danger/20 text-danger text-sm rounded-lg">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
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

            <button
              type="submit"
              disabled={loading}
              className="w-full flex items-center justify-center gap-2 px-4 py-3 bg-primary text-white rounded-xl text-sm font-semibold hover:bg-primary-hover transition-colors shadow-md shadow-primary/20 disabled:opacity-60 disabled:cursor-not-allowed cursor-pointer"
            >
              {loading ? (
                <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <Mail className="w-4 h-4" />
              )}
              {loading ? t('auth.sendingCode') : t('auth.sendCodeBtn')}
            </button>
          </form>

          <div className="mt-6 text-center">
            <Link
              to="/login"
              className="inline-flex items-center gap-2 text-xs font-semibold text-text-muted hover:text-text transition-colors"
            >
              <ArrowLeft className="w-3.5 h-3.5 rtl:rotate-180" /> {t('auth.backToLogin')}
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};
