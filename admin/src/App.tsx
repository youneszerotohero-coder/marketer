import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AdminLayout } from './components/layout/AdminLayout';
import { Dashboard } from './pages/Dashboard';
import { ManageMarketers } from './pages/ManageMarketers';
import { ManageProducts } from './pages/ManageProducts';
import { OrdersManagement } from './pages/OrdersManagement';
import { WalletManagement } from './pages/WalletManagement';
import { Settings } from './pages/Settings';
import { LoginPage } from './pages/LoginPage';

// Guard: redirect to /login if no token stored
const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const token = localStorage.getItem('access_token');
  return token ? <>{children}</> : <Navigate to="/login" replace />;
};

// Guard: allow only admins
const AdminRoute = ({ children }: { children: React.ReactNode }) => {
  const userStr = localStorage.getItem('user');
  const user = userStr ? JSON.parse(userStr) : null;
  return user?.role === 'admin' ? <>{children}</> : <Navigate to="/" replace />;
};

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
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
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;