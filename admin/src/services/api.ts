import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

export const STORAGE_URL = BASE_URL.replace(/\/api$/, '/storage');

const api = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
});

// Inject JWT token on every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Handle 401 → redirect to login
api.interceptors.response.use(
  (res) => res,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('access_token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;

// ─── Auth ────────────────────────────────────────────────────────────────────
export const authApi = {
  login: (email: string, password: string) =>
    api.post('/auth/login', { email, password }),
  logout: () => api.post('/auth/logout'),
  me: () => api.get('/me'),
};

// ─── Dashboard ───────────────────────────────────────────────────────────────
export const dashboardApi = {
  getStats: (params?: Record<string, string>) => api.get('/admin/dashboard', { params }),
};

// ─── Users (Marketers / Confirmatrices / Admins) ─────────────────────────────
export const usersApi = {
  list: (params?: Record<string, string | number>) =>
    api.get('/admin/users', { params }),
  create: (data: Record<string, unknown>) => api.post('/admin/users', data),
  update: (id: number, data: Record<string, unknown>) =>
    api.patch(`/admin/users/${id}`, data),
  getStats: (id: number) => api.get(`/admin/users/${id}/stats`),
};

// ─── Products ────────────────────────────────────────────────────────────────
export const productsApi = {
  list: (params?: Record<string, string | number>) =>
    api.get('/admin/products', { params }),
  create: (data: Record<string, unknown>) => api.post('/admin/products', data),
  update: (id: number, data: Record<string, unknown>) =>
    api.patch(`/admin/products/${id}`, data),
  archive: (id: number) => api.patch(`/admin/products/${id}/archive`),
  updateVariant: (variantId: number, data: Record<string, unknown>) =>
    api.patch(`/admin/variants/${variantId}`, data),
};

// ─── Categories ──────────────────────────────────────────────────────────────
export const categoriesApi = {
  list: (params?: Record<string, string | number>) =>
    api.get('/admin/categories', { params }),
  create: (data: Record<string, unknown>) => api.post('/admin/categories', data),
  update: (id: number, data: Record<string, unknown>) =>
    api.patch(`/admin/categories/${id}`, data),
};

// ─── Orders ──────────────────────────────────────────────────────────────────
export const ordersApi = {
  list: (params?: Record<string, string | number>) => {
    const userStr = localStorage.getItem('user');
    const role = userStr ? JSON.parse(userStr).role : 'admin';
    const prefix = role === 'confirmatrice' ? '/confirmatrice' : '/admin';
    return api.get(`${prefix}/orders`, { params });
  },
  updateStatus: (id: number, data: { status: string; notes?: string; postponed_until?: string }) => {
    const userStr = localStorage.getItem('user');
    const role = userStr ? JSON.parse(userStr).role : 'admin';
    const prefix = role === 'confirmatrice' ? '/confirmatrice' : '/admin';
    return api.patch(`${prefix}/orders/${id}/status`, data);
  },
  update: (id: number, data: { client_name?: string; client_phone?: string; wilaya?: string; commune?: string; address?: string; delivery_type?: 'home' | 'desk'; notes?: string }) => {
    const userStr = localStorage.getItem('user');
    const role = userStr ? JSON.parse(userStr).role : 'admin';
    const prefix = role === 'confirmatrice' ? '/confirmatrice' : '/admin';
    return api.patch(`${prefix}/orders/${id}`, data);
  },
  assignConfirmatrice: (id: number, confirmatriceId: number) =>
    api.patch(`/admin/orders/${id}/assign-confirmatrice`, {
      confirmatrice_id: confirmatriceId,
    }),
  syncDeliveryStatus: (id: number) => api.post(`/orders/${id}/delivery-status`),
};

// ─── Delivery / ZR Express ──────────────────────────────────────────────────
export const deliveryApi = {
  territories: () => api.get('/delivery/territories'),
  rates: () => api.get('/delivery/rates'),
};

// ─── Wallet / Withdrawals ─────────────────────────────────────────────────────
export const walletApi = {
  listWithdrawals: (params?: Record<string, string | number>) =>
    api.get('/admin/wallet/withdrawals', { params }),
  approve: (id: number) => api.patch(`/admin/wallet/withdrawals/${id}/approve`),
  reject: (id: number, notes?: string) =>
    api.patch(`/admin/wallet/withdrawals/${id}/reject`, { notes }),
};

// ─── Settings ─────────────────────────────────────────────────────────────────
export const settingsApi = {
  list: () => api.get('/admin/settings'),
  upsert: (settings: { key: string; value: unknown }[]) =>
    api.patch('/admin/settings', { settings }),
};

// ─── Shipping Rates ────────────────────────────────────────────────────────────
export const shippingRatesApi = {
  list: () => api.get('/admin/shipping-rates'),
  bulkUpdate: (rates: {
    id: number;
    home_price: number;
    desk_price: number;
    is_active: boolean;
    home_active: boolean;
    desk_active: boolean;
  }[]) => api.patch('/admin/shipping-rates', { rates }),
};
