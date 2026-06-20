# Récapitulatif de l'Intégration Backend ↔ Frontends

Ce document résume l'ensemble des travaux et modifications apportés pour connecter le Backend Laravel 11 avec le Panel Admin React et l'Application Mobile Flutter.

---

## 1. Backend Laravel (API)

### 🔧 Compatibilité & Configuration
* **Compatibilité SQLite** : Modification des requêtes de recherche dans `ProductController.php` pour utiliser `like` au lieu de `ilike` (qui n'est pas supporté par SQLite).
* **CORS** : Configuration dans `config/cors.php` pour autoriser l'accès depuis le panel admin (`http://localhost:5173`) et l'application mobile en local.

### 🛣️ Nouveaux Endpoints & Contrôleurs
* **Gestion des Catégories** :
  * `CategoryController.php` (Public) : Endpoint `GET /api/categories` pour alimenter les catégories de la boutique mobile.
  * `CategoryAdminController.php` (Admin) : CRUD complet `/api/admin/categories` pour permettre aux administrateurs de créer, lister et modifier des catégories.
* **Gestion des Marques** :
  * `BrandController.php` (Public) : Endpoint `GET /api/brands` pour lister les marques.
* **Statistiques Marketer** :
  * `MarketerStatsController.php` (Marketer) : Endpoint `GET /api/marketer/stats` retournant les données réelles de vente (commandes livrées, en cours, échouées, taux de livraison, et solde de commission actuel).
* **Dashboard Admin** :
  * Envoi dynamique du compteur des demandes de retraits en attente (`pending_payouts_count`) pour le dashboard d'administration.

---

## 2. Panel Admin (React + Vite)

### 🔐 Authentification & Requêtes API
* **Service API Centralisé** : Création de `api.ts` utilisant Axios avec intercepteurs automatiques pour :
  * Injecter l'en-tête `Authorization: Bearer <JWT_TOKEN>` à chaque requête.
  * Gérer les expirations de token (redirection automatique vers le login en cas de code `401 Unauthorized`).
* **Page de Connexion** : Création de `LoginPage.tsx` fonctionnelle, connectée à `/api/auth/login`, gérant les sessions utilisateur avec persistance locale du token JWT.
* **Routes Protégées** : Sécurisation de l'application via `App.tsx` pour empêcher l'accès aux pages d'administration sans session valide.

### 💻 Pages Connectées au Backend
* **Tableau de Bord** : Affichage des statistiques de vente en direct (revenus, commandes livrées/échouées, nombre de marketers actifs) à la place des données statiques.
* **Gestion des Marketers** : Liste dynamique des inscrits avec affichage de leur niveau (tier) et possibilité de mettre à jour le tier en temps réel.
* **Gestion des Commandes** : Affichage des commandes en direct, modification de statut en un clic, et attribution des confirmateurs.
* **Gestion des Portefeuilles** : Validation ou rejet direct des demandes de retrait des marketers avec impact immédiat sur leur solde.
* **Gestion des Produits et Catégories** : Intégration de `ManageProducts.tsx` avec les endpoints `/api/admin/products` et `/api/admin/categories` pour visualiser, filtrer et archiver les produits de la base de données.
* **Paramètres (Settings)** : Intégration de `Settings.tsx` avec l'API pour récupérer les administrateurs et les configurations de livraison en temps réel.

---

## 3. Application Mobile Affiliate (Flutter)

### 📦 Dépendances & Services
* **Configuration** : Ajout des packages `http` et `shared_preferences` dans `pubspec.yaml`.
* **Gestionnaire de Requêtes HTTP** : Création de `api_service.dart` pour gérer les appels avec injection automatique du header JWT et gestion propre des erreurs API.
* **Service d'Authentification** : Création de `auth_service.dart` pour gérer l'inscription, la connexion, la déconnexion et la persistance du JWT.

### 📱 Écrans Dynamiques Connectés
* **Splash Screen & Auth** : Vérification automatique du token JWT, et connexion des formulaires Login & Signup avec indicateurs de chargement et retours d'erreurs réels.
* **Boutique (Shop Page)** : Chargement complet et dynamique des catégories et des produits via `GET /api/categories` et `GET /api/products`, avec gestion de l'état de chargement.
* **Détails du Produit** : L'écran récupère les données du produit spécifique via `GET /api/products/{id}` et affiche le titre, le prix, la description, et le stock réels.
* **Création de Commande** : Remplacement de la soumission factice par un véritable appel `POST /api/orders` afin que les commandes saisies atterrissent bien dans l'interface de gestion admin.
* **Page Profil** : Affichage en direct des statistiques (ventes totales, gains, taux de livraison) via `GET /api/marketer/stats`.
* **Page Portefeuille & Commandes** : Historique et données rechargés à chaque ouverture grâce aux endpoints `wallet` et `orders`.


---

## 4. Modifications 

### ✅ Task 1 — Intégration ZR Express API
- Insertion des credentials ZR Express dans la table `settings` (DB) :
  - `delivery.provider` = `zr_express`
  - `zr_express_tenant_id`
  - `zr_express_secret_key`
  - `zr_express_base_url`
  - `zr_express_api_version`
- Le gateway `ZrExpressGateway.php` lit ces credentials depuis la DB via le modèle `Setting`.
- Le système bascule automatiquement entre Mock et ZR via `AppServiceProvider.php`.
- **Note :** L'API ZR Express retourne une erreur 525 (SSL down côté ZR). Le système fonctionne en mode fallback (tarifs hardcodés) jusqu'à résolution côté ZR Express.

### ✅ Task 2 — Ne pas pénaliser le marketer si produit cassé
- Migration ajoutée : `add_return_reason_to_orders_table`
  - Nouveau champ `return_reason` (nullable) sur la table `orders`
  - Valeurs possibles : `customer_refused`, `broken_product`, `wrong_address`, `other`
- `WalletService::createReturnFee()` modifié : si `return_reason === 'broken_product'`, aucune pénalité n'est appliquée.
- `OrderAdminController::updateStatus()` modifié :
  - Accepte le champ `return_reason` dans la validation
  - Sauvegarde `return_reason` uniquement quand le statut est `failed`
- `Order::$fillable` mis à jour pour inclure `return_reason`.

### ✅ Task 3 — Duplication de commande 
- **Backend :** Méthode `duplicate()` ajoutée dans `OrderAdminController.php`
  - Copie tous les champs de la commande originale
  - Génère une nouvelle référence unique
  - Copie tous les `OrderItems` sans décrémenter le stock
  - Route : `POST /api/admin/orders/{order}/duplicate` (admin only)
- **Frontend React :** Bouton "Duplicate" déjà présent dans `OrdersManagement.tsx`
  - Confirmation dialog avant duplication
  - Toast success/error après l'action
  - Refresh automatique de la liste

### ✅ Task 4 — Suppression du hashing + Forgot Password
- **Suppression du hashing :**
  - `User.php` : suppression de `'password' => 'hashed'` dans `casts()`
  - `AuthController::login()` : comparaison directe `$user->password === $credentials['password']`
  - ⚠️ Les mots de passe sont maintenant stockés en plain text (décision client)
- **Forgot Password :**
  - Nouvelle méthode `AuthController::forgotPassword()` : envoie le mot de passe en plain text par email
  - Route publique ajoutée : `POST /api/auth/forgot-password`
  - Email configuré via Mailtrap SMTP (`.env`)
  - **Frontend React :** Bouton "Forgot password?" ajouté dans `LoginPage.tsx` avec un formulaire inline
- **Configuration mail `.env` :**
  - `MAIL_MAILER=smtp`
  - `MAIL_HOST=sandbox.smtp.mailtrap.io`
  - `MAIL_PORT=2525`
  - Credentials Mailtrap configurés