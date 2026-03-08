# ProCreditApp Backend - Guide de Développement

## Introduction

Ce guide fournit les instructions pour développer sur le backend ProCreditApp.

## Architecture

L'application suit une architecture en couches:

```
├── Controllers    → Gère les requêtes HTTP
├── Services       → Logique métier réutilisable
├── Middleware     → Auth, validation, gestion erreurs
├── Routes         → Définition des endpoints
└── Utils          → Helpers, JWT, BCrypt, etc
```

## Convention de Code

### TypeScript
- Mode strict activé
- Typage complet requis
- Pas de `any` non justifié

### Nommage
- **Files**: `camelCase.ts` (ex: `authService.ts`)
- **Classes**: `PascalCase` (ex: `AuthService`)
- **Functions**: `camelCase` (ex: `getUserById`)
- **Constants**: `UPPER_CASE` (ex: `MAX_RETRIES`)
- **Database**: `snake_case` (ex: `total_debt`)

### Exemple de Structure Service

```typescript
import { PrismaClient } from '@prisma/client';
import { ApiError } from '../utils/errors';

const prisma = new PrismaClient();

export class MyService {
  async create(data: any): Promise<any> {
    try {
      // Validation
      if (!data.required) {
        throw new ApiError(400, 'Missing required field');
      }
      
      // Business logic
      const result = await prisma.table.create({ data });
      
      return result;
    } catch (error) {
      // Error handling
      throw error;
    }
  }
}

export default new MyService();
```

## Développement Local

### 1. Environnement

```bash
# Copy et éditer .env
cp .env.example .env

# Variables importantes:
DATABASE_URL=mysql://user:pass@localhost:3306/db
JWT_SECRET=your-secret-key-min-32-chars
NODE_ENV=development
```

### 2. Base de Données

```bash
# Create database
mysql -u root -p < create_db.sql

# Run migrations
npm run prisma:migrate

# Seed data
npm run prisma:seed

# Open Prisma Studio
npm run prisma:studio
```

### 3. Démarrage du serveur

```bash
# Development (hot reload)
npm run dev

# Production
npm run build
npm start
```

### 4. Vérification

```bash
# Health check endpoint
curl http://localhost:3000/health

# Login endpoint
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"epicier1@procreditapp.com","password":"Epicier@123"}'
```

## Tests

### Unit Tests

```bash
# Run tests
npm test

# Watch mode
npm run test:watch

# Coverage report
npm run test:coverage
```

### Structure des Tests

```typescript
// __tests__/services/authService.test.ts
describe('AuthService', () => {
  describe('login', () => {
    it('should login user with valid credentials', async () => {
      const result = await authService.login('email@example.com', 'password');
      expect(result).toHaveProperty('id');
    });

    it('should throw error with invalid credentials', async () => {
      await expect(
        authService.login('email@example.com', 'wrongpassword')
      ).rejects.toThrow();
    });
  });
});
```

### E2E Tests

```bash
# Tests d'intégration (avec vraie DB)
npm test -- --testPathPattern=e2e
```

## Linting & Formatting

```bash
# Lint code
npm run lint

# Fix linting issues
npm run lint -- --fix

# Format code with Prettier
npm run format
```

## Prisma

### Ajouter une table

1. Modifiez `prisma/schema.prisma`
2. Créez une migration:
   ```bash
   npm run prisma:migrate -- --name add_new_table
   ```
3. Le Prisma Client se génère automatiquement

### Exemples Prisma

```typescript
// Create
const user = await prisma.user.create({
  data: { email: 'test@example.com', password: 'hash' }
});

// Read
const user = await prisma.user.findUnique({ where: { id: '123' } });
const users = await prisma.user.findMany({
  where: { role: 'EPICIER' },
  orderBy: { createdAt: 'desc' }
});

// Update
const user = await prisma.user.update({
  where: { id: '123' },
  data: { firstName: 'New' }
});

// Delete (hard)
await prisma.user.delete({ where: { id: '123' } });

// Soft delete
await prisma.user.update({
  where: { id: '123' },
  data: { deletedAt: new Date() }
});

// Relations
const user = await prisma.user.findUnique({
  where: { id: '123' },
  include: { clients: true, transactions: true }
});
```

## Authentification

Le système utilise JWT + BCrypt:

