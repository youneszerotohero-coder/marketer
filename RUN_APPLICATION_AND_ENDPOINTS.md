# Run Application And Test Endpoints

This project contains three main parts:

- `backend`: Laravel 11 API with PostgreSQL, JWT auth, and Swagger docs.
- `admin`: React + TypeScript + Vite admin dashboard.
- `afiliat_mobile`: Flutter mobile app for marketers.

## 1. Backend

From the backend folder:

```bash
cd marketer/backend
docker compose up --build
```

The API will be available at:

```txt
http://localhost:8005/api
```

Swagger UI:

```txt
http://localhost:8005/api/documentation
```

PostgreSQL is exposed on host port `5433`:

```txt
database: marketer
username: marketer
password: secret
container: marketer-postgress
```

If you need to reset and seed the database:

```bash
docker exec -it marketer-backend php artisan migrate:fresh --seed
```

Seed accounts:

```txt
admin@marketer.local / password
confirmatrice@marketer.local / password
marketer@marketer.local / password
```

## 2. Admin Frontend

From the admin folder:

```bash
cd marketer/admin
npm install
npm run dev
```

The admin client uses this API URL by default:

```txt
http://localhost:8005/api
```

You can override it with:

```bash
VITE_API_BASE_URL=http://localhost:8005/api npm run dev
```

## 3. Flutter Mobile App

From the mobile folder:

```bash
cd marketer/afiliat_mobile
flutter pub get
flutter run
```

For Android emulator access to a backend running on your machine, use `10.0.2.2` instead of `localhost` if needed.

## 4. Quick Curl Setup

Install `jq` if you want to copy these token commands directly.

```bash
BASE="http://localhost:8005/api"

ADMIN_TOKEN=$(curl -s -X POST "$BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@marketer.local","password":"password"}' | jq -r '.access_token')

MARKETER_LOGIN=$(curl -s -X POST "$BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"email":"marketer@marketer.local","password":"password"}')

MARKETER_TOKEN=$(echo "$MARKETER_LOGIN" | jq -r '.access_token')
REFRESH_TOKEN=$(echo "$MARKETER_LOGIN" | jq -r '.refresh_token')

CONFIRMATRICE_TOKEN=$(curl -s -X POST "$BASE/auth/login" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"email":"confirmatrice@marketer.local","password":"password"}' | jq -r '.access_token')
```

Shared headers:

```bash
-H "Accept: application/json"
-H "Content-Type: application/json"
-H "Authorization: Bearer $TOKEN"
```

## 5. Endpoint Names And Methods

### Auth

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| Register marketer | `POST` | `/auth/register` | No | Create a marketer account |
| Login | `POST` | `/auth/login` | No | Get access and refresh tokens |
| Refresh token | `POST` | `/auth/refresh` | No | Exchange refresh token for new tokens |
| Current user | `GET` | `/me` | Any logged user | Check current token |
| Logout | `POST` | `/auth/logout` | Any logged user | Invalidate current token |

### Product Catalog

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| List active products | `GET` | `/products` | Any logged user | Browse catalog |
| Show product | `GET` | `/products/{product}` | Any logged user | View product details |

### Marketer Orders

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| List own orders | `GET` | `/orders` | Marketer | View marketer orders |
| Create order | `POST` | `/orders` | Marketer | Submit customer order |
| Show own order | `GET` | `/orders/{order}` | Marketer | View one marketer order |

### Marketer Wallet

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| Wallet summary | `GET` | `/wallet` | Marketer | Check available balance |
| Wallet transactions | `GET` | `/wallet/transactions` | Marketer | List wallet history |
| Request withdrawal | `POST` | `/wallet/withdraw` | Marketer | Create payout request |

### Confirmatrice Workflow

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| List assigned/open orders | `GET` | `/confirmatrice/orders` | Confirmatrice or admin | View pending/confirmed orders |
| Update order status | `PATCH` | `/confirmatrice/orders/{order}/status` | Confirmatrice or admin | Confirm/cancel order |

