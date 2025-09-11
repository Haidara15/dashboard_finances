
# 🚀 Déploiement automatique d'une application Shiny avec Git & Nginx

Ce guide explique comment configurer un serveur Ubuntu pour déployer automatiquement une application **Shiny** hébergée sur GitHub.

---

## 🧰 Prérequis

- Un serveur Ubuntu (ex: VPS)
- Un nom de domaine (ex: `m-haidara.fr`)
- Un dépôt GitHub contenant votre application (`app.R`, `www/`, `data/`, etc.)
- Une clé SSH configurée pour accéder à votre repo

---

## ⚙️ 1. Installation des dépendances système

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y r-base gdebi-core nginx git curl ufw
```

---

## 📦 2. Installation de R et des packages nécessaires

```bash
sudo apt install -y r-base
```

Puis installez `shiny` et les autres packages nécessaires :

```bash
sudo su - -c "R -e "install.packages(c('shiny','plotly','DT','readr','dplyr','tidyr','lubridate','scales','cachem','digest'), repos='https://cloud.r-project.org/')""
```

### 👉 Option recommandée : fichier `packages.R`

Créez un fichier `packages.R` à la racine de votre dépôt GitHub :

```r
# packages.R
packages <- c("shiny", "plotly", "DT", "readr", "dplyr", "tidyr", "lubridate", "scales", "cachem", "digest")

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

invisible(lapply(packages, install_if_missing))
```

👉 **Emplacement recommandé** : `/srv/shiny-server/apps/app/packages.R`

Exécution manuelle (ou dans votre script) :

```bash
sudo su - -c "Rscript /srv/shiny-server/apps/app/packages.R"
```

---

## 🌐 3. Installation de Shiny Server

```bash
wget https://download3.rstudio.org/ubuntu-20.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo gdebi shiny-server-1.5.20.1002-amd64.deb
```

Vérification :

```bash
sudo systemctl status shiny-server
```

---

## 🌍 4. Configuration Nginx pour reverse proxy + HTTPS

### Exemple de fichier : `/etc/nginx/sites-available/m-haidara.fr`

```nginx
server {
    listen 80;
    server_name m-haidara.fr www.m-haidara.fr;
    location / {
        proxy_pass http://127.0.0.1:3838/;
        proxy_redirect http://127.0.0.1:3838/ $scheme://$host/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 20d;
    }
}
```

### Activer le site et recharger Nginx

```bash
sudo ln -s /etc/nginx/sites-available/m-haidara.fr /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔐 5. Certificat SSL avec Let's Encrypt (HTTPS)

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d m-haidara.fr -d www.m-haidara.fr
```

Vérifiez que le renouvellement automatique fonctionne :

```bash
sudo certbot renew --dry-run
```

---

## 🚀 6. Script de déploiement automatique

Fichier : `~/deploy_from_git.sh`

```bash
#!/bin/bash

set -e  # Stop on error

APP_NAME="shinyFinances"
DEPLOY_DIR="/srv/shiny-server/apps/app"
GIT_REPO="git@github.com:Haidara15/${APP_NAME}.git"
TMP_DIR="/tmp/${APP_NAME}_deploy"

echo "==> Déploiement de ${APP_NAME}..."

rm -rf "$TMP_DIR"
git clone "$GIT_REPO" "$TMP_DIR"

sudo rm -rf "$DEPLOY_DIR"
sudo mkdir -p "$DEPLOY_DIR"
sudo cp -r "$TMP_DIR"/* "$DEPLOY_DIR"

# Recrée le lien symbolique vers 'current'
sudo ln -sfn "$DEPLOY_DIR" "$DEPLOY_DIR/current"

# Droits
sudo chown -R shiny:shiny "$DEPLOY_DIR"
sudo chmod -R 755 "$DEPLOY_DIR"

# Redémarre le serveur
echo "🔄 Redémarrage de Shiny Server..."
sudo systemctl restart shiny-server

echo "✅ Déploiement terminé avec succès !"
```

Rendez-le exécutable :

```bash
chmod +x ~/deploy_from_git.sh
```

---

## 🔁 7. Cycle de mise à jour d'une app

À chaque fois que vous modifiez votre app localement :

```bash
git add .
git commit -m "modification"
git push
```

Puis sur le serveur :

```bash
~/deploy_from_git.sh
```

C’est tout !

---