```typescript
// Login flow
const user = await authService.login(email, password);
const token = generateToken({
  id: user.id,
  email: user.email,
  role: user.role
});

// Usage dans les routes protégées
router.get('/protected', authMiddleware, epicierMiddleware, (req, res) => {
  // req.user.id est disponible
});
```

## Gestion des Erreurs

Utilisez `ApiError` personnalisée:

```typescript
if (!user) {
  throw new ApiError(404, 'User not found');
}

if (password.length < 8) {
  throw new ApiError(400, 'Password must be at least 8 characters');
}
```

## Logging

Utilisez Winston logger:

```typescript
import logger from '../utils/logger';

logger.info('User logged in');
logger.warn('Unusual activity detected');
logger.error('Database connection failed', error);
logger.debug('Debug information');
```

## Variables d'Environnement

Structure `.env`:

```env
# Database
DATABASE_URL=mysql://user:pass@localhost:3306/db

# JWT
JWT_SECRET=your-secret-key-min-32-chars
JWT_EXPIRATION=7d

# Application
NODE_ENV=development
PORT=3000
CORS_ORIGIN=http://localhost:3000

# Logging
LOG_LEVEL=debug

# Security
BCRYPT_ROUNDS=10
```

## Performance & Best Practices

### 1. Database Queries
```typescript
// ❌ N+1 problem
const users = await prisma.user.findMany();
for (const user of users) {
  const clients = await prisma.client.findMany({ where: { userId: user.id } });
}

// ✅ Use include
const users = await prisma.user.findMany({
  include: { clients: true }
});

// ✅ Use select pour limiter les données
const users = await prisma.user.findMany({
  select: { id: true, email: true, clients: true }
});
```

### 2. Error Handling
```typescript
// ✅ Async route handler avec try-catch
router.post('/endpoint', async (req, res) => {
  try {
    const result = await service.doSomething();
    res.json(result);
  } catch (error) {
    logger.error('Error:', error);
    res.status(500).json({ error: 'Something went wrong' });
  }
});
```

### 3. Input Validation
```typescript
// ✅ Valider avant utilisation
if (!email || !email.includes('@')) {
  throw new ApiError(400, 'Invalid email');
}

// Ou utiliser express-validator (plus tard)
```

### 4. Rate Limiting (À implémenter)
```typescript
// Installer: npm install express-rate-limit
import rateLimit from 'express-rate-limit';

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

router.post('/auth/login', limiter, (req, res) => { ... });
```

## Sécurité

### Checklist de Sécurité

- [ ] Password hashing avec BCrypt (12 rounds)
- [ ] JWT secrets stockés en variables d'environnement
- [ ] HTTPS/TLS en production
- [ ] CORS configuré correctement
- [ ] SQL injection prévenue (Prisma ORM)
- [ ] XSS protection (helmet)
- [ ] CSRF protection (si applicable)
- [ ] Rate limiting sur les endpoints sensibles
- [ ] Logs des activités sensibles
- [ ] Validation de toutes les entrées utilisateurs

## Déploiement Continu

La CI/CD est configurée via GitHub Actions (`.github/workflows/ci-cd.yml`):

1. **Test**: Exécute les tests linters
2. **Build**: Compile le TypeScript
3. **Docker**: Construit et pousse l'image Docker
4. **Deploy**: Déploie sur le serveur

Pour activer:
1. Créez un dépôt GitHub
2. Ajoutez les secrets:
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`
   - `VPS_HOST`
   - `VPS_SSH_KEY`

## Troubleshooting

### Port déjà utilisé
```bash
lsof -i :3000
kill -9 <PID>
```

### Problèmes de connexion à la Database
```bash
# Vérifier la connexion
mysql -u procreditapp -p procreditapp_db

# Vérifier les variables d'environnement
echo $DATABASE_URL
```

### Prisma Client outdated
```bash
npx prisma generate
npm install
```

### Problèmes de migration
```bash
# Résoudre les conflits
npm run prisma:migrate -- --name recovery

# Réinitialiser (développement)
npx prisma migrate reset
```

## Ressources Utiles

- [Express.js Documentation](https://expressjs.com/)
- [Prisma ORM](https://www.prisma.io/docs/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc7519)
- [OWASP Security](https://owasp.org/)

## Support

Pour questions ou problèmes: support@procreditapp.com

---

Bonne programmation! 🚀
