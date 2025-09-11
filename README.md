
# 🚀 Déploiement Automatisé d'une Application Shiny avec GitHub, Nginx & HTTPS

Ce guide décrit **toutes les étapes** nécessaires pour :

- Déployer une app Shiny automatiquement depuis GitHub
- L'exposer proprement via un **nom de domaine personnalisé (Nginx + HTTPS)**
- Automatiser le redéploiement avec un **script shell**

---

## 🧰 1. Prérequis

- Un **VPS Ubuntu**
- Un **nom de domaine** pointant vers l’IP du VPS (ex. `m-haidara.fr`)
- Un **compte GitHub**
- Une application Shiny (fichier `app.R`, dossier `www/`, etc.)

---

## 🧱 2. Installation des outils nécessaires

### 🔹 Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

### 🔹 Installer R et Shiny
```bash
sudo apt install -y r-base
sudo su - -c "R -e \"install.packages('shiny', repos='https://cloud.r-project.org/')\""
```

### 🔹 Installer Shiny Server
```bash
sudo apt install -y gdebi-core
wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo gdebi shiny-server-1.5.20.1002-amd64.deb
```

### 🔹 Installer Nginx + Certbot (HTTPS)
```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

---

## 🔒 3. Activer HTTPS avec votre nom de domaine

### Configurer Nginx
```bash
sudo nano /etc/nginx/sites-available/m-haidara.fr
```
Contenu :
```nginx
server {
    listen 80;
    server_name m-haidara.fr www.m-haidara.fr;

    location / {
        proxy_pass http://127.0.0.1:3838;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```
Puis :
```bash
sudo ln -s /etc/nginx/sites-available/m-haidara.fr /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Obtenir un certificat HTTPS avec Certbot
```bash
sudo certbot --nginx -d m-haidara.fr -d www.m-haidara.fr
```

---

## 🔐 4. Ajout de la clé SSH pour GitHub

```bash
ssh-keygen -t rsa -b 4096 -C "votre_email@example.com"
cat ~/.ssh/id_rsa.pub
```
→ Copiez la clé et ajoutez-la sur GitHub : **Settings > SSH and GPG Keys**.

---

## ⚙️ 5. Script de déploiement automatique

Créer :
```bash
nano ~/deploy_from_git.sh
```

Contenu :
```bash
#!/bin/bash

set -e

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
sudo ln -sfn "$DEPLOY_DIR" "$DEPLOY_DIR/current"

sudo chown -R shiny:shiny "$DEPLOY_DIR"
sudo chmod -R 755 "$DEPLOY_DIR"

echo "🔄 Redémarrage de Shiny Server..."
sudo systemctl restart shiny-server

echo "✅ Déploiement terminé avec succès !"
```

Rendre exécutable :
```bash
chmod +x ~/deploy_from_git.sh
```

---

## 🧪 6. Utilisation quotidienne

### Ajouter une modification :
```bash
git add .
git commit -m "modif"
git push
```

### Déployer sur le serveur :
```bash
~/deploy_from_git.sh
```

---

## 📂 7. Structure du dossier

```
/srv/shiny-server/apps/app/
├── app.R
├── data/
├── www/
└── current → lien vers ce dossier
```

---

## ✅ Récapitulatif des commandes

| Étape | Commande |
|-------|----------|
| Commit + push | `git add . && git commit -m "..." && git push` |
| Déploiement serveur | `~/deploy_from_git.sh` |
| Redémarrer Shiny (optionnel) | `sudo systemctl restart shiny-server` |

---

## 🔁 Améliorations futures

- Webhook GitHub pour déploiement automatique
- Versioning des releases
- Tests automatisés

