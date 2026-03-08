# 🚀 Déploiement Rapide - CCNS App

## ⚡ Version Express (30 minutes)

### 1️⃣ Push sur GitHub (5 min)

```bash
cd D:\CCNS\workspace
git init
git add .
git commit -m "Initial commit"

# Créer repo sur https://github.com/new puis :
git remote add origin https://github.com/VOTRE_USERNAME/ccns-app.git
git push -u origin main
```

### 2️⃣ Supabase (5 min)

1. https://supabase.com/dashboard → **New project**
2. Nom : `ccns-prod` | Password : `MDP_SECURE_123!` | Region : Europe
3. Attendre 2 min
4. **Settings** → **Database** → **Connection string** → **URI**
5. Copier l'URL + remplacer `[YOUR-PASSWORD]` + ajouter `?sslmode=require`

**Exemple** :
```
postgresql://postgres.abc:MDP_SECURE_123!@aws-0-eu-west-1.pooler.supabase.com:5432/postgres?sslmode=require
```

### 3️⃣ Render (10 min)

1. https://render.com → **Sign up with GitHub**
2. **New +** → **Blueprint**
3. Connecter repo `ccns-app`
4. Configurer secrets :
   - **DATABASE_URL** : *(URL Supabase ci-dessus)*
   - **JWT_SECRET** : `abcdef123456789abcdef123456789abcdef123456789` *(générer avec `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"` )*
   - **CORS_ORIGIN** : `*`
5. **Apply** → Attendre 5 min
6. Copier l'URL : `https://ccns-backend-api-xyz.onrender.com`

### 4️⃣ Build APK (5 min)

```bash
cd D:\CCNS\workspace\front

flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://ccns-backend-api-xyz.onrender.com/api
```

APK ici : `front\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`

### 5️⃣ Tester (3 min)

1. Installer APK sur téléphone
2. Créer compte test
3. Ajouter client + transaction
4. ✅ Vérifier que tout fonctionne

### 6️⃣ Distribuer (2 min)

**Option A** : Envoyer APK par WhatsApp/Email directement

**Option B** : GitHub Release
```bash
# Sur https://github.com/VOTRE_USERNAME/ccns-app/releases/new
Tag: v1.0.0
Upload: app-arm64-v8a-release.apk
Publish
```

---

## 📚 Documentation Complète

- **Guide Déploiement Détaillé** : [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Guide Installation Client** : [GUIDE_CLIENT_INSTALLATION.md](GUIDE_CLIENT_INSTALLATION.md)

---

## 🔧 Commandes Utiles

### Vérifier backend
```bash
curl https://votre-service.onrender.com/health
```

### Rebuild APK après modifs
```bash
cd front
flutter build apk --release --dart-define=API_BASE_URL=https://votre-service.onrender.com/api
```

### Redéployer backend
```bash
git add .
git commit -m "Update: description"
git push
# Render redéploie automatiquement
```

### Voir logs Render
https://dashboard.render.com → Votre service → **Logs**

### Gérer BD Supabase
https://supabase.com/dashboard → Votre projet → **Table Editor**

---

## ⚠️ Points Importants

| Item | Détail |
|------|--------|
| 🆓 **Coût** | 0€ (plans gratuits Supabase + Render) |
| 😴 **Sleep Mode** | Backend dort après 15 min inactivité (se réveille en 15-30s) |
| 📊 **Limites Gratuit** | Supabase: 500MB BD, 2GB transfert/mois<br>Render: 750h/mois, 512MB RAM |
| 🔐 **Sécurité** | HTTPS automatique, JWT auth, passwords hachés |
| 📱 **Compatibilité** | Android 5.0+ (API 21+) |

---

## ✅ Checklist

- [ ] Code sur GitHub
- [ ] Supabase configuré
- [ ] Render déployé
- [ ] Health check OK
- [ ] APK buildé avec bonne URL
- [ ] APK testé
- [ ] APK distribué

---

## 🆘 Problèmes Courants

### ❌ Render : Health check failed

```bash
# Vérifier logs Render
# Vérifier DATABASE_URL contient ?sslmode=require
```

### ❌ APK : Connection failed

```bash
# Vérifier backend est "Live" sur Render
# Vérifier URL dans --dart-define est correcte
# Attendre 30s (premier démarrage après sleep)
```

### ❌ Build APK failed

```bash
cd front
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://...
```

---

**Tout est prêt ! Lisez DEPLOYMENT_GUIDE.md pour les détails complets.** 🚀
