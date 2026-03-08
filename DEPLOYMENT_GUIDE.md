# Guide de Déploiement Complet - Application CCNS

## 📋 Table des Matières
1. [Prérequis](#prérequis)
2. [Étape 1 : Préparation du Code](#étape-1--préparation-du-code)
3. [Étape 2 : Déploiement sur GitHub](#étape-2--déploiement-sur-github)
4. [Étape 3 : Configuration Supabase](#étape-3--configuration-supabase)
5. [Étape 4 : Déploiement sur Render](#étape-4--déploiement-sur-render)
6. [Étape 5 : Build APK Production](#étape-5--build-apk-production)
7. [Étape 6 : Distribution aux Clients](#étape-6--distribution-aux-clients)
8. [Vérification et Tests](#vérification-et-tests)
9. [Maintenance](#maintenance)

---

## Prérequis

### Comptes à créer (GRATUITS)
- ✅ Compte GitHub : https://github.com/signup
- ✅ Compte Supabase : https://supabase.com/dashboard
- ✅ Compte Render : https://render.com/register

### Outils installés
- ✅ Git (vérifier : `git --version`)
- ✅ Node.js 20+ (vérifier : `node --version`)
- ✅ Flutter (vérifier : `flutter --version`)

---

## Étape 1 : Préparation du Code

### 1.1 Créer le fichier .gitignore

```bash
cd D:\CCNS\workspace
```

Créer `D:\CCNS\workspace\.gitignore` avec ce contenu :

```
# Node.js
backend/node_modules/
backend/dist/
backend/.env
backend/prisma/.env

# Flutter
front/build/
front/.dart_tool/
front/.flutter-plugins
front/.flutter-plugins-dependencies
front/.packages
front/pubspec.lock

# IDE
.vscode/
.idea/
*.iml

# OS
.DS_Store
Thumbs.db
```

### 1.2 Vérifier le fichier backend/.env.example

Assurez-vous que `backend/.env.example` contient :
![alt text](image.png)
```env
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres?sslmode=require"
JWT_SECRET="votre-secret-jwt-super-long-et-securise-minimum-32-caracteres"
CORS_ORIGIN="*"
NODE_ENV="production"
PORT=3000
```

### 1.3 Tester localement une dernière fois

```bash
# Backend
cd backend
npm install
npm run build

# Flutter
cd ../front
flutter clean
flutter pub get
flutter analyze
```

✅ **Tout doit être sans erreurs avant de continuer**

---

## Étape 2 : Déploiement sur GitHub

### 2.1 Initialiser Git

```bash
cd D:\CCNS\workspace
git init
git config user.name "Votre Nom"
git config user.email "votre@email.com"
```

### 2.2 Premier commit

```bash
git add .
git commit -m "Initial commit - CCNS App"
```

### 2.3 Créer un repository GitHub

1. Aller sur https://github.com/new
2. **Repository name** : `ccns-app` (ou autre nom)
3. **Visibility** : Private (recommandé) ou Public
4. ❌ **NE PAS** cocher "Initialize with README"
5. Cliquer **Create repository**

### 2.4 Pousser le code

GitHub vous donnera des commandes. Utilisez :

```bash
git remote add origin https://github.com/VOTRE_USERNAME/ccns-app.git
git branch -M main
git push -u origin main
```

**Si demandé** : Entrez vos identifiants GitHub ou utilisez un Personal Access Token

✅ **Vérifier** : Rafraîchir la page GitHub, vous devez voir vos fichiers

---

## Étape 3 : Configuration Supabase

### 3.1 Créer un projet Supabase

1. Aller sur https://supabase.com/dashboard
2. Cliquer **New project**
3. Remplir :
   - **Name** : `ccns-production` (ou autre)
   - **Database Password** : `VotreMotDePasseSuper5ecur!se` (**SAUVEGARDER CE MOT DE PASSE**)
   - **Region** : Choisir le plus proche (ex: Europe West)
   - **Pricing Plan** : Free
4. Cliquer **Create new project** (attendre 2-3 minutes)

### 3.2 Récupérer DATABASE_URL

1. Dans votre projet Supabase, aller à **Settings** (icône engrenage en bas à gauche)
2. Cliquer **Database**
3. Scroll vers **Connection string**
4. Sélectionner l'onglet **URI** (ou **Direct connection**)
5. Copier l'URL qui ressemble à :
   ```
   postgresql://postgres.abcdefgh:[YOUR-PASSWORD]@aws-0-eu-west-1.pooler.supabase.com:5432/postgres
   ```
6. **IMPORTANT** : Remplacer `[YOUR-PASSWORD]` par votre mot de passe réel
7. **IMPORTANT** : Ajouter `?sslmode=require` à la fin

**Exemple final** :
```
postgresql://postgres.abcdefgh:VotreMotDePasseSuper5ecur!se@aws-0-eu-west-1.pooler.supabase.com:5432/postgres?sslmode=require
```

✅ **Sauvegardez cette URL** (vous en aurez besoin pour Render)

---

## Étape 4 : Déploiement sur Render

### 4.1 Créer un compte Render

1. Aller sur https://render.com/register
2. **Sign up with GitHub** (recommandé)
3. Autoriser Render à accéder à vos repos

### 4.2 Créer un Blueprint

1. Sur le Dashboard Render, cliquer **New +** → **Blueprint**
2. **Connect a repository** :
   - Si première fois : Cliquer **Configure account** → Sélectionner **Only select repositories** → Choisir `ccns-app`
   - Sinon : Sélectionner directement `ccns-app`
3. Render détectera automatiquement `render.yaml`
4. **Blueprint Name** : Laisser par défaut ou changer
5. Cliquer **Apply**

### 4.3 Configurer les variables d'environnement

Render va créer le service "ccns-backend-api" et demander les secrets :

1. **DATABASE_URL** :
   ```
   postgresql://postgres.abcdefgh:VotreMotDePasseSuper5ecur!se@aws-0-eu-west-1.pooler.supabase.com:5432/postgres?sslmode=require
   ```
   *(l'URL Supabase de l'étape 3.2)*

2. **JWT_SECRET** :
   Générer une clé secrète forte (32+ caractères) :
   ```bash
   # Option 1 : Générer avec Node.js
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   
   # Option 2 : Utiliser un site comme https://randomkeygen.com/
   # Choisir "Fort Knox Passwords" (256-bit)
   ```
   Exemple : `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6`

3. **CORS_ORIGIN** :
   ```
   *
   ```
   *(permet toutes les origines pour simplifier, ou spécifiez votre domaine plus tard)*

4. Cliquer **Apply** ou **Save**

### 4.4 Attendre le déploiement

1. Render va automatiquement :
   - Installer les dépendances (`npm install`)
   - Générer Prisma Client (`npx prisma generate`)
   - Compiler TypeScript (`npm run build`)
   - Exécuter les migrations (`npx prisma migrate deploy`)
   - Lancer le serveur (`npm start`)

2. **Durée** : 3-5 minutes pour le premier déploiement

3. **Suivre les logs** : Cliquer sur le service → Onglet "Logs"

### 4.5 Récupérer l'URL du backend

1. Une fois **"Live"** (pastille verte), copier l'URL en haut :
   ```
   https://ccns-backend-api-abcd.onrender.com
   ```

2. **Tester** : Ouvrir dans un navigateur :
   ```
   https://ccns-backend-api-abcd.onrender.com/health
   ```
   
   Vous devez voir :
   ```json
   {"status":"ok","timestamp":"2026-03-08T..."}
   ```

✅ **Backend déployé avec succès !**

---

## Étape 5 : Build APK Production

### 5.1 Vérifier l'URL du backend

Remplacer `https://ccns-backend-api-abcd.onrender.com` par **votre URL Render réelle**.

### 5.2 Build l'APK

```bash
cd D:\CCNS\workspace\front

# Nettoyer les anciens builds
flutter clean
flutter pub get

# Build APK avec l'URL production
flutter build apk --release --dart-define=API_BASE_URL=https://ccns-backend-api-abcd.onrender.com/api
```

**Durée** : 2-5 minutes

### 5.3 Localiser l'APK

L'APK sera créé ici :
```
D:\CCNS\workspace\front\build\app\outputs\flutter-apk\app-release.apk
```

**Taille** : ~20-50 MB

### 5.4 (Optionnel) Build APK séparé par architecture

Pour des APKs plus légers (recommandé pour distribution) :

```bash
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://ccns-backend-api-abcd.onrender.com/api
```

Ceci créera 3 fichiers :
- `app-armeabi-v7a-release.apk` (~15 MB) - Pour téléphones anciens
- `app-arm64-v8a-release.apk` (~18 MB) - **Pour la majorité des téléphones modernes**
- `app-x86_64-release.apk` (~20 MB) - Pour émulateurs/tablettes

✅ **Utilisez `app-arm64-v8a-release.apk` pour la plupart des clients**

---

## Étape 6 : Distribution aux Clients

### Option A : Distribution Directe (Rapide)

#### 6.1 Via WhatsApp/Telegram/Email

1. Envoyer `app-arm64-v8a-release.apk` directement
2. Instructions pour le client :
   ```
   1. Télécharger le fichier APK
   2. Ouvrir le fichier
   3. Si demandé : Autoriser "Installer des applications inconnues"
   4. Suivre les étapes d'installation
   5. Ouvrir l'app CCNS
   ```

#### 6.2 Via Google Drive

1. Uploader l'APK sur Google Drive
2. Clic droit → Partager → **Anyone with the link**
3. Copier le lien et l'envoyer aux clients

### Option B : Distribution Professionnelle (Recommandé)

#### 6.3 Via GitHub Releases

1. Aller sur votre repo GitHub : `https://github.com/VOTRE_USERNAME/ccns-app`
2. Cliquer **Releases** → **Create a new release**
3. **Tag version** : `v1.0.0`
4. **Release title** : `Version 1.0.0 - Production`
5. **Description** :
   ```markdown
   ## CCNS App - Version 1.0.0
   
   ### Installation
   1. Télécharger `app-arm64-v8a-release.apk`
   2. Installer sur votre téléphone Android
   3. Ouvrir l'application
   
   ### Support
   Contactez-nous : votre@email.com
   ```
6. **Attach binaries** : Glisser-déposer `app-arm64-v8a-release.apk`
7. Cliquer **Publish release**
8. Partager le lien de la release : `https://github.com/VOTRE_USERNAME/ccns-app/releases/tag/v1.0.0`

#### 6.4 Via Firebase App Distribution (Gratuit)

1. Créer un projet Firebase : https://console.firebase.google.com/
2. Ajouter une app Android
3. Installer Firebase CLI :
   ```bash
   npm install -g firebase-tools
   firebase login
   ```
4. Uploader l'APK :
   ```bash
   firebase appdistribution:distribute front/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
     --app FIREBASE_APP_ID \
     --groups "testers" \
     --release-notes "Version 1.0.0"
   ```
5. Les clients reçoivent un email avec lien de téléchargement

### Option C : Google Play Store (Payant - 25$ one-time)

1. Créer compte Google Play Console : https://play.google.com/console
2. Payer frais d'inscription unique : 25 USD
3. Créer une application
4. Uploader l'APK via **Production** ou **Internal Testing**
5. Remplir les informations requises (description, screenshots, etc.)
6. Soumettre pour review (1-7 jours)

---

## Vérification et Tests

### Test 1 : Backend Health Check

```bash
curl https://ccns-backend-api-abcd.onrender.com/health
```

Résultat attendu :
```json
{"status":"ok","timestamp":"2026-03-08T12:34:56.789Z"}
```

### Test 2 : Inscription Test

1. Installer l'APK sur un téléphone
2. Ouvrir l'app
3. Cliquer **S'inscrire**
4. Remplir :
   - **Prénom** : Test
   - **Nom** : User
   - **Téléphone** : 20123456
   - **Nom boutique** : Test Shop
   - **Adresse boutique** : 123 Rue Test
   - **Téléphone boutique** : 71123456
   - **Email** : test@example.com
   - **Mot de passe** : Test123456
5. Cliquer **S'inscrire**
6. ✅ Vous devez arriver sur le Dashboard

### Test 3 : Connexion

1. Se déconnecter
2. Se reconnecter avec :
   - **Email** : test@example.com
   - **Mot de passe** : Test123456
3. ✅ Vous devez arriver sur le Dashboard

### Test 4 : Fonctionnalités

1. **Ajouter un client** : Créer un client test
2. **Ajouter une transaction** : Créer une transaction crédit/paiement
3. **Voir statistiques** : Vérifier que les chiffres se mettent à jour
4. **Profile** : Modifier vos informations

---

## Maintenance

### Déployer une nouvelle version

#### Backend (automatique)

```bash
cd D:\CCNS\workspace

# Faire vos modifications dans backend/
# ...

# Commit et push
git add .
git commit -m "Fix: description de votre changement"
git push origin main
```

✅ Render redéploie automatiquement après chaque push (2-3 min)

#### Frontend

```bash
cd D:\CCNS\workspace\front

# Faire vos modifications
# ...

# Incrémenter version dans pubspec.yaml
# version: 1.0.0+1 → 1.0.1+2

# Rebuild APK
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://ccns-backend-api-abcd.onrender.com/api

# Distribuer le nouveau APK aux clients
```

### Voir les logs Render

1. Dashboard Render → Votre service
2. Onglet **Logs** → Voir les erreurs en temps réel
3. Onglet **Metrics** → Voir CPU/RAM/Requêtes

### Gérer la base de données

#### Via Supabase Table Editor

1. Dashboard Supabase → **Table Editor**
2. Voir/modifier les données directement

#### Via Prisma Studio (local)

```bash
cd D:\CCNS\workspace\backend

# Créer .env temporaire avec DATABASE_URL Supabase
echo 'DATABASE_URL="postgresql://postgres.abc..."' > .env

# Lancer Prisma Studio
npx prisma studio
```

Ouvrir http://localhost:5555

### Sauvegardes

Supabase fait des sauvegardes automatiques (plan gratuit : 7 jours de rétention)

Pour backup manuel :
1. Supabase Dashboard → **Database** → **Backups**
2. Cliquer **Create backup**

---

## Résolution de Problèmes

### ❌ Render : "Build failed"

**Logs** : `Error: Cannot find module 'typescript'`

**Solution** :
```bash
cd backend
npm install --save-dev typescript
git add package.json package-lock.json
git commit -m "Add typescript to devDependencies"
git push
```

### ❌ Flutter : "App crashes on startup"

**Vérifier** :
1. L'URL backend est correcte
2. Le backend est bien "Live" sur Render
3. Logs Android : `adb logcat | grep -i flutter`

**Solution** : Rebuild avec la bonne URL

### ❌ "Unable to connect to database"

**Vérifier** :
1. DATABASE_URL dans Render contient bien `?sslmode=require`
2. Le mot de passe Supabase est correct (pas de caractères spéciaux encodés)

**Fix** : Render Dashboard → Service → Environment → Edit DATABASE_URL

### ❌ Render : "Service is sleeping"

Le plan gratuit Render dort après 15 min d'inactivité.

**Solution** : La première requête réveille le service (15-30 secondes)

**Alternative** : Utiliser un service de ping (ex: UptimeRobot) - gratuit

---

## Support

### Contacts Utiles

- **Render Support** : https://render.com/docs
- **Supabase Support** : https://supabase.com/docs
- **Flutter Issues** : https://github.com/flutter/flutter/issues

### Commandes Utiles

```bash
# Vérifier version Flutter
flutter --version

# Nettoyer cache Flutter
flutter clean

# Analyser code Flutter
flutter analyze

# Voir logs backend
curl https://votre-service.onrender.com/health

# Tester API locale
curl http://localhost:3000/health

# Voir logs Android
adb logcat | grep -E "flutter|CCNS"
```

---

## Checklist Complète

### Avant déploiement
- [ ] Backend compile sans erreurs (`npm run build`)
- [ ] Flutter analyse sans warnings (`flutter analyze`)
- [ ] .gitignore créé
- [ ] .env.example à jour

### Déploiement
- [ ] Code sur GitHub
- [ ] Projet Supabase créé
- [ ] DATABASE_URL récupérée avec `?sslmode=require`
- [ ] Service Render créé via Blueprint
- [ ] Variables d'environnement configurées (DATABASE_URL, JWT_SECRET, CORS_ORIGIN)
- [ ] Service Render "Live"
- [ ] Health check OK : `https://....onrender.com/health`

### Distribution
- [ ] APK buildé avec URL production
- [ ] APK testé sur au moins 1 appareil
- [ ] Inscription/connexion testée
- [ ] Fonctionnalités principales testées
- [ ] APK distribué aux clients (GitHub/Drive/WhatsApp/etc.)

### Post-déploiement
- [ ] Instructions d'installation envoyées aux clients
- [ ] Support client préparé
- [ ] Monitoring activé (optionnel)
- [ ] Backups configurés

---

## Étapes Suivantes

1. ✅ Lire ce guide en entier
2. ✅ Créer les 3 comptes (GitHub, Supabase, Render)
3. ✅ Suivre Étape 1 à 6 dans l'ordre
4. ✅ Tester l'application complètement
5. ✅ Distribuer aux premiers clients (beta testers)
6. ✅ Collecter feedback
7. ✅ Itérer et améliorer

**Bonne chance ! 🚀**
