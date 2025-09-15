# 🚀 Automatiser le Déploiement CI/CD d'une Application Shiny avec Git et Nginx

Ce guide vous explique comment configurer un serveur Linux pour héberger et déployer automatiquement une application Shiny depuis GitHub. Le pipeline permet de :

- Déployer automatiquement votre app après un `git push`
- Redémarrer Shiny Server à chaque mise à jour
- Gérer les permissions et structure proprement

---

## 🧱 1. Prérequis sur le serveur

Disposer d'un VPS ou une machine avec Ubuntu (22.04 par ex.) et accès SSH.

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 🛠️ 2. Installer R et Shiny Server

```bash
# Mettre à jour les paquets
sudo apt update && sudo apt upgrade -y

# Installer R
sudo apt install -y r-base

# Installer les packages R nécessaires à ton app (Shiny + dépendances)
sudo su - -c "R -e \"install.packages(c('shiny','plotly','DT','readr','dplyr','tidyr','lubridate','scales','cachem','digest'), repos='https://cloud.r-project.org/')\""

# Télécharger la version récente de Shiny Server (compatible Ubuntu 20.04 / 22.04)
wget https://download3.rstudio.org/ubuntu-20.04/x86_64/shiny-server-1.5.23.1030-amd64.deb

# Installer gdebi si pas encore installé
sudo apt install -y gdebi-core

# Installer Shiny Server via gdebi (gère les dépendances automatiquement)
sudo gdebi shiny-server-1.5.23.1030-amd64.deb


```


## 🌐 3. Configurer Nginx et HTTPS (Nom de domaine)

```bash
sudo apt install nginx certbot python3-certbot-nginx
```

Créer un fichier de configuration Nginx :

```bash
sudo nano /etc/nginx/sites-available/mondomaine.fr
```

Contenu à adapter :

```nginx
server {
  listen 80;
  server_name mondomaine.fr www.mondomaine.fr;
  location / {
    proxy_pass http://127.0.0.1:3838;
    proxy_redirect http://127.0.0.1:3838/ $scheme://$host/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 20d;
    proxy_buffering off;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

Activer et tester :

```bash
sudo ln -s /etc/nginx/sites-available/mondomaine.fr /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Activer HTTPS avec Let's Encrypt :

```bash
sudo certbot --nginx -d mondomaine.fr -d www.mondomaine.fr
```

---

## 🔐 4. Clé SSH pour GitHub (authentification sans mot de passe)

Générer une clé SSH :

```bash
ssh-keygen -t rsa -b 4096 -C "you@example.com"
```

Appuyez sur Entrée pour accepter le chemin proposé (`/home/USER/.ssh/id_rsa`).

Afficher la clé publique :

```bash
cat ~/.ssh/id_rsa.pub
```

Copier cette clé dans GitHub > Settings > SSH and GPG keys > **New SSH key**

---

## 🚀 5. Créer le script de déploiement

Créer un fichier `deploy_from_git.sh` dans le home :

```bash
nano ~/deploy_from_git.sh
```

Contenu :

```bash
#!/bin/bash

set -e  # Stop si erreur

APP_NAME="App-name"
DEPLOY_DIR="/srv/shiny-server/apps/app"
GIT_REPO="git@github.com:VOTRE_USER/${APP_NAME}.git"
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

## ✅ 6. Utilisation

À chaque modification de votre app :

```bash
# En local
git add .
git commit -m "modification"
git push

# Sur le serveur
~/deploy_from_git.sh
```

---

## 📁 Structure recommandée

Le dossier `/srv/shiny-server/apps/app` contiendra :

```txt
app/
├── app.R
├── data/
│   └── finances.csv
├── www/
│   ├── styles.css
│   └── app.js
└── current -> lien symbolique (facultatif)
```

---