### Admin Dashboard

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| Dashboard stats | `GET` | `/admin/dashboard` | Admin | Check totals and KPIs |

### Admin Users

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| List users | `GET` | `/admin/users` | Admin | Filter users by role/status |
| Create user | `POST` | `/admin/users` | Admin | Add admin, marketer, or confirmatrice |
| Update user | `PATCH` | `/admin/users/{user}` | Admin | Suspend, activate, or edit user |

### Admin Orders

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| List all orders | `GET` | `/admin/orders` | Admin | Filter all orders |
| Update order status | `PATCH` | `/admin/orders/{order}/status` | Admin | Move order through workflow |
| Assign confirmatrice | `PATCH` | `/admin/orders/{order}/assign-confirmatrice` | Admin | Assign order to confirmatrice |

### Admin Products

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| List products | `GET` | `/admin/products` | Admin | View all products |
| Create product | `POST` | `/admin/products` | Admin | Create product with variants |
| Update product | `PATCH` | `/admin/products/{product}` | Admin | Edit product fields/status |
| Archive product | `PATCH` | `/admin/products/{product}/archive` | Admin | Archive product |
| Update variant | `PATCH` | `/admin/variants/{variant}` | Admin | Edit stock, price, commission, status |

### Admin Wallet Withdrawals

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| List withdrawals | `GET` | `/admin/wallet/withdrawals` | Admin | Filter payout requests |
| Approve withdrawal | `PATCH` | `/admin/wallet/withdrawals/{withdrawal}/approve` | Admin | Approve payout request |
| Reject withdrawal | `PATCH` | `/admin/wallet/withdrawals/{withdrawal}/reject` | Admin | Reject payout request |

### Admin Settings

| Name | Method | Endpoint | Auth | Quick test |
| --- | --- | --- | --- | --- |
| List settings | `GET` | `/admin/settings` | Admin | Read app settings |
| Update settings | `PATCH` | `/admin/settings` | Admin | Upsert app settings |

## 6. Fast Endpoint Smoke Tests

Use these after exporting tokens from section 4.

```bash
curl -s "$BASE/me" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $MARKETER_TOKEN"

curl -s "$BASE/products?per_page=5" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $MARKETER_TOKEN"

curl -s "$BASE/orders?per_page=5" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $MARKETER_TOKEN"

curl -s "$BASE/wallet" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $MARKETER_TOKEN"

curl -s "$BASE/confirmatrice/orders?per_page=5" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $CONFIRMATRICE_TOKEN"

curl -s "$BASE/admin/dashboard" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

curl -s "$BASE/admin/users?per_page=5" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

curl -s "$BASE/admin/orders?per_page=5" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

curl -s "$BASE/admin/products?per_page=5" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

curl -s "$BASE/admin/settings" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

## 7. Useful Test Payloads

Create an order:

```bash
curl -X POST "$BASE/orders" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MARKETER_TOKEN" \
  -d '{
    "client_name":"Client Test",
    "client_phone":"0555123456",
    "wilaya":"Alger",
    "commune":"Bab Ezzouar",
    "address":"Street 1",
    "items":[{"product_variant_id":1,"quantity":1}],
    "notes":"Test order"
  }'
```

Update order status as admin:

```bash
curl -X PATCH "$BASE/admin/orders/1/status" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"status":"confirmed","notes":"Confirmed by admin"}'
```

Create a product as admin:

```bash
curl -X POST "$BASE/admin/products" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "category_id":null,
    "brand_id":null,
    "name":"Test Product",
    "description":"Created from curl",
    "main_image_path":null,
    "variants":[{
      "sku":"TEST-SKU-001",
      "purchase_price":1000,
      "sale_price":1500,
      "commission_value":150,
      "commission_type":"fixed",
      "stock":10
    }]
  }'
```

Request a withdrawal as marketer:

```bash
curl -X POST "$BASE/wallet/withdraw" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MARKETER_TOKEN" \
  -d '{
    "amount":100,
    "payment_method":"ccp",
    "payout_details":{"account":"1234567890","name":"Test Marketer"}
  }'
```
