# ProCreditApp Backend - Guide de Déploiement

## Prérequis

- Node.js >= 18
- MySQL >= 8.0
- Docker & Docker Compose (optionnel, pour containerization)
- Linux Server (VPS) avec SSH access
- Domain name pointé vers le serveur

## Option 1: Déploiement Local (Développement)

### 1. Installation des dépendances

```bash
cd backend
npm install
```

### 2. Configuration de la base de données

Créez une base de données MySQL:

```bash
mysql -u root -p
CREATE DATABASE procreditapp_db;
CREATE USER 'procreditapp'@'localhost' IDENTIFIED BY 'procreditapp_password';
GRANT ALL PRIVILEGES ON procreditapp_db.* TO 'procreditapp'@'localhost';
FLUSH PRIVILEGES;
```

### 3. Configuration des variables d'environnement

```bash
cp .env.example .env
```

Éditez `.env`:

```env
DATABASE_URL="mysql://procreditapp:procreditapp_password@localhost:3306/procreditapp_db"
JWT_SECRET="your-secure-random-key-here-min-32-chars"
JWT_EXPIRATION="7d"
NODE_ENV="development"
PORT=3000
CORS_ORIGIN="http://localhost:3000"
LOG_LEVEL="debug"
BCRYPT_ROUNDS=10
```

### 4. Initialisation de la base de données

```bash
npm run prisma:migrate
npm run prisma:seed
```

### 5. Démarrage du serveur

```bash
npm run dev
```

Le serveur sera disponible sur `http://localhost:3000`

---

## Option 2: Déploiement avec Docker

### 1. Construire l'image Docker

```bash
docker build -t procreditapp-backend .
```

### 2. Démarrer avec Docker Compose

```bash
docker-compose up -d
```

### 3. Vérifier le statut

```bash
docker-compose ps
docker-compose logs -f app
```

### 4. Arrêter les services

```bash
docker-compose down
```

---

## Option 3: Déploiement en Production (VPS Linux)

### 1. Connexion au serveur

```bash
ssh root@your_server_ip
```

### 2. Installation des prérequis

```bash
# Update system
apt update && apt upgrade -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# Install MySQL
apt install -y mysql-server

# Install Nginx
apt install -y nginx

# Install Certbot (SSL)
apt install -y certbot python3-certbot-nginx

# Install PM2 (Process Manager)
npm install -g pm2
```

### 3. Cloner le projet

```bash
git clone https://github.com/yourusername/procreditapp.git
cd procreditapp/backend
```

### 4. Configuration de MySQL

```bash
# Sécuriser MySQL
mysql_secure_installation

# Créer la base de données
mysql -u root -p
CREATE DATABASE procreditapp_db;
CREATE USER 'procreditapp'@'localhost' IDENTIFIED BY 'strong_password';
GRANT ALL PRIVILEGES ON procreditapp_db.* TO 'procreditapp'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 5. Configuration du backend

```bash
npm install
cp .env.example .env
```

Éditez `.env` pour la production:

```env
DATABASE_URL="mysql://procreditapp:strong_password@localhost:3306/procreditapp_db"
JWT_SECRET="generate-a-strong-random-key-32-64-chars"
JWT_EXPIRATION="7d"
NODE_ENV="production"
PORT=3000
CORS_ORIGIN="https://your-domain.com"
LOG_LEVEL="info"
BCRYPT_ROUNDS=12
```

### 6. Build et migration

```bash
npm run build
npm run prisma:deploy
npm run prisma:seed
```

### 7. Configuration de PM2

Créez `ecosystem.config.js`:

```javascript
module.exports = {
  apps: [
    {
      name: 'procreditapp-backend',
      script: './dist/index.js',
      instances: 'max',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'production',
      },
      error_file: './logs/pm2-error.log',
      out_file: './logs/pm2-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
    },
  ],
};
```

Démarrez avec PM2:

```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

Vérifiez le statut:

```bash
pm2 status
pm2 logs procreditapp-backend
```

### 8. Configuration de Nginx (Reverse Proxy)

