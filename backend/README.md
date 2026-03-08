# ProCreditApp Backend

API Backend pour ProCreditApp - Gestion numérique des crédits clients pour épiciers tunisiens.

## Stack Technique

- **Runtime**: Node.js
- **Framework**: Express.js
- **ORM**: Prisma ORM
- **Database**: PostgreSQL (Supabase)
- **Authentication**: JWT + BCrypt
- **Validation**: Express Validator
- **Logging**: Winston

## Installation

### Prérequis
- Node.js >= 18
- PostgreSQL (Supabase ou local)
- npm ou yarn

### Étapes

1. **Cloner et installer les dépendances**
```bash
cd backend
npm install
```

2. **Configurer les variables d'environnement**
```bash
cp .env.example .env
# Éditez .env avec vos paramètres PostgreSQL
```

3. **Initialiser la base de données**
```bash
npm run prisma:migrate
npm run prisma:seed
```

4. **Démarrer le serveur**
```bash
npm run dev
```

Le serveur démarre sur `http://localhost:3000`

## Hébergement gratuit (Render + Supabase + GitHub)

Architecture:

Flutter App (Android) -> API HTTPS (Render) -> PostgreSQL (Supabase)

### 1) Supabase (base de données)
1. Créez un projet Supabase.
2. Récupérez la chaîne de connexion PostgreSQL (URI directe).
3. Ajoutez `sslmode=require` dans `DATABASE_URL`.

Exemple:

`postgresql://postgres:YOUR_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres?sslmode=require`

### 2) Render (backend)
1. Poussez le code sur GitHub.
2. Dans Render, créez un "Blueprint" depuis `render.yaml` (racine repo).
3. Configurez les variables secrètes:
	- `DATABASE_URL` (Supabase)
	- `JWT_SECRET`
	- `CORS_ORIGIN` (URL de l'app Flutter web si besoin, ou domaine API client)
4. Déployez. Le service expose `/health`.

### 3) Flutter (app)
Lancez l'app en pointant vers l'API Render:

```bash
flutter run --dart-define=API_BASE_URL=https://YOUR-RENDER-SERVICE.onrender.com/api
```

Pour build release Android:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-RENDER-SERVICE.onrender.com/api
```

## Structure du Projet

```
backend/
├── config/              # Configuration (database, jwt, etc)
├── src/
│   ├── controllers/     # Logique métier des routes
│   ├── middleware/      # Middlewares Express (auth, validation, etc)
│   ├── routes/         # Définition des routes API
│   ├── services/       # Logique métier réutilisable
│   ├── utils/          # Utilitaires (helpers, validators, etc)
│   └── index.ts        # Point d'entrée
├── prisma/
│   ├── schema.prisma   # Schéma de base de données
│   └── seed.ts         # Données de seed
├── tests/              # Tests unitaires et intégration
├── .env.example        # Variables d'environnement exemple
└── package.json        # Dépendances
```

## API Endpoints

### Authentification
- `POST /api/auth/register` - Inscription épicier
- `POST /api/auth/login` - Connexion
- `POST /api/auth/refresh` - Renouveler JWT token
- `POST /api/auth/logout` - Déconnexion

### Gestion Clients
- `GET /api/clients` - Lister les clients
- `POST /api/clients` - Créer un client
- `GET /api/clients/:id` - Détails client
- `PUT /api/clients/:id` - Modifier client
- `DELETE /api/clients/:id` - Supprimer client

### Transactions
- `GET /api/transactions` - Lister les transactions
- `POST /api/transactions` - Créer une transaction
- `GET /api/transactions/:id` - Détails transaction

### Synchronisation
- `POST /api/sync` - Synchroniser les données offline

### Dashboard
- `GET /api/dashboard/stats` - Statistiques globales

## Authentification

L'API utilise JWT (JSON Web Tokens) pour l'authentification. Incluez le token dans le header:

```
Authorization: Bearer <token>
```

## Base de Données

Les schémas Prisma sont définis dans `prisma/schema.prisma`. Pour générer les migrations:

```bash
npm run prisma:migrate
```

## Tests

```bash
npm test
npm run test:coverage
```

## Développement

Pour le développement avec hot-reload:

```bash
npm run dev
```

## Déploiement

1. Build le projet:
```bash
npm run build
```

2. Déployer le dossier `dist/` sur votre serveur

3. Configurer les variables d'environnement sur le serveur

4. Exécuter les migrations en production:
```bash
npm run prisma:deploy
```

5. Démarrer le serveur:
```bash
npm start
```

## Licence

Propriétaire - ProCreditApp
