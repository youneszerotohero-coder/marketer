# Spécifications et Conception : Projet Marketer

Ce document décrit en langage naturel les cas d'utilisation, l'architecture des données (classes/entités) et les flux de processus (séquences) pour le projet Marketer, basés sur les spécifications du backend en Laravel 11 et la base de données PostgreSQL. Il inclut les trois rôles principaux : **Admin**, **Confermatrice**, et **Marketer (Vendeur)**.

## 1. Description des Cas d'Utilisation

Cette section détaille les actions que chaque utilisateur peut effectuer sur le système en fonction de son rôle.

### A. Rôle : Marketer / Vendeur (Via l'Application Mobile)
- **S'authentifier :** Le marketer peut créer un compte (Inscription) ou se connecter pour accéder à son espace.
- **Parcourir les produits :** Il peut consulter la liste des produits disponibles, effectuer des recherches, filtrer par catégorie et trier par prix ou popularité.
- **Gérer le panier :** Il peut choisir des variantes de produits (ex: taille, couleur), les ajouter à son panier, modifier les quantités, ou retirer des articles.
- **Créer une commande (Checkout) :** Il saisit les informations de son client (Nom, Téléphone, Wilaya, Commune) pour valider et placer une commande.
- **Suivre les commandes :** Il peut consulter l'historique de ses commandes passées, vérifier leur statut (En attente, Confirmée, Expédiée, Livrée, Annulée) et contacter directement son client.
- **Gérer le portefeuille :** Il a accès à ses statistiques de ventes, peut consulter son solde de commissions, et soumettre des demandes de retrait d'argent (Cash-out).
- **Gérer le profil :** Il peut ajuster les paramètres de l'application (Mode sombre, Langue).

### B. Rôle : Confermatrice (Via le Web Admin Panel)
- **Consulter le Dashboard :** Accès limité aux statistiques de base des commandes.
- **Gérer les commandes :** Son rôle principal est de traiter les nouvelles commandes. Elle consulte la liste, contacte les clients, et met à jour le statut des commandes (par exemple, passage de "En attente" à "Confirmée", puis "Expédiée" et "Livrée").

### C. Rôle : Admin (Via le Web Admin Panel)
- **Consulter le Dashboard :** Accès complet aux analyses financières (Revenus, croissance, inscriptions, etc.).
- **Gérer les produits et catégories :** L'admin peut ajouter, modifier, ou archiver des produits, et structurer les catégories.
- **Gérer les commandes :** Accès global pour superviser, filtrer et modifier le statut de n'importe quelle commande.
- **Gérer les paiements (Retraits) :** L'admin reçoit les demandes de retrait des marketers, les examine, et peut les approuver (ce qui déduit le solde du marketer) ou les rejeter.
- **Gérer les Marketers :** Il peut consulter la liste des vendeurs, analyser leurs performances et modifier leur niveau (Tier).
- **Gérer les Paramètres :** Il configure les frais de livraison globaux et les spécificités par Wilaya, ainsi que les taux de commission.

---

## 2. Dictionnaire des Données (Classes & Entités)

Cette section décrit les tables principales qui seront créées dans PostgreSQL via les modèles Laravel, ainsi que leurs champs et relations.

### 1. Utilisateur (User)
*Gère les accès au système (Admin, Confermatrice, Marketer).*
- **Champs principaux :** ID, Nom complet, Email, Mot de passe, Rôle (Admin, Confermatrice, Marketer), Numéro de téléphone, Dates de création/mise à jour.
- **Relations :** Un Marketer peut avoir plusieurs Commandes et plusieurs Transactions de portefeuille.

### 2. Catégorie (Category)
*Organise les produits.*
- **Champs principaux :** ID, Nom de la catégorie, Image, Catégorie Parente (ID), Statut (Actif, Inactif).
- **Relations :** Peut contenir plusieurs Produits. Peut être liée à d'autres sous-catégories.

### 3. Produit (Product)
*Le catalogue des articles de base.*
- **Champs principaux :** ID, ID Catégorie, Nom du produit, Image principale, Statut (Archivé/Non-archivé).
- **Relations :** Appartient à une Catégorie. Possède plusieurs Variantes de Produit (ProductVariant).

### 3.1. Attribut (Attribute)
*Définit les caractéristiques réutilisables globalement pour toutes les déclinaisons (ex: "Taille", "Couleur").*
- **Champs principaux :** ID, Nom.
- **Relations :** Possède plusieurs Valeurs d'Attribut.