Créez `/etc/nginx/sites-available/procreditapp`:

```nginx
upstream procreditapp_backend {
  least_conn;
  server 127.0.0.1:3000;
  server 127.0.0.1:3001;
  server 127.0.0.1:3002;
}

server {
  listen 80;
  server_name yourdomain.com www.yourdomain.com;

  # Redirect to HTTPS
  return 301 https://$server_name$request_uri;
}

server {
  listen 443 ssl http2;
  server_name yourdomain.com www.yourdomain.com;

  # SSL certificates (Let's Encrypt)
  ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

  # Security headers
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-Frame-Options "DENY" always;
  add_header X-XSS-Protection "1; mode=block" always;

  # Gzip compression
  gzip on;
  gzip_types text/html text/plain application/json;

  location /api {
    proxy_pass http://procreditapp_backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;

    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
  }

  location / {
    return 404;
  }
}
```

Activez la configuration:

```bash
ln -s /etc/nginx/sites-available/procreditapp /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

### 9. Configuration SSL avec Let's Encrypt

```bash
certbot certonly --nginx -d yourdomain.com -d www.yourdomain.com
```

### 10. Configuration du Firewall (UFW)

```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

### 11. Backup MySQL automatique

Créez `/root/backup_db.sh`:

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/mysql"
mkdir -p $BACKUP_DIR

mysqldump -u procreditapp -p'password' procreditapp_db > $BACKUP_DIR/procreditapp_$DATE.sql
gzip $BACKUP_DIR/procreditapp_$DATE.sql

# Delete backups older than 30 days
find $BACKUP_DIR -type f -mtime +30 -delete
```

Rendez-le exécutable et ajoutez-le au cron:

```bash
chmod +x /root/backup_db.sh
crontab -e
```

Ajoutez la ligne:

```
0 2 * * * /root/backup_db.sh
```

### 12. Monitoring avec Prometheus & Grafana (Optionnel)

Installation de Prometheus:

```bash
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar xvfz prometheus-2.40.0.linux-amd64.tar.gz
mv prometheus-2.40.0.linux-amd64 /opt/prometheus
```

Configuration de Prometheus (`/opt/prometheus/prometheus.yml`):

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'procreditapp'
    static_configs:
      - targets: ['localhost:3000']
```

Installation de Grafana:

```bash
apt install -y grafana-server
systemctl start grafana-server
systemctl enable grafana-server
```

---

## Monitoring & Maintenance

### Logs

```bash
# View logs
pm2 logs procreditapp-backend

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System logs
journalctl -u procreditapp-backend -n 50
```

### Performance Monitoring

```bash
# Check CPU and memory usage
ps aux | grep node

# Check database connections
mysql -u procreditapp -p -e "SHOW PROCESSLIST;"

# Check disk usage
df -h
du -sh /var/lib/mysql
```

### Updates

```bash
# Update Node.js
nvm install latest

# Update dependencies
npm update

# Run migrations
npm run prisma:migrate

# Restart the application
pm2 restart procreditapp-backend
```

---

## Troubleshooting

### Port already in use:

```bash
lsof -i :3000
kill -9 <PID>
```

### Database connection issues:

```bash
# Test connection
mysql -u procreditapp -p -h localhost procreditapp_db

# Check MySQL service
systemctl status mysql
```

### Out of memory:

```bash
# Increase swap space
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

### SSL certificate renewal:

```bash
certbot renew --quiet
# Auto-renew (runs automatically via cron)
```

---

## Checklist Avant Production

- [ ] Changer tous les secrets (JWT_SECRET)
- [ ] Configurer HTTPS (SSL)
- [ ] Configurer le firewall
- [ ] Mettre en place les backups automatiques
- [ ] Configurer le monitoring
- [ ] Tester la récupération après sinistre
- [ ] Nettoyer les logs/données sensibles
- [ ] Vérifier les permissions des fichiers
- [ ] Configurer les rate limits
- [ ] Mettre en place un système d'alertes

---

## Support

Pour questions ou problèmes: support@procreditapp.com
