Flutter Mobile App (Marketer Portal)
The mobile app includes fully functional pages with localization support (English/Arabic toggle).

Page 1: Login Screen
Purpose: Authentication portal for Marketers.
Entries:
Email Address (String, Required)
Password (String, Required)
Actions:
"Sign In" button $\rightarrow$ calls POST /api/auth/login. Returns JWT token + User/Marketer profile.
"Sign Up" text link $\rightarrow$ Navigates to Signup Page.
Note: Google authentication has been removed.
Page 2: Signup Screen
Purpose: Registration portal for new Marketers.
Entries:
Full Name (String, Required)
Email Address (String, Required)
Password (String, Required)
Actions:
"Sign Up" button $\rightarrow$ calls POST /api/auth/register. Logs user in automatically and redirects to main dashboard shell.
Page 3: Shop Page (Main Home Tab)
Purpose: Product listing, searching, and filtering.
Required API: GET /api/products (Filters, Search keywords, and sorting parameters).
Entries (Filters popup):
Search query (String, e.g. name or brand)
Category (Select options: All, Electronics, Fashion, Home, Beauty)
Price Range (Min/Max numeric inputs)
Sort By (Enum: Popular, Newest, Price: Low to High, Price: High to Low, Brands)
Actions:
Product Card clicks $\rightarrow$ Navigates to Product Details.
"Buy now" / "Add to Cart" directly from the card.
Page 4: Product Details Screen
Purpose: View single product details, images carousel, and instant client purchase.
Required API: GET /api/products/{id}.
Entries (Client Info inline card):
Full Name (String, Required)
Phone Number (String, Required, without prefix +213)
Wilaya (Dropdown, e.g. '16 - Algiers', '09 - Blida', '31 - Oran')
Commune (Dropdown, e.g. 'Hydra', 'El Biar', 'Bab Ezzouar')
Actions:
"Save All" / Download $\rightarrow$ calls a local function to save/download all image URLs in the carousel to the device.
Quantity Selector $\rightarrow$ increases/decreases order qty.
"Add to Cart" button $\rightarrow$ adds product to local Cart state.
"Buy Now" button $\rightarrow$ redirects directly to checkout form pre-populated with these client entries.
Page 5: Cart Screen
Purpose: Review added products and update quantities.
Entries:
Quantity changes (Numeric, updates local state).
Actions:
"Remove item" (Swipe-to-delete or remove button) $\rightarrow$ updates cart.
"Proceed to Checkout" button $\rightarrow$ Navigates to Order Creation page.
Page 6: Order Creation Form (Checkout)
Purpose: Complete order placement.
Required API: POST /api/orders (Payload contains Client details, selected items with quantities, subtotal, shipping fee, total price, and calculated commission).
Entries:
Full Name (String, Required)
Phone Number (String, Required)
Wilaya (Dropdown)
Commune (Dropdown)
Popups:
"Order Successful" Dialog: Triggered upon API success. Displays a checkmark and the text: "Your order has been placed successfully. You can track its status in the orders page." Clicking "Back to Home" resets the navigation stack.
Page 7: Orders Page
Purpose: Track placed orders and check statuses.
Required API: GET /api/orders (supports filtering by status).
Entries (Status Filter Tabs):
Tabs: All, Pending, Confirmed, Shipping, Delivered, Cancelled
Actions:
"Details" button $\rightarrow$ opens order details/timeline sheet.
"Contact client" button $\rightarrow$ launches Dialer/WhatsApp using client's phone number.
Page 8: Wallet Page
Purpose: View financial analytics, make cash-out requests, and read transactions.
Required API:
GET /api/wallet/summary (balances, charts)
GET /api/wallet/transactions (history)
POST /api/wallet/withdraw (request cash-out)
Entries (Request Withdrawal Form):
Amount to withdraw (Decimal, Required)
Payment method (Enum: Bank Transfer, Flexi)
Account details (String e.g. IBAN or phone number, Required)
Actions:
"Request Withdrawal" submit button $\rightarrow$ triggers POST /api/wallet/withdraw.
Page 9: Profile Screen
Purpose: Track overall performance and adjust application settings.
Required API: GET /api/marketer/stats (Total Sales, Pending, Delivered, Failed, Total Earned Commission).
Entries:
Dark Mode Toggle Switch (Updates local app UI theme context).
Language Toggle Switch (Toggles Arabic/English locale context).
Actions:
"Log Out" button $\rightarrow$ clears auth cache/token and redirects to Login Screen.
3. React Admin Panel (Web)
The web dashboard is used by administrators to manage products, orders, payouts, and marketers.

Page 1: Dashboard Overview
Purpose: Quick analytical overview of the business.
Required API: GET /api/admin/dashboard-stats (Revenue, sales growth, pending payouts, registration metrics).
Page 2: Manage Products
Purpose: Manage active inventory and category structure.
Required API:
GET /api/admin/products, POST /api/admin/products (create), PUT /api/admin/products/{id} (edit), DELETE /api/admin/products/{id} (archive).
GET /api/admin/categories, POST /api/admin/categories (create), PUT /api/admin/categories/{id} (edit).
Popups/Modals:
Add / Edit Product Modal:
Product Image (File Upload $\rightarrow$ multipart form data)
Product Name (String)
Price Bought (Decimal)
Selling Price (Decimal)
Commission (Decimal or Percentage value)
Stock (Integer)
Category (Select option)
Add / Edit Category Modal:
Category Image (File Upload)
Category Name (String)
Parent Category (Select option, Nullable)
Initial Status (Enum: Active, Inactive)
Archive Confirmation Modal:
Confirms hiding the product from the mobile catalog.
Page 3: Orders Management
Purpose: Oversee client orders and update fulfillment status.
Required API:
GET /api/admin/orders (filtering, paging)
PATCH /api/admin/orders/{id}/status (updates status $\rightarrow$ changing to Delivered should credit the marketer's account).
Entries / Actions:
Status Selector (Dropdown options: Pending, Confirmed, Shipping, Delivered, Cancelled).
"Details" popup modal displaying order breakdown, items, and shipping addresses.
Page 4: Wallet & Payout Management
Purpose: Process payout requests made by marketers.
Required API:
GET /api/admin/payouts (withdrawal requests list)
POST /api/admin/payouts/{id}/approve (approves transaction, deducts from marketer balance)
POST /api/admin/payouts/{id}/reject (rejects transaction, reverts pending balance)
Entries / Actions:
Action buttons: "Approve Payout" / "Reject Payout".
Page 5: Manage Marketers
Purpose: Track registered marketers, update profiles, and manage tiers.
Required API:
GET /api/admin/marketers
PATCH /api/admin/marketers/{id}/tier (e.g. promote to Pro Affiliate)
Modals:
View Details Modal: Displays payout history, order history, and active performance charts for the selected marketer.
Page 6: Settings
Purpose: Configure system-wide rates (e.g. shipping fees per Wilaya).
Required API:
GET /api/admin/settings, PUT /api/admin/settings.
Entries:
Global Base Shipping Fee (Decimal)
Tier commissions multipliers (Decimal)
Wilaya-specific shipping surcharge values list.