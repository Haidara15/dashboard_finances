# 📊 Déploiement automatique d'une application Shiny en production

Ce guide explique comment configurer **un pipeline de déploiement automatisé** pour une application [Shiny](https://shiny.posit.co/) sur un **serveur Ubuntu avec Nginx + HTTPS**.  
Il permet de **déployer automatiquement une app** hébergée sur GitHub via une simple commande (ou un push Git, si vous allez plus loin).

---

## 🚀 Fonctionnalités

- Déploiement automatique depuis GitHub (`git clone`)
- Redémarrage du serveur `shiny-server`
- Configuration Nginx avec HTTPS (via Let's Encrypt)
- Script `deploy_from_git.sh` clé en main
- Prise en charge des dépendances R

---

## 🧱 Prérequis

- Ubuntu (testé sur Ubuntu 22.04)
- Droits `sudo`
- Serveur accessible via `nom-de-domaine` (ex: `example.com`)
- Application Shiny stockée sur GitHub

---

## ⚙️ 1. Installation des composants de base

### 📦 Mise à jour système

```bash
sudo apt update && sudo apt upgrade -y
```

### 🐍 Installer R

```bash
sudo apt install -y r-base
```

### 💡 Installer les packages nécessaires à l'application

Créez un fichier `packages.R` contenant ceci si besoin :

```r
packages <- c("shiny", "plotly", "DT", "readr", "dplyr", "tidyr", "lubridate", "scales", "cachem", "digest")
install.packages(setdiff(packages, rownames(installed.packages())), repos = "https://cloud.r-project.org/")
```

Puis lancez :

```bash
sudo su - -c "Rscript packages.R"
```

---

### 💡 Installer Shiny Server

```bash
sudo apt install -y gdebi-core
wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo gdebi shiny-server-1.5.20.1002-amd64.deb
```

---

## 🌐 2. Configurer Nginx avec HTTPS

### 🌐 Installation de Nginx

```bash
sudo apt install -y nginx
```

### 🔒 Certificat SSL gratuit avec Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d example.com -d www.example.com
```

🛡️ Cela configure automatiquement un certificat SSL.

---

## 🛠️ 3. Script de déploiement automatique

### 📄 Créez `deploy_from_git.sh`

```bash
nano ~/deploy_from_git.sh
```

Collez :

```bash
#!/bin/bash

set -e

APP_NAME="your-app-name"
DEPLOY_DIR="/srv/shiny-server/apps/app"
GIT_REPO="git@github.com:your-github-username/${APP_NAME}.git"
TMP_DIR="/tmp/${APP_NAME}_deploy"

echo "==> Déploiement de ${APP_NAME}..."

rm -rf "$TMP_DIR"
git clone "$GIT_REPO" "$TMP_DIR"

sudo rm -rf "$DEPLOY_DIR"
sudo mkdir -p "$DEPLOY_DIR"
sudo cp -r "$TMP_DIR"/* "$DEPLOY_DIR"

sudo ln -sfn "$DEPLOY_DIR" "$DEPLOY_DIR/current"

sudo chown -R shiny:shiny "$DEPLOY_DIR"
sudo chmod -R 755 "$DEPLOY_DIR"

echo "🔄 Redémarrage de Shiny Server..."
sudo systemctl restart shiny-server

echo "✅ Déploiement terminé avec succès !"
```

Rendez-le exécutable :

```bash
chmod +x ~/deploy_from_git.sh
```

---

## 🔐 4. Configuration de la clé SSH GitHub (si repo privé)

### Générer la clé (si besoin)

```bash
ssh-keygen -t rsa -b 4096 -C "votre_email@example.com"
```

Laissez le chemin par défaut (`/home/your_user/.ssh/id_rsa`), puis :

```bash
cat ~/.ssh/id_rsa.pub
```

➡️ Copiez cette **clé publique** dans votre GitHub :  
GitHub → Settings → **SSH and GPG keys** → **New SSH key**

---

## 🌐 5. Configurer le domaine Nginx

Créer le fichier :

```bash
sudo nano /etc/nginx/sites-available/example.com
```

Avec :

```nginx
server {
    listen 80;
    server_name example.com www.example.com;

    location /app/ {
        proxy_pass http://127.0.0.1:3838/app/;
        proxy_redirect http://127.0.0.1:3838/ $scheme://$host/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Puis activez-le :

```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🚀 6. Déploiement de votre application

À chaque fois que vous poussez du code sur GitHub :

```bash
git add .
git commit -m "Mise à jour"
git push
```

Puis sur le serveur :

```bash
~/deploy_from_git.sh
```

---

## ✅ Exemple d'accès à l'app

https://www.example.com/app/

---

## 🧼 Bonnes pratiques

- Ne jamais exposer vos clés privées (`id_rsa`)
- Utiliser des repos privés si l’application est sensible
- Automatiser le déclenchement avec un webhook (optionnel)
- Sauvegarder régulièrement le serveur

---

## ✨ Bonus : Automatisation complète (facultatif)

Configurer un **GitHub webhook** ou une **GitHub Action** pour appeler automatiquement le script `deploy_from_git.sh` via SSH ou webhook à chaque `git push`.

---

## 🛡️ Avertissement

⚠️ **Ne publiez jamais vos clés SSH privées, mots de passe, ou certificats SSL**.

---

## 🧑‍💻 Auteur

[Votre nom ou pseudo GitHub]
