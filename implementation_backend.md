# Documentation d'Implémentation et Logique Métier

Ce document retrace l'ensemble des fonctionnalités, logiques et modifications apportées à travers le Backend (Laravel), l'Application Mobile (Flutter) et le Panel Admin (React).

---

## 1. Gestion des Commandes et Logique de Stock

### 🔄 Cycle de vie des Commandes
- **Création de commande** : L'API (`OrderController`) valide scrupuleusement les quantités par rapport au stock de la variante spécifique (`ProductVariant`), puis décrémente le stock en temps réel lors de l'achat.
- **Annulation et Échec** :
  - L'observateur `OrderObserver::booted` écoute les changements de statut.
  - Si une commande passe en statut `cancelled` (Annulée) ou `failed` (Retour), le système **réincrémente automatiquement** le stock des produits associés pour les remettre en vente.

### 🚚 Type de Livraison
- **Base de données** : Une migration a été ajoutée pour intégrer le champ `delivery_type` (`home` ou `desk`) à la table `orders`.
- **API & Tarification** :
  - `OrderController` accepte ce paramètre.
  - `DeliveryGateway` et `MockDeliveryGateway` ont été mis à jour pour calculer dynamiquement les frais de port en fonction du type de livraison (une réduction de 200 DZD s'applique sur les livraisons en "Stop Desk").

---

## 2. Portefeuille (Wallet) et Gestion Financière

Toute la gestion financière est centralisée dans le service `WalletService.php` et est entièrement automatisée :

- **Commissions** :
  - Lorsqu'une commande passe au statut `delivered` (Livrée), la commission est automatiquement créditée sur le solde du Marketer (`createCommission`).
  - Si, par erreur, le statut repasse de `delivered` à autre chose, la commission est **immédiatement annulée/révoquée** (`cancelCommission`).
- **Pénalités (Frais de retour)** :
  - Lorsqu'une commande passe au statut `failed` (Retour/Échec de livraison), une pénalité fixe (par défaut 400 DZD) est déduite du solde du Marketer via une transaction de type `return_fee`.
  - **Note importante** : Le statut `cancelled` (Annulée à l'avance) **n'applique pas** de frais de retour.
  - Si l'Admin ou la Confirmatrice corrige une commande de `failed` vers `pending` ou `delivered`, les frais de retour prélevés sont **automatiquement remboursés** (`cancelReturnFee`).

---

## 3. Application Mobile (Flutter)

### 🛒 Panier et Variantes
- **ID de Variante vs Produit** : L'erreur "Stock Insuffisant" (Erreur 422) a été résolue. L'application transmet désormais l'ID exact de la variante (`product_variant_id`) au lieu de l'ID du produit père.
- **Gestion Avancée du Panier (`CartService`)** :
  - Le modèle `CartItemModel` conserve en mémoire toutes les variantes disponibles d'un produit.
  - **Sélecteur de variante** : Depuis le panier ou le formulaire de commande, l'utilisateur peut cliquer sur la variante actuelle pour faire apparaître un menu déroulant dynamique (Bottom Sheet) et changer de taille/couleur sans retourner sur la page produit.
  - **Bouton X** : Ajout de la possibilité de vider un article spécifique du panier.
- **Formulaire de Commande (`OrderCreationForm` & `ProductDetails`)** :
  - Ajout des boutons radios pour le **Type de Livraison** (À Domicile vs Stop Desk).

### 📊 Tableau de Bord (Profil Marketer)
- **Statistiques précises** : Dans le Back-end (`MarketerStatsController`), les statistiques des commandes `failed` et `cancelled` ont été scindées.
- **UI** : La page `ProfilePage` intègre désormais une 5ème carte grise pour afficher spécifiquement les commandes "Annulées" (Cancelled), évitant la confusion avec les retours (Failed).

---

## 4. Panel d'Administration (React)

- **Gestion des Utilisateurs (`Settings.tsx`)** : Ajout du rôle "Marketer" dans la liste déroulante d'ajout/modification d'utilisateurs.
- **Statistiques Globales** : Les interfaces de commandes et gestion des marketers affichent les totaux mis à jour et profitent de la nouvelle logique financière (Portefeuille précis à 100%).

---

## 📝 Ce qu'il reste à faire (Next Steps)

Voici les éléments potentiels restants pour finaliser le projet à 100% :

1. **Expérience Utilisateur (Mobile)** :
   - Ajouter la fonctionnalité de "Swipe / Glisser" entre les images dans la page des détails du produit (Carousel d'images fluide).
2. **Intégration Yalidine Réelle** :
   - Remplacer `MockDeliveryGateway` par la vraie API de Yalidine pour la création des colis, la génération des bordereaux et le suivi en temps réel (Tracking).
3. **Paramétrage Global (Admin)** :
   - Connecter le formulaire de "Settings" (Paramètres) du Panel Admin avec le Back-end pour modifier dynamiquement les frais de retour par défaut (passer de 400 DZD à autre chose sans toucher au code source).
4. **Demandes de Retrait (Payouts)** :
   - Développer complètement le flux de paiement où l'Admin peut marquer un "Retrait" du Marketer comme "Payé" (via CCP/BaridiMob), ce qui actualisera le solde final.
