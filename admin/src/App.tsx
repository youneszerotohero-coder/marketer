import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AdminLayout } from './components/layout/AdminLayout';
import { Dashboard } from './pages/Dashboard';
import { ManageMarketers } from './pages/ManageMarketers';
import { ManageProducts } from './pages/ManageProducts';
import { OrdersManagement } from './pages/OrdersManagement';
import { WalletManagement } from './pages/WalletManagement';
import { Settings } from './pages/Settings';

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<AdminLayout />}>
          <Route index element={<Dashboard />} />
          <Route path="marketers" element={<ManageMarketers />} />
          <Route path="products" element={<ManageProducts />} />
          <Route path="orders" element={<OrdersManagement />} />
          <Route path="wallet" element={<WalletManagement />} />
          <Route path="settings" element={<Settings />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

export default App;