### 3.2. Valeur d'Attribut (AttributeValue)
*Les valeurs spécifiques possibles pour un attribut donné (ex: "S", "M", "L", "Rouge", "Bleu").*
- **Champs principaux :** ID, ID Attribut, Valeur.
- **Relations :** Appartient à un Attribut. Liée à plusieurs Variantes via une table de liaison (Many-to-Many).

### 3.3. Variante de Produit (ProductVariant)
*La déclinaison spécifique et achetable d'un produit (ex: Produit "T-Shirt" -> Variante "Taille M / Couleur Rouge").*
- **Champs principaux :** ID, ID Produit, SKU (Code de référence unique), Prix d'achat, Prix de vente, Commission (valeur ou pourcentage), Stock disponible, Image de la variante.
- **Relations :** Appartient à un Produit. Contient plusieurs Valeurs d'Attribut (via table pivot `product_variant_values`). Liée aux Articles de Commande (OrderItem).

### 4. Commande (Order)
*Les achats effectués par les clients finaux via les Marketers.*
- **Champs principaux :** ID, ID du Marketer, Nom du client final, Téléphone du client, Wilaya, Commune, Sous-total, Frais de livraison, Prix Total, Commission gagnée par le Marketer, Statut (En attente, Confirmée, Expédiée, Livrée, Annulée).
- **Relations :** Appartient à un Marketer. Contient plusieurs Articles de Commande.

### 5. Article de Commande (OrderItem)
*Le détail des articles contenus dans une commande spécifique.*
- **Champs principaux :** ID, ID de la commande, ID de la variante (ProductVariant), Quantité commandée, Prix unitaire au moment de l'achat.
- **Relations :** Appartient à une Commande. Lié à une Variante de Produit précise.

### 6. Transaction de Portefeuille (WalletTransaction)
*Historique financier des vendeurs (Commissions et Retraits).*
- **Champs principaux :** ID, ID du Marketer, Montant, Type (Commission gagnée, Demande de retrait), Statut (En attente, Approuvée, Rejetée), Méthode de paiement (Virement bancaire, CCP, Flexy), Détails du compte de réception.
- **Relations :** Appartient à un Utilisateur (Marketer).

### 7. Paramètre (Setting)
*Configuration globale du système (Frais de livraison, surtaxes par wilaya, etc.).*
- **Champs principaux :** ID, Clé (ex: `frais_livraison_base`, `commission_tier_pro`), Valeur.

---

## 3. Déroulement des Processus (Séquences d'actions)

Cette section explique étape par étape comment les actions les plus importantes se déroulent entre les acteurs, l'application et la base de données.

### Processus A : Création et Traitement d'une Commande
1. **Initiation :** Le client final choisit un produit et communique ses informations au Marketer.
2. **Ajout au panier :** Le Marketer ouvre l'application mobile, ajoute le produit dans son panier et se rend sur la page de Checkout.
3. **Validation :** Il saisit les informations du client (Nom, Tél, Wilaya) et clique sur "Commander".
4. **Sauvegarde (Backend) :** L'application envoie les données à l'API Laravel (`POST /api/orders`). Le backend vérifie le stock, calcule les totaux et enregistre la commande dans PostgreSQL avec le statut "En attente". Une notification de succès s'affiche sur le téléphone du Marketer.
5. **Prise en charge (Admin Panel) :** La Confermatrice (ou l'Admin) se connecte au tableau de bord web et consulte la liste des nouvelles commandes.
6. **Confirmation :** La Confermatrice appelle le client pour valider l'achat, puis change le statut de la commande en "Confirmée" (`PATCH /api/admin/orders/{id}/status`).
7. **Livraison et Commission :** Une fois le colis expédié et arrivé à destination, le statut est passé à "Livrée". **À ce moment précis**, le backend Laravel génère automatiquement une nouvelle transaction financière (Commission) et l'ajoute au portefeuille du Marketer.

### Processus B : Demande de Retrait d'Argent (Cash-out)
1. **Demande :** Le Marketer consulte ses gains dans l'application mobile. Il saisit un montant et ses coordonnées bancaires (ou CCP), puis valide.
2. **Enregistrement :** L'API Laravel reçoit la demande (`POST /api/wallet/withdraw`) et crée une ligne de transaction avec le statut "En attente".
3. **Vérification :** L'Admin voit cette nouvelle demande apparaître sur le panel web, dans la section "Payouts".
4. **Approbation :** L'Admin vérifie la validité. S'il approuve la demande, il clique sur "Approuver". Le backend Laravel met à jour le statut de la transaction en "Approuvée" et déduit officiellement le montant du solde disponible du Marketer.
