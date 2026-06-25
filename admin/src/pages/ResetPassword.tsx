import React, { useState, useEffect } from 'react';
import { Eye, EyeOff, KeyRound, ArrowLeft, TrendingUp, Globe } from 'lucide-react';
import { authApi } from '../services/api';
import { Link, useSearchParams, useNavigate } from 'react-router-dom';
import { useLanguage } from '../context/LanguageContext';

export const ResetPassword: React.FC = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const email = searchParams.get('email') || '';
  const token = searchParams.get('token') || '';
  const { t, language, setLanguage } = useLanguage();

  const [password, setPassword] = useState('');
  const [passwordConfirmation, setPasswordConfirmation] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    if (!email || !token) {
      navigate('/forgot-password');
    }
  }, [email, token, navigate]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password !== passwordConfirmation) {
      setError(t('auth.passwordMismatch'));
      return;
    }
    setLoading(true);
    setError('');
    setSuccess('');
    try {
      await authApi.resetPassword({
        email,
        token,
        password,
        password_confirmation: passwordConfirmation,
      });
      setSuccess(t('auth.resetSuccess'));
    } catch (err: any) {
      setError(err.response?.data?.message || 'Une erreur est survenue lors de la réinitialisation.');
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
          <h1 className="text-2xl font-bold text-text">{t('auth.resetTitle')}</h1>
          <p className="text-sm text-text-muted mt-1">{t('auth.resetSub')}</p>
        </div>

        <div className="bg-surface border border-border rounded-2xl p-8 shadow-sm">
          {error && (
            <div className="mb-5 p-3 bg-danger/10 border border-danger/20 text-danger text-sm rounded-lg">
              {error}
            </div>
          )}

          {success ? (
            <div className="space-y-6">
              <div className="p-4 bg-success/10 border border-success/20 text-success text-sm rounded-xl">
                {success}
              </div>
              <Link
                to="/login"
                className="w-full flex items-center justify-center gap-2 px-4 py-3 bg-primary text-white rounded-xl text-sm font-semibold hover:bg-primary-hover transition-colors shadow-md shadow-primary/20 cursor-pointer"
              >
                {t('auth.signInBtn')}
              </Link>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-5">
              <div>
                <label className="block text-sm font-medium text-text mb-1.5">{t('auth.newPasswordLabel')}</label>
                <div className="relative">
                  <input
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full pe-10 ps-4 py-2.5 bg-background border border-border rounded-xl text-sm focus:outline-none focus:border-primary transition-colors"
                    placeholder="••••••••"
                    required
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute end-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-text transition-colors cursor-pointer"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-text mb-1.5">{t('auth.confirmPasswordLabel')}</label>
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={passwordConfirmation}
                  onChange={(e) => setPasswordConfirmation(e.target.value)}
                  className="w-full px-4 py-2.5 bg-background border border-border rounded-xl text-sm focus:outline-none focus:border-primary transition-colors"
                  placeholder="••••••••"
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
                  <KeyRound className="w-4 h-4" />
                )}
                {loading ? t('auth.resetting') : t('auth.resetBtn')}
              </button>
            </form>
          )}

          <div className="mt-6 text-center">
            <Link
              to="/forgot-password"
              className="inline-flex items-center gap-2 text-xs font-semibold text-text-muted hover:text-text transition-colors cursor-pointer"
            >
              <ArrowLeft className="w-3.5 h-3.5 rtl:rotate-180" /> {t('auth.restartProcess')}
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};
