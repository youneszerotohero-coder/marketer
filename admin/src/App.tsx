import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AdminLayout } from './components/layout/AdminLayout';
import { Dashboard } from './pages/Dashboard';
import { ManageMarketers } from './pages/ManageMarketers';
import { ManageProducts } from './pages/ManageProducts';
import { OrdersManagement } from './pages/OrdersManagement';
import { WalletManagement } from './pages/WalletManagement';
import { Settings } from './pages/Settings';
import { LoginPage } from './pages/LoginPage';
import { ShippingRates } from './pages/ShippingRates';
import { ForgotPassword } from './pages/ForgotPassword';
import { VerifyCode } from './pages/VerifyCode';
import { ResetPassword } from './pages/ResetPassword';
import { LanguageProvider } from './context/LanguageContext';

// Guard: redirect to /login if no token stored
const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const token = localStorage.getItem('access_token');
  const isAuthenticated = token && token !== 'undefined' && token !== 'null';
  return isAuthenticated ? <>{children}</> : <Navigate to="/login" replace />;
};

// Guard: redirect to / if already logged in
const PublicOnlyRoute = ({ children }: { children: React.ReactNode }) => {
  const token = localStorage.getItem('access_token');
  const userStr = localStorage.getItem('user');
  const isAuthenticated = token && token !== 'undefined' && token !== 'null' && userStr;
  return isAuthenticated ? <Navigate to="/" replace /> : <>{children}</>;
};

// Guard: allow only admins
const AdminRoute = ({ children }: { children: React.ReactNode }) => {
  const userStr = localStorage.getItem('user');
  let user = null;
  try {
    user = userStr && userStr !== 'undefined' && userStr !== 'null' ? JSON.parse(userStr) : null;
  } catch (e) {
    user = null;
  }
  return user?.role === 'admin' ? <>{children}</> : <Navigate to="/" replace />;
};

function App() {
  return (
    <LanguageProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<PublicOnlyRoute><LoginPage /></PublicOnlyRoute>} />
          <Route path="/forgot-password" element={<PublicOnlyRoute><ForgotPassword /></PublicOnlyRoute>} />
          <Route path="/verify-code" element={<PublicOnlyRoute><VerifyCode /></PublicOnlyRoute>} />
          <Route path="/reset-password" element={<PublicOnlyRoute><ResetPassword /></PublicOnlyRoute>} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <AdminLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Dashboard />} />
            <Route path="marketers" element={<AdminRoute><ManageMarketers /></AdminRoute>} />
            <Route path="products" element={<AdminRoute><ManageProducts /></AdminRoute>} />
            <Route path="orders" element={<OrdersManagement />} />
            <Route path="wallet" element={<AdminRoute><WalletManagement /></AdminRoute>} />
            <Route path="settings" element={<AdminRoute><Settings /></AdminRoute>} />
            <Route path="shipping-rates" element={<AdminRoute><ShippingRates /></AdminRoute>} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </LanguageProvider>
  );
}

export default App;