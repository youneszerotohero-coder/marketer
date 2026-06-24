import React, { useState, useEffect } from 'react';
import { KeyRound, ArrowLeft, RefreshCw } from 'lucide-react';
import { authApi } from '../services/api';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';

export const VerifyCode: React.FC = () => {
  const [searchParams] = useSearchParams();
  const email = searchParams.get('email') || '';
  const navigate = useNavigate();

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
      setError('Le code de validation doit comporter exactement 6 chiffres.');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');
    try {
      await authApi.verifyCode(email, token);
      navigate(`/reset-password?email=${encodeURIComponent(email)}&token=${encodeURIComponent(token)}`);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Le code saisi est incorrect ou a expiré.');
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
      setSuccess('Un nouveau code de validation a été envoyé.');
      setCountdown(30);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Erreur lors du renvoi du code.');
    } finally {
      setResending(false);
    }
  };

  return (
    <div className="min-h-screen bg-background flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-primary/10 rounded-2xl mb-4">
            <KeyRound className="w-8 h-8 text-primary" />
          </div>
          <h1 className="text-2xl font-bold text-text">Validation du code</h1>
          <p className="text-sm text-text-muted mt-1">
            Saisissez le code à 6 chiffres envoyé à <span className="font-semibold text-text">{email}</span>
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
              <label className="block text-sm font-medium text-text mb-1.5">Code de validation (6 chiffres)</label>
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
              className="w-full flex items-center justify-center gap-2 px-4 py-3 bg-primary text-white rounded-xl text-sm font-semibold hover:bg-primary-hover transition-colors shadow-md shadow-primary/20 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {loading ? (
                <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : (
                <KeyRound className="w-4 h-4" />
              )}
              {loading ? 'Validation en cours...' : 'Valider le code'}
            </button>
          </form>

          {/* Resend Button with Countdown */}
          <div className="mt-5 text-center">
            <button
              type="button"
              onClick={handleResend}
              disabled={countdown > 0 || resending}
              className="inline-flex items-center gap-1.5 text-sm font-semibold text-primary hover:text-primary-hover disabled:text-text-muted transition-colors disabled:cursor-not-allowed"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${resending ? 'animate-spin' : ''}`} />
              {countdown > 0 ? `Renvoyer le code (${countdown}s)` : 'Renvoyer le code'}
            </button>
          </div>

          <div className="mt-6 text-center border-t border-border pt-5">
            <Link
              to="/forgot-password"
              className="inline-flex items-center gap-2 text-xs font-semibold text-text-muted hover:text-text transition-colors"
            >
              <ArrowLeft className="w-3.5 h-3.5" /> Modifier l'adresse e-mail
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};
