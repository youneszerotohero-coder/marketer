import React, { useState, useEffect } from 'react';
import { KeyRound, ArrowLeft, RefreshCw, Globe } from 'lucide-react';
import { authApi } from '../services/api';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { useLanguage } from '../context/LanguageContext';

export const VerifyCode: React.FC = () => {
  const [searchParams] = useSearchParams();
  const email = searchParams.get('email') || '';
  const navigate = useNavigate();
  const { t, language, setLanguage } = useLanguage();

  const [token, setToken] = useState('');
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [countdown, setCountdown] = useState(30);

  useEffect(() => {
    if (!email) {
      navigate('/forgot-password');
      return;
    }
  }, [email, navigate]);

  useEffect(() => {
    if (countdown <= 0) return;
    const timer = setTimeout(() => {
      setCountdown((prev) => prev - 1);
    }, 1000);
    return () => clearTimeout(timer);
  }, [countdown]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (token.length !== 6) {
      setError(t('auth.codeLengthError'));
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');
    try {
      await authApi.verifyCode(email, token);
      navigate(`/reset-password?email=${encodeURIComponent(email)}&token=${encodeURIComponent(token)}`);
    } catch (err: any) {
      setError(err.response?.data?.message || t('auth.codeInvalidError'));
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    if (countdown > 0 || resending) return;

    setResending(true);
    setError('');
    setSuccess('');
    try {
      await authApi.forgotPassword(email);
      setSuccess(t('auth.codeSentSuccess'));
      setCountdown(30);
    } catch (err: any) {
      setError(err.response?.data?.message || t('auth.codeResendError'));
    } finally {
      setResending(false);
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
            <KeyRound className="w-8 h-8 text-primary" />
          </div>
          <h1 className="text-2xl font-bold text-text">{t('auth.verifyTitle')}</h1>
          <p className="text-sm text-text-muted mt-1">
            {t('auth.verifySub')} <span className="font-semibold text-text">{email}</span>
          </p>
        </div>

        <div className="bg-surface border border-border rounded-2xl p-8 shadow-sm">
          {error && (
            <div className="mb-5 p-3 bg-danger/10 border border-danger/20 text-danger text-sm rounded-lg">
              {error}
            </div>
          )}

          {success && (
            <div className="mb-5 p-3 bg-success/10 border border-success/20 text-success text-sm rounded-lg">
              {success}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-text mb-1.5">{t('auth.validationCodeLabel')}</label>
              <input
                type="text"
                maxLength={6}
                value={token}
                onChange={(e) => setToken(e.target.value.replace(/\D/g, ''))}
                className="w-full px-4 py-2.5 bg-background border border-border rounded-xl text-sm font-mono tracking-widest text-center focus:outline-none focus:border-primary transition-colors"
                placeholder="123456"
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
              {loading ? t('auth.validating') : t('auth.validateBtn')}
            </button>
          </form>

          {/* Resend Button with Countdown */}
          <div className="mt-5 text-center">
            <button
              type="button"
              onClick={handleResend}
              disabled={countdown > 0 || resending}
              className="inline-flex items-center gap-1.5 text-sm font-semibold text-primary hover:text-primary-hover disabled:text-text-muted transition-colors disabled:cursor-not-allowed cursor-pointer"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${resending ? 'animate-spin' : ''}`} />
              {countdown > 0 ? t('auth.resendCodeCountdown', { countdown }) : t('auth.resendCode')}
            </button>
          </div>

          <div className="mt-6 text-center border-t border-border pt-5">
            <Link
              to="/forgot-password"
              className="inline-flex items-center gap-2 text-xs font-semibold text-text-muted hover:text-text transition-colors cursor-pointer"
            >
              <ArrowLeft className="w-3.5 h-3.5 rtl:rotate-180" /> {t('auth.changeEmail')}
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};
