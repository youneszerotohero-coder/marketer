import React, { useState } from 'react';
import { Search, Plus, Edit, Archive, Filter, LayoutGrid, Upload } from 'lucide-react';
import { Modal } from '../components/ui/Modal';

const mockProducts = [
  { id: '1', name: 'Wireless Headphones', priceBought: '$50.00', category: 'Electronics', stock: 45, commission: '10%', price: '$99.00', brand: 'AudioTech', image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=100&q=80' },
  { id: '2', name: 'Smart Watch Series 5', priceBought: '$120.00', category: 'Wearables', stock: 12, commission: '15%', price: '$199.00', brand: 'TechGear', image: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=100&q=80' },
  { id: '3', name: 'Ergonomic Chair', priceBought: '$150.00', category: 'Furniture', stock: 0, commission: '5%', price: '$249.00', brand: 'ComfortPlus', image: 'https://images.unsplash.com/photo-1505843490538-5133c6c7d0e1?w=100&q=80' },
];

const mockCategories = [
  { id: '1', name: 'Electronics', productCount: 124, status: 'Active' },
  { id: '2', name: 'Wearables', productCount: 45, status: 'Active' },
  { id: '3', name: 'Furniture', productCount: 8, status: 'Inactive' },
];

export const ManageProducts: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'products' | 'categories'>('products');
  const [actionModal, setActionModal] = useState<'add' | 'edit' | 'archive' | null>(null);
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [productsLimit, setProductsLimit] = useState(20);
  const [categoriesLimit, setCategoriesLimit] = useState(20);

  const productsList = Array.from({ length: 25 }, (_, i) => ({
    ...mockProducts[i % mockProducts.length],
    id: String(i + 1),
    name: `${mockProducts[i % mockProducts.length].name} ${i + 1}`
  }));

  const categoriesList = Array.from({ length: 25 }, (_, i) => ({
    ...mockCategories[i % mockCategories.length],
    id: String(i + 1),
    name: `${mockCategories[i % mockCategories.length].name} ${i + 1}`
  }));

  const visibleProducts = productsList.slice(0, productsLimit);
  const visibleCategories = categoriesList.slice(0, categoriesLimit);

  const openModal = (type: any, item?: any) => {
    setSelectedItem(item || null);
    setActionModal(type);
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text">Manage Products</h1>
          <p className="text-sm text-text-muted mt-1">Add new products, edit details, and manage categories.</p>
        </div>
        <button 
          onClick={() => openModal('add')}
          className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors shadow-md shadow-primary/20"
        >
          <Plus className="w-4 h-4" />
          {activeTab === 'products' ? 'Add Product' : 'Add Category'}
        </button>
      </div>

      <div className="flex border-b border-border">
        <button 
          onClick={() => setActiveTab('products')}
          className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === 'products' ? 'border-primary text-primary' : 'border-transparent text-text-muted hover:text-text'}`}
        >
          Products List
        </button>
        <button 
          onClick={() => setActiveTab('categories')}
          className={`px-4 py-3 text-sm font-medium border-b-2 transition-colors ${activeTab === 'categories' ? 'border-primary text-primary' : 'border-transparent text-text-muted hover:text-text'}`}
        >
          Categories
        </button>
      </div>

      {activeTab === 'products' ? (
        <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
          <div className="p-4 border-b border-border flex flex-wrap items-center gap-4 bg-background/50">
            <div className="relative flex-1 min-w-[250px]">
              <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
              <input 
                type="text" 
                placeholder="Search by product name, SKU or brand..." 
                className="w-full pl-10 pr-4 py-2 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary transition-colors"
              />
            </div>
            <button className="flex items-center gap-2 px-4 py-2 border border-border rounded-lg text-sm font-medium text-text-muted hover:bg-background transition-colors">
              <Filter className="w-4 h-4" />
              Filters
            </button>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider">
                  <th className="p-4 font-medium">Product</th>
                  <th className="p-4 font-medium">Price Bought</th>
                  <th className="p-4 font-medium">Category & Brand</th>
                  <th className="p-4 font-medium">Price</th>
                  <th className="p-4 font-medium">Stock</th>
                  <th className="p-4 font-medium">Commission</th>
                  <th className="p-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {visibleProducts.map((product) => (
                  <tr key={product.id} className="hover:bg-background/50 transition-colors group">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <img src={product.image} alt={product.name} className="w-12 h-12 rounded-lg object-cover border border-border" />
                        <div>
                          <p className="text-sm font-semibold text-text line-clamp-1">{product.name}</p>
                        </div>
                      </div>
                    </td>
                    <td className="p-4 text-sm font-bold text-text">{product.priceBought}</td>
                    <td className="p-4">
                      <p className="text-sm text-text">{product.category}</p>
                      <p className="text-xs text-text-muted">{product.brand}</p>
                    </td>
                    <td className="p-4 text-sm font-bold text-text">{product.price}</td>
                    <td className="p-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        product.stock > 10 ? 'bg-success/10 text-success' : 
                        product.stock > 0 ? 'bg-primary/10 text-primary' : 'bg-danger/10 text-danger'
                      }`}>
                        {product.stock > 0 ? `${product.stock} in stock` : 'Out of stock'}
                      </span>
                    </td>
                    <td className="p-4 text-sm font-medium text-success">{product.commission}</td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button onClick={() => openModal('edit', product)} className="p-1.5 text-text-muted hover:text-blue-500 hover:bg-blue-500/10 rounded-md transition-colors" title="Edit">
                          <Edit className="w-4 h-4" />
                        </button>
                        <button onClick={() => openModal('archive', product)} className="p-1.5 text-text-muted hover:text-danger hover:bg-danger/10 rounded-md transition-colors" title="Archive">
                          <Archive className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {productsLimit < productsList.length && (
            <div className="p-4 border-t border-border flex justify-center bg-background/20">
              <button 
                onClick={() => setProductsLimit(prev => prev + 20)}
                className="px-5 py-2 border border-border bg-surface text-text hover:bg-background text-sm font-semibold rounded-xl transition-all duration-200 cursor-pointer shadow-sm hover:scale-102"
              >
                Load More
              </button>
            </div>
          )}
        </div>
      ) : (
        <div className="bg-surface border border-border rounded-2xl shadow-sm overflow-hidden">
          <div className="p-4 border-b border-border flex flex-wrap items-center gap-4 bg-background/50">
            <div className="relative flex-1 min-w-[250px]">
              <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-text-muted" />
              <input 
                type="text" 
                placeholder="Search categories..." 
                className="w-full pl-10 pr-4 py-2 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary transition-colors"
              />
            </div>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider">
                  <th className="p-4 font-medium">Category Name</th>
                  <th className="p-4 font-medium">Total Products</th>
                  <th className="p-4 font-medium">Status</th>
                  <th className="p-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {visibleCategories.map((category) => (
                  <tr key={category.id} className="hover:bg-background/50 transition-colors group">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
                          <LayoutGrid className="w-5 h-5" />
                        </div>
                        <p className="text-sm font-semibold text-text">{category.name}</p>
                      </div>
                    </td>
                    <td className="p-4 text-sm text-text-muted">{category.productCount} products</td>
                    <td className="p-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        category.status === 'Active' ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'
                      }`}>
                        {category.status}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button onClick={() => openModal('edit', category)} className="p-1.5 text-text-muted hover:text-blue-500 hover:bg-blue-500/10 rounded-md transition-colors" title="Edit">
                          <Edit className="w-4 h-4" />
                        </button>
                        <button onClick={() => openModal('archive', category)} className="p-1.5 text-text-muted hover:text-danger hover:bg-danger/10 rounded-md transition-colors" title="Archive">
                          <Archive className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {categoriesLimit < categoriesList.length && (
            <div className="p-4 border-t border-border flex justify-center bg-background/20">
              <button 
                onClick={() => setCategoriesLimit(prev => prev + 20)}
                className="px-5 py-2 border border-border bg-surface text-text hover:bg-background text-sm font-semibold rounded-xl transition-all duration-200 cursor-pointer shadow-sm hover:scale-102"
              >
                Load More
              </button>
            </div>
          )}
        </div>
      )}

      <Modal 
        isOpen={actionModal === 'add' || actionModal === 'edit'} 
        onClose={() => setActionModal(null)} 
        title={actionModal === 'edit' ? `Edit ${activeTab === 'products' ? 'Product' : 'Category'}` : `Add New ${activeTab === 'products' ? 'Product' : 'Category'}`}
      >
        <form className="space-y-4">
          {activeTab === 'products' ? (
            <>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Product Image</label>
                <div className="border-2 border-dashed border-border rounded-xl p-6 flex flex-col items-center justify-center text-center hover:bg-background/50 transition-colors cursor-pointer group">
                  {selectedItem?.image ? (
                    <img src={selectedItem.image} alt="Preview" className="w-20 h-20 object-cover rounded-lg mb-2 border border-border" />
                  ) : (
                    <div className="p-3 bg-primary/10 text-primary rounded-full group-hover:scale-110 transition-transform">
                      <Upload className="w-5 h-5" />
                    </div>
                  )}
                  <p className="mt-3 text-sm font-medium text-text">Click to {selectedItem?.image ? 'change' : 'upload'} image</p>
                  <p className="text-xs text-text-muted mt-1">SVG, PNG, JPG or GIF (max. 5MB)</p>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Product Name</label>
                <input type="text" defaultValue={selectedItem?.name} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="e.g. Wireless Headphones" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-text mb-1">Price Bought</label>
                  <input type="text" defaultValue={selectedItem?.priceBought} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="$50.00" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-text mb-1">Selling Price</label>
                  <input type="text" defaultValue={selectedItem?.price} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="$99.00" />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-text mb-1">Commission</label>
                  <input type="text" defaultValue={selectedItem?.commission} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="10%" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-text mb-1">Stock</label>
                  <input type="number" defaultValue={selectedItem?.stock} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="0" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Category</label>
                <select defaultValue={selectedItem?.category || 'Electronics'} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
                  <option>Electronics</option>
                  <option>Wearables</option>
                  <option>Furniture</option>
                </select>
              </div>
            </>
          ) : (
            <>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Category Image</label>
                <div className="border-2 border-dashed border-border rounded-xl p-6 flex flex-col items-center justify-center text-center hover:bg-background/50 transition-colors cursor-pointer group">
                  <div className="p-3 bg-primary/10 text-primary rounded-full group-hover:scale-110 transition-transform">
                    <Upload className="w-5 h-5" />
                  </div>
                  <p className="mt-3 text-sm font-medium text-text">Click to upload image</p>
                  <p className="text-xs text-text-muted mt-1">SVG, PNG, JPG or GIF (max. 5MB)</p>
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Category Name</label>
                <input type="text" defaultValue={selectedItem?.name} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="e.g. Electronics" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-text mb-1">Parent Category</label>
                  <select className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
                    <option value="">None (Top Level)</option>
                    <option>Electronics</option>
                    <option>Wearables</option>
                    <option>Furniture</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-text mb-1">Initial Status</label>
                  <select defaultValue={selectedItem?.status || 'Active'} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
                    <option>Active</option>
                    <option>Inactive</option>
                  </select>
                </div>
              </div>
            </>
          )}
          <div className="flex justify-end gap-3 pt-4 mt-6 border-t border-border">
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm font-medium hover:bg-background transition-colors">
              Cancel
            </button>
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors">
              {actionModal === 'edit' ? 'Save Changes' : `Save ${activeTab === 'products' ? 'Product' : 'Category'}`}
            </button>
          </div>
        </form>
      </Modal>

      <Modal isOpen={actionModal === 'archive'} onClose={() => setActionModal(null)} title={`Archive ${activeTab === 'products' ? 'Product' : 'Category'}`}>
        <div className="space-y-4">
          <p className="text-sm text-text">Are you sure you want to archive <strong>{selectedItem?.name}</strong>? This will hide it from the marketer application.</p>
          <div className="flex justify-end gap-3 pt-4 mt-6 border-t border-border">
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm font-medium hover:bg-background transition-colors">
              Cancel
            </button>
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 bg-danger text-white rounded-lg text-sm font-medium hover:bg-danger/90 transition-colors">
              Archive
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
