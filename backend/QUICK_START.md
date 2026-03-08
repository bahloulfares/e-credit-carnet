# ProCreditApp Backend - Quick Start Guide

## ⚡ Démarrage Rapide (5 minutes)

### Prérequis
- Node.js >= 18
- MySQL >= 8.0
- npm

### 1️⃣ Cloner et installez

```bash
cd backend
npm install
```

### 2️⃣ Configurer la base de données

```bash
# Créer la base de données et l'utilisateur
mysql -u root -p
CREATE DATABASE procreditapp_db;
CREATE USER 'procreditapp'@'localhost' IDENTIFIED BY 'procreditapp_password';
GRANT ALL PRIVILEGES ON procreditapp_db.* TO 'procreditapp'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3️⃣ Configuration

```bash
# Copier le fichier de configuration
cp .env.example .env

# Les paramètres par défaut fonctionnent déjà:
# DATABASE_URL="mysql://procreditapp:procreditapp_password@localhost:3306/procreditapp_db"
```

### 4️⃣ Initialiser la base de données

```bash
# Exécuter les migrations
npm run prisma:migrate

# Charger des données de test (optionnel)
npm run prisma:seed
```

### 5️⃣ Lancer le serveur

```bash
npm run dev
```

✅ Le serveur est maintenant en cours d'exécution sur `http://localhost:3000`

---

## 🧪 Tester l'API

### Health Check
```bash
curl http://localhost:3000/health
```

### S'inscrire (Créer un compte épicier)
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mon-epicerie@example.com",
    "firstName": "Ahmed",
    "lastName": "Ben Amedi",
    "password": "MaPassword@123",
    "shopName": "Mon Épicerie"
  }'
```

### Se connecter
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "epicier1@procreditapp.com",
    "password": "Epicier@123"
  }'
```

Réponse:
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { ... }
}
```

Copiez le `token` pour le prochain appel.

### Créer un client
```bash
curl -X POST http://localhost:3000/api/clients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_HERE" \
  -d '{
    "firstName": "Mohamed",
    "lastName": "Mansour",
    "phone": "+216 20 123 456",
    "address": "Tunis"
  }'
```

### Lister les clients
```bash
curl http://localhost:3000/api/clients \
  -H "Authorization: Bearer TOKEN_HERE"
```

### Créer une transaction
```bash
curl -X POST http://localhost:3000/api/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_HERE" \
  -d '{
    "clientId": "CLIENT_ID_HERE",
    "type": "CREDIT",
    "amount": 100.50,
    "description": "Achat provisions"
  }'
```

### Dashboard
```bash
curl http://localhost:3000/api/dashboard/stats \
  -H "Authorization: Bearer TOKEN_HERE"
```

---

## 📁 Structure du Projet

```
backend/
├── src/
│   ├── controllers/      # Gestion des requêtes HTTP
│   ├── services/         # Logique métier
│   ├── routes/           # Définition des endpoints
│   ├── middleware/       # Auth, gestion erreurs
│   ├── utils/            # Helpers (JWT, BCrypt, etc)
│   └── index.ts          # Point d'entrée
├── prisma/
│   ├── schema.prisma     # Modèle de données
│   └── seed.ts           # Données de test
├── tests/                # Tests unitaires
├── .env.example          # Configuration exemple
├── package.json          # Dépendances
├── tsconfig.json         # Configuration TypeScript
└── README.md             # Documentation
```

---

## 🔑 Utilisateurs de Test

Après avoir exécuté `npm run prisma:seed`, vous pouvez vous connecter avec:

**Super Admin:**
- Email: `admin@procreditapp.com`
- Mot de passe: `Admin@123`

**Épicier 1:**
- Email: `epicier1@procreditapp.com`
- Mot de passe: `Epicier@123`
- Boutique: Épicerie Ben Ahmed (Tunis)

**Épicier 2:**
- Email: `epicier2@procreditapp.com`
- Mot de passe: `Epicier@123`
- Boutique: Épicerie Khmissa (Sfax)

**5 clients de test + transactions** sont pré-créés pour Épicier 1.

---

## 📚 Documentation Complète

- **README.md** - Présentation générale du projet
- **API_DOCUMENTATION.md** - Documentation détaillée de tous les endpoints
- **DEVELOPMENT_GUIDE.md** - Guide pour développer sur le projet
- **DEPLOYMENT_GUIDE.md** - Instructions pour déployer en production

---

## 🛠️ Commandes Utiles

```bash
# Développement
npm run dev              # Démarrer avec hot reload

# Build
npm run build            # Compiler TypeScript
npm start                # Démarrer en production

# Base de données
npm run prisma:migrate   # Exécuter les migrations
npm run prisma:seed      # Charger données de test
npm run prisma:studio    # Interface graphique Prisma

# Tests
npm test                 # Exécuter les tests
npm run test:watch       # Mode surveillance
npm run test:coverage    # Rapport de couverture

# Qualité du code
npm run lint             # Vérifier les erreurs
npm run format           # Formater le code
```

---

## 🐳 Utiliser Docker (Optionnel)

```bash
# Lancer MySQL + Backend avec Docker Compose
docker-compose up -d

# Vérifier les logs
docker-compose logs -f app

# Arrêter les services
docker-compose down
```

---

## ⚠️ Problèmes Courants

### Port 3000 déjà utilisé
```bash
lsof -i :3000
kill -9 <PID>
```

### Impossible de se connecter à MySQL
```bash
# Vérifier que MySQL est en cours d'exécution
mysql -u root -p

# Vérifier la DATABASE_URL dans .env
echo $DATABASE_URL
```

### Prisma Client outdated
```bash
npx prisma generate
npm install
```

---

## 🚀 Prochaines Étapes

### Court terme (cette semaine)
- [ ] Tester tous les endpoints avec Postman
- [ ] Configurer le frontend Flutter pour consommer l'API
- [ ] Ajouter la validation des entrées avec `express-validator`
- [ ] Implémenter le rate limiting pour la sécurité

### Moyen terme (cette semaine)
- [ ] Ajouter plus de tests unitaires (target: > 80% coverage)
- [ ] Configurer le logging (Winston)
- [ ] Implémenter le monitoring (Prometheus/Grafana)
- [ ] Ajouter les tests d'intégration avec TestContainers

### Long terme (avant production)
- [ ] Configurer CI/CD avec GitHub Actions
- [ ] Préparer le déploiement Docker
- [ ] Configuration de Nginx et SSL (Let's Encrypt)
- [ ] Backup automatique de la base de données
- [ ] Monitoring et alertes en production

---

## 📞 Support

Besoin d'aide?
- Consultez les guides de documentation
- Vérifiez les logs: `docker-compose logs -f app`
- Contactez: support@procreditapp.com

---

**Bon développement! 🎉**
