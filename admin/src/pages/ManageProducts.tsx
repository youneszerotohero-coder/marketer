import React, { useState, useEffect } from 'react';
import { Search, Plus, Edit, Archive, LayoutGrid, Upload, X, Star } from 'lucide-react';
import { Modal } from '../components/ui/Modal';
import api, { STORAGE_URL } from '../services/api';

export const ManageProducts: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'products' | 'categories'>('products');
  const [actionModal, setActionModal] = useState<'add' | 'edit' | 'archive' | null>(null);
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [productsPage, setProductsPage] = useState(1);
  const [productsMeta, setProductsMeta] = useState<any>(null);
  const [categoriesPage, setCategoriesPage] = useState(1);
  const [categoriesMeta, setCategoriesMeta] = useState<any>(null);

  const [productsList, setProductsList] = useState<any[]>([]);
  const [categoriesList, setCategoriesList] = useState<any[]>([]);
  const [allCategories, setAllCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  
  const [productImages, setProductImages] = useState<any[]>([]);
  const [deletedImages, setDeletedImages] = useState<number[]>([]);
  const [productVariants, setProductVariants] = useState<any[]>([]);
  const [categoryImageDeleted, setCategoryImageDeleted] = useState(false);
  const [categoryImagePreview, setCategoryImagePreview] = useState<string | null>(null);
  const [categoryImageFile, setCategoryImageFile] = useState<File | null>(null);

  useEffect(() => {
    api.get('/admin/categories').then(res => setAllCategories(res.data.data || res.data));
  }, []);

  useEffect(() => {
    fetchData(1, false);
  }, [activeTab, search, categoryFilter]);

  const fetchData = async (p = 1, append = false) => {
    setLoading(true);
    try {
      if (activeTab === 'products') {
        const params = new URLSearchParams();
        if (search) params.append('search', search);
        if (categoryFilter) params.append('category_id', categoryFilter);
        params.append('page', p.toString());
        params.append('per_page', '20');
        const response = await api.get(`/admin/products?${params.toString()}`);
        const data = response.data.data || response.data;
        setProductsList(prev => append ? [...prev, ...data] : data);
        setProductsPage(p);
        const totalPages = response.data.last_page || response.data.meta?.last_page || 1;
        setProductsMeta({ last_page: totalPages, current_page: p });
      } else {
        const params = new URLSearchParams();
        if (search) params.append('search', search);
        params.append('page', p.toString());
        params.append('per_page', '20');
        const response = await api.get(`/admin/categories?${params.toString()}`);
        const data = response.data.data || response.data;
        setCategoriesList(prev => append ? [...prev, ...data] : data);
        setCategoriesPage(p);
        const totalPages = response.data.last_page || response.data.meta?.last_page || 1;
        setCategoriesMeta({ last_page: totalPages, current_page: p });
      }
    } catch (error) {
      console.error('Failed to fetch data:', error);
    } finally {
      setLoading(false);
    }
  };

  const visibleProducts = productsList;
  const visibleCategories = categoriesList;

  const openModal = (type: any, item?: any) => {
    setSelectedItem(item || null);
    setActionModal(type);
    
    if (type === 'edit' && item) {
      if (activeTab === 'products') {
        const existingImages = (item.images || []).map((img: any) => ({
          id: img.id,
          path: img.path,
          isMain: item.main_image_path === img.path,
          preview: img.path.startsWith('http') ? img.path : `${STORAGE_URL}/${img.path}`
        }));

        if (existingImages.length === 0 && item.main_image_path) {
          existingImages.push({
            id: undefined, // Mock images don't have an ID
            path: item.main_image_path,
            isMain: true,
            preview: item.main_image_path.startsWith('http') ? item.main_image_path : `${STORAGE_URL}/${item.main_image_path}`
          });
        }

        setProductImages(existingImages);
        setDeletedImages([]);

        if (item.variants && item.variants.length > 0) {
          setProductVariants(item.variants.filter((v: any) => v.status !== 'archived'));
        } else {
          setProductVariants([{ sku: `P-${Date.now()}`, purchase_price: '', sale_price: '', commission_value: '', commission_type: 'fixed' }]);
        }
      } else {
        setCategoryImagePreview(item.image_path ? (item.image_path.startsWith('http') ? item.image_path : `${STORAGE_URL}/${item.image_path}`) : null);
        setCategoryImageDeleted(false);
        setCategoryImageFile(null);
      }
    } else {
      setProductImages([]);
      setDeletedImages([]);
      setProductVariants([{ sku: `P-${Date.now()}`, purchase_price: '', sale_price: '', commission_value: '', commission_type: 'fixed' }]);
      setCategoryImagePreview(null);
      setCategoryImageDeleted(false);
      setCategoryImageFile(null);
    }
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const newFiles = Array.from(e.target.files).map((file, idx) => ({
        file,
        isMain: productImages.filter(i => !i.isDeleted).length === 0 && idx === 0,
        preview: URL.createObjectURL(file)
      }));
      setProductImages(prev => [...prev, ...newFiles]);
    }
  };

  const deleteImage = (idx: number) => {
    setProductImages(prev => {
      const newArr = [...prev];
      if (newArr[idx].id) {
        newArr[idx].isDeleted = true;
        setDeletedImages(d => [...d, newArr[idx].id!]);
      } else {
        newArr.splice(idx, 1);
      }
      return newArr;
    });
  };

  const setMainImage = (idx: number) => {
    setProductImages(prev => prev.map((img, i) => ({ ...img, isMain: i === idx })));
  };

  const handleCategoryImgChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setCategoryImageFile(e.target.files[0]);
      setCategoryImagePreview(URL.createObjectURL(e.target.files[0]));
      setCategoryImageDeleted(false);
    }
  };

  const handleArchive = async () => {
    if (!selectedItem) return;
    try {
      if (activeTab === 'products') {
        await api.patch(`/admin/products/${selectedItem.id}/archive`);
      } else {
        // Categories typically deleted
        await api.delete(`/admin/categories/${selectedItem.id}`);
      }
      setActionModal(null);
      fetchData();
    } catch (error) {
      console.error('Failed to archive:', error);
    }
  };

  const handleSave = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    
    if (activeTab === 'products') {
      formData.delete('images[]'); // Remove any native file inputs as we manage them manually
      
      deletedImages.forEach(id => formData.append('deleted_images[]', id.toString()));
      
      const newImages = productImages.filter(img => !img.isDeleted && img.file);
      newImages.forEach(img => formData.append('images[]', img.file!));
      
      const mainImg = productImages.find(img => !img.isDeleted && img.isMain);
      if (mainImg) {
        if (mainImg.id) {
          formData.append('main_image_id', mainImg.id.toString());
        } else if (mainImg.file) {
           const idx = newImages.indexOf(mainImg);
           if (idx !== -1) formData.append('main_image_index', idx.toString());
        }
      }
    } else {
      if (categoryImageFile && !categoryImageDeleted) {
        formData.append('image', categoryImageFile);
      }
    }

    try {
      const token = localStorage.getItem('access_token');
      const baseUrl = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';
      let url = '';

      if (activeTab === 'products') {
        url = actionModal === 'add' ? `${baseUrl}/admin/products` : `${baseUrl}/admin/products/${selectedItem.id}?_method=PATCH`;
      } else {
        url = actionModal === 'add' ? `${baseUrl}/admin/categories` : `${baseUrl}/admin/categories/${selectedItem.id}?_method=PATCH`;
      }

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Accept': 'application/json'
        },
        body: formData
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw { response: { data: errorData } };
      }

      setActionModal(null);
      fetchData();
    } catch (error: any) {
      console.error('Failed to save:', error);
      if (error.response?.data?.errors) {
        alert('Validation Error:\n' + JSON.stringify(error.response.data.errors, null, 2));
      } else {
        alert('An error occurred. Check console.');
      }
    }
  };

  const getProductPrice = (product: any) => {
    if (product.variants && product.variants.length > 0) {
      return `$${product.variants[0].sale_price}`;
    }
    return 'N/A';
  };

  const getProductCommission = (product: any) => {
    if (product.variants && product.variants.length > 0) {
      return `$${product.variants[0].commission_value}`;
    }
    return 'N/A';
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
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search by product name, SKU or brand..." 
                className="w-full pl-10 pr-4 py-2 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary transition-colors"
              />
            </div>
            <select 
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="flex items-center gap-2 px-4 py-2 bg-surface border border-border rounded-lg text-sm font-medium focus:outline-none focus:border-primary transition-colors"
            >
              <option value="">All Categories</option>
              {allCategories.map(cat => (
                <option key={cat.id} value={cat.id}>{cat.name}</option>
              ))}
            </select>
          </div>
          
          {loading ? (
            <div className="flex justify-center p-8">
              <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary border-r-2 border-transparent"></div>
            </div>
          ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider">
                  <th className="p-4 font-medium">Product</th>
                  <th className="p-4 font-medium">Category & Brand</th>
                  <th className="p-4 font-medium">Price</th>
                  <th className="p-4 font-medium">Commission</th>
                  <th className="p-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {visibleProducts.map((product) => (
                  <tr key={product.id} className="group hover:bg-surface-hover transition-colors">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        {product.main_image_path ? (
                          <img src={product.main_image_path.startsWith('http') ? product.main_image_path : `${STORAGE_URL}/${product.main_image_path}`} alt={product.name} className="w-10 h-10 rounded-lg object-cover border border-border" />
                        ) : (
                          <div className="w-10 h-10 rounded-lg bg-background flex items-center justify-center border border-border">
                            <LayoutGrid className="w-5 h-5 text-text-muted" />
                          </div>
                        )}
                        <div>
                          <p className="text-sm font-semibold text-text line-clamp-1">{product.name}</p>
                        </div>
                      </div>
                    </td>
                    <td className="p-4">
                      <p className="text-sm text-text">{product.category?.name || 'N/A'}</p>
                      <p className="text-xs text-text-muted">{product.brand?.name || 'N/A'}</p>
                    </td>
                    <td className="p-4 text-sm font-bold text-text">{getProductPrice(product)}</td>
                    <td className="p-4 text-sm font-medium text-success">{getProductCommission(product)}</td>
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
                {visibleProducts.length === 0 && (
                  <tr>
                    <td colSpan={5} className="p-4 text-center text-text-muted">No products found.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
          )}

          {productsMeta && productsMeta.last_page > productsPage && (
            <div className="p-4 border-t border-border flex justify-center bg-background/20">
              <button 
                onClick={() => fetchData(productsPage + 1, true)}
                className="px-5 py-2 border border-border bg-surface text-text hover:bg-background text-sm font-semibold rounded-xl transition-all duration-200 cursor-pointer shadow-sm hover:scale-102 flex items-center gap-2"
              >
                {loading && <div className="animate-spin rounded-full h-4 w-4 border-t-2 border-primary border-r-2 border-transparent"></div>}
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
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search categories..." 
                className="w-full pl-10 pr-4 py-2 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary transition-colors"
              />
            </div>
          </div>
          
          {loading ? (
            <div className="flex justify-center p-8">
              <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary border-r-2 border-transparent"></div>
            </div>
          ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-background/50 text-text-muted text-xs uppercase tracking-wider">
                  <th className="p-4 font-medium">Category Name</th>
                  <th className="p-4 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {visibleCategories.map((category) => (
                  <tr key={category.id} className="hover:bg-background/50 transition-colors group">
                    <td className="p-4">
                      <div className="flex items-center gap-3">
                        {category.image_path ? (
                          <img src={category.image_path.startsWith('http') ? category.image_path : `${STORAGE_URL}/${category.image_path}`} alt={category.name} className="w-10 h-10 rounded-xl object-cover border border-border" />
                        ) : (
                          <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary border border-border">
                            <LayoutGrid className="w-5 h-5" />
                          </div>
                        )}
                        <p className="text-sm font-semibold text-text">{category.name}</p>
                      </div>
                    </td>
                    <td className="p-4 text-right">
                      <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button onClick={() => openModal('edit', category)} className="p-1.5 text-text-muted hover:text-blue-500 hover:bg-blue-500/10 rounded-md transition-colors" title="Edit">
                          <Edit className="w-4 h-4" />
                        </button>
                        <button onClick={() => openModal('archive', category)} className="p-1.5 text-text-muted hover:text-danger hover:bg-danger/10 rounded-md transition-colors" title="Delete">
                          <Archive className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {visibleCategories.length === 0 && (
                  <tr>
                    <td colSpan={2} className="p-4 text-center text-text-muted">No categories found.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
          )}

          {categoriesMeta && categoriesMeta.last_page > categoriesPage && (
            <div className="p-4 border-t border-border flex justify-center bg-background/20">
              <button 
                onClick={() => fetchData(categoriesPage + 1, true)}
                className="px-5 py-2 border border-border bg-surface text-text hover:bg-background text-sm font-semibold rounded-xl transition-all duration-200 cursor-pointer shadow-sm hover:scale-102 flex items-center gap-2"
              >
                {loading && <div className="animate-spin rounded-full h-4 w-4 border-t-2 border-primary border-r-2 border-transparent"></div>}
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
        <form className="space-y-4" onSubmit={handleSave}>
          {activeTab === 'products' ? (
            <>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Product Images</label>
                <div className="grid grid-cols-4 gap-4 mb-2">
                  {productImages.map((img, idx) => {
                    if (img.isDeleted) return null;
                    return (
                      <div key={idx} className={`relative rounded-xl border-2 overflow-hidden group ${img.isMain ? 'border-primary' : 'border-border'}`}>
                        <img src={img.preview} className="w-full h-24 object-cover" />
                        <div className="absolute top-1 right-1 flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity bg-black/50 p-1 rounded-lg">
                          <button type="button" onClick={() => setMainImage(idx)} className={`p-1 rounded-md ${img.isMain ? 'text-yellow-400' : 'text-white hover:text-yellow-400'}`}>
                            <Star className="w-4 h-4" fill={img.isMain ? 'currentColor' : 'none'} />
                          </button>
                          <button type="button" onClick={() => deleteImage(idx)} className="p-1 rounded-md text-white hover:text-red-500">
                            <X className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                  <div className="border-2 border-dashed border-border rounded-xl h-24 flex flex-col items-center justify-center text-center hover:bg-background/50 transition-colors cursor-pointer relative">
                    <input type="file" multiple accept="image/*" onChange={handleImageChange} className="absolute inset-0 w-full h-full opacity-0 cursor-pointer" />
                    <Plus className="w-6 h-6 text-text-muted" />
                  </div>
                </div>
                <p className="text-xs text-text-muted">Click on the star to set as main image. Max 5MB per image.</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Product Name</label>
                <input type="text" name="name" defaultValue={selectedItem?.name} required className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="e.g. Wireless Headphones" />
              </div>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Description</label>
                <textarea name="description" defaultValue={selectedItem?.description} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary min-h-[80px]" placeholder="Brief product description..."></textarea>
              </div>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-sm font-bold text-text">Product Variants</h3>
                  <button type="button" onClick={() => setProductVariants([...productVariants, { sku: `P-${Date.now()}-${Math.floor(Math.random()*1000)}`, purchase_price: '', sale_price: '', commission_value: '', commission_type: 'fixed' }])} className="text-xs text-primary hover:underline font-medium">
                    + Add Variant
                  </button>
                </div>
                
                {productVariants.map((v, i) => (
                  <div key={v.sku || i} className="p-4 border border-border rounded-xl bg-background/30 relative">
                    {productVariants.length > 1 && (
                      <button type="button" onClick={() => setProductVariants(productVariants.filter((_, idx) => idx !== i))} className="absolute top-2 right-2 p-1 text-danger hover:bg-danger/10 rounded-md">
                        <X className="w-4 h-4" />
                      </button>
                    )}
                    <div className="grid grid-cols-2 gap-4">
                      <div className="col-span-2 sm:col-span-1">
                        <label className="block text-xs font-medium text-text mb-1">SKU / Option (e.g. RED-M)</label>
                        <input type="text" name={`variants[${i}][sku]`} defaultValue={v.sku} required className="w-full px-3 py-1.5 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="e.g. RED-M" />
                      </div>
                      <div>
                        <label className="block text-xs font-medium text-text mb-1">Purchase Price</label>
                        <input type="number" step="0.01" name={`variants[${i}][purchase_price]`} defaultValue={v.purchase_price} required className="w-full px-3 py-1.5 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="50.00" />
                      </div>
                      <div>
                        <label className="block text-xs font-medium text-text mb-1">Selling Price</label>
                        <input type="number" step="0.01" name={`variants[${i}][sale_price]`} defaultValue={v.sale_price} required className="w-full px-3 py-1.5 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="99.00" />
                      </div>
                      <div>
                        <label className="block text-xs font-medium text-text mb-1">Commission</label>
                        <input type="number" step="0.01" name={`variants[${i}][commission_value]`} defaultValue={v.commission_value} required className="w-full px-3 py-1.5 bg-surface border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="10" />
                        <input type="hidden" name={`variants[${i}][commission_type]`} value="fixed" />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Category</label>
                <select name="category_id" defaultValue={selectedItem?.category_id || ''} required className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
                  <option value="" disabled>Select Category</option>
                  {allCategories.map(cat => (
                    <option key={cat.id} value={cat.id}>{cat.name}</option>
                  ))}
                </select>
              </div>
            </>
          ) : (
            <>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Category Image</label>
                {categoryImagePreview && !categoryImageDeleted ? (
                  <div className="relative inline-block border-2 border-border rounded-xl overflow-hidden group">
                     <img src={categoryImagePreview} className="w-24 h-24 object-cover" />
                     <button type="button" onClick={() => setCategoryImageDeleted(true)} className="absolute top-1 right-1 p-1 bg-black/50 rounded-md text-white hover:text-red-500 opacity-0 group-hover:opacity-100 transition-opacity">
                        <X className="w-4 h-4" />
                     </button>
                  </div>
                ) : (
                  <div className="border-2 border-dashed border-border rounded-xl p-6 flex flex-col items-center justify-center text-center hover:bg-background/50 transition-colors cursor-pointer group relative">
                    <input type="file" accept="image/*" onChange={handleCategoryImgChange} className="absolute inset-0 w-full h-full opacity-0 cursor-pointer" />
                    <Upload className="w-5 h-5 text-primary" />
                    <p className="mt-3 text-sm font-medium text-text">Click to upload image</p>
                  </div>
                )}
                <input type="hidden" name="delete_image" value={categoryImageDeleted ? '1' : '0'} />
              </div>
              <div>
                <label className="block text-sm font-medium text-text mb-1">Category Name</label>
                <input type="text" name="name" defaultValue={selectedItem?.name} required className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary" placeholder="e.g. Electronics" />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-text mb-1">Parent Category</label>
                  <select name="parent_id" defaultValue={selectedItem?.parent_id || ''} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
                    <option value="">None (Top Level)</option>
                    {allCategories.map(cat => (
                      <option key={cat.id} value={cat.id}>{cat.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-text mb-1">Status</label>
                  <select name="status" defaultValue={selectedItem?.status || 'active'} className="w-full px-3 py-2 bg-background border border-border rounded-lg text-sm focus:outline-none focus:border-primary">
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </select>
                </div>
              </div>
            </>
          )}
          <div className="flex justify-end gap-3 pt-4 mt-6 border-t border-border">
            <button type="button" onClick={() => setActionModal(null)} className="px-4 py-2 border border-border text-text-muted rounded-lg text-sm font-medium hover:bg-background transition-colors">
              Cancel
            </button>
            <button type="submit" className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-medium hover:bg-primary-hover transition-colors">
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
            <button type="button" onClick={handleArchive} className="px-4 py-2 bg-danger text-white rounded-lg text-sm font-medium hover:bg-danger/90 transition-colors">
              Archive
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
