# Marketer Backend

Laravel 11 API for the Marketer platform.

## Stack

- Laravel 11
- PostgreSQL 16
- JWT access tokens with stored refresh tokens
- L5 Swagger / OpenAPI
- Mock delivery gateway

## Local Docker

```bash
docker compose up --build
```

API:

```txt
http://localhost:8005/api
```

Swagger UI:

```txt
http://localhost:8005/api/documentation
```

PostgreSQL container:

```txt
container_name: marketer-postgress
database: marketer
username: marketer
password: secret
port: 5432
```

## Seed Accounts

```txt
admin@marketer.local / password
confirmatrice@marketer.local / password
marketer@marketer.local / password
```

Run seed manually:

```bash
php artisan migrate:fresh --seed
```

## Main API Areas

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `GET /api/products`
- `POST /api/orders`
- `GET /api/wallet`
- `POST /api/wallet/withdraw`
- `GET /api/admin/dashboard`
- `GET /api/admin/orders`
- `PATCH /api/admin/orders/{order}/status`
- `GET /api/admin/wallet/withdrawals`
- `GET /api/confirmatrice/orders`

## Notes

Queues and Horizon are intentionally not included yet.
The delivery integration is isolated behind `App\Services\Delivery\DeliveryGateway` and currently uses `MockDeliveryGateway`.
