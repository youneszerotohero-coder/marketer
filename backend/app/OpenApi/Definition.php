<?php

namespace App\OpenApi;

use OpenApi\Attributes as OA;

#[OA\Info(
    version: '0.1.0',
    title: 'Marketer API',
    description: 'Laravel 11 API for auth, products, orders, wallet, admin, confirmatrice workflow, and mock delivery integration.'
)]
#[OA\Server(url: 'http://localhost:8000/api', description: 'Local Docker API')]
#[OA\SecurityScheme(
    securityScheme: 'bearerAuth',
    type: 'http',
    bearerFormat: 'JWT',
    scheme: 'bearer'
)]
class Definition
{
    #[OA\Get(
        path: '/products',
        summary: 'List active products',
        security: [['bearerAuth' => []]],
        tags: ['Products'],
        responses: [
            new OA\Response(response: 200, description: 'Paginated products list'),
            new OA\Response(response: 401, description: 'Unauthenticated'),
        ]
    )]
    public function products(): void
    {
    }

    #[OA\Post(
        path: '/auth/login',
        summary: 'Login and receive access and refresh tokens',
        tags: ['Auth'],
        responses: [
            new OA\Response(response: 200, description: 'Authenticated'),
            new OA\Response(response: 401, description: 'Invalid credentials'),
        ]
    )]
    public function login(): void
    {
    }
}
