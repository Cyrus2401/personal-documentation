# Configuration d’un VirtualHost Apache en HTTPS pour un projet Symfony (port 9000)

Cette documentation explique **pas à pas** comment configurer un **VirtualHost Apache en HTTPS** pour un projet **Symfony**, en utilisant une **adresse IP** et le **port 9000**.

>  Contexte

* OS : Linux (Debian / Ubuntu)
* Serveur Web : Apache 2.4+
* Framework : Symfony (DocumentRoot = `/public`)
* HTTPS avec certificat **auto-signé**
* Accès via : `https://IP:9000`

---

## Prérequis

* Apache installé
* OpenSSL installé
* Accès root ou sudo
* Projet Symfony déjà déployé sur le serveur
* Le port `9000` doit être libre

---

## 1⃣ Activer les modules Apache nécessaires

```bash
sudo a2enmod ssl rewrite headers
sudo systemctl restart apache2
```

---

## 2⃣ Configurer Apache pour écouter le port 9000

Éditer le fichier :

```bash
sudo nano /etc/apache2/ports.conf
```

Ajouter :

```apache
Listen 9000
```

---

## 3⃣ Créer un certificat SSL auto-signé

Créer le dossier SSL :

```bash
sudo mkdir -p /etc/apache2/ssl
```

Générer le certificat :

```bash
sudo openssl req -x509 -nodes -days 365 \
-newkey rsa:2048 \
-keyout /etc/apache2/ssl/symfony.key \
-out /etc/apache2/ssl/symfony.crt
```

### Important

Lors de la question **Common Name (CN)**, mettre **exactement l’IP du serveur** :

```
192.x.x.x
```

---

## 4⃣ Créer le VirtualHost HTTPS

Créer le fichier de configuration :

```bash
sudo nano /etc/apache2/sites-available/symfony-9000-https.conf
```

### Configuration recommandée (Symfony + HTTPS)

```apache
<VirtualHost *:9000>

    ServerName 185.238.1.103
    ServerAlias localhost

    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/FLASH/eQRCode/public

    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/symfony.crt
    SSLCertificateKeyFile /etc/apache2/ssl/symfony.key

    <Directory /var/www/html/FLASH/eQRCode/public>
        Options FollowSymLinks
        AllowOverride None
        Require all granted

        <IfModule mod_rewrite.c>
            RewriteEngine On
            Options -MultiViews

            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule ^ index.php [QSA,L]
        </IfModule>
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/symfony_9000_error.log
    CustomLog ${APACHE_LOG_DIR}/symfony_9000_access.log combined

</VirtualHost>
```

---

## 5⃣ Vérifier les droits du projet Symfony

```bash
sudo chown -R www-data:www-data /var/www/html/FLASH/eQRCode
sudo chmod -R 755 /var/www/html/FLASH/eQRCode
```

---

## 6⃣ Activer le site

```bash
sudo a2ensite symfony-9000-https.conf
sudo systemctl reload apache2
```

---

## 7⃣ Définir le ServerName global (évite les warnings)

```bash
sudo nano /etc/apache2/apache2.conf
```

Ajouter à la fin :

```apache
ServerName 185.238.1.103
```

Puis :

```bash
sudo systemctl restart apache2
```

---

## 8⃣ Ouvrir le port 9000 dans le firewall

### Avec UFW

```bash
sudo ufw allow 9000/tcp
sudo ufw reload
```

---

## 9⃣ Vérifications

### Tester la configuration Apache

```bash
sudo apache2ctl configtest
```

Résultat attendu :

```
Syntax OK
```

### Vérifier que le port écoute

```bash
sudo ss -tulpn | grep 9000
```

---

## Accès à l’application

Dans le navigateur :

```
https://185.238.1.103:9000
```

>  Une alerte de sécurité est normale (certificat auto-signé)

---

## Bonnes pratiques Symfony

* Toujours pointer le `DocumentRoot` vers `/public`
* Désactiver `MultiViews`
* Utiliser `APP_ENV=prod` en production

```env
APP_ENV=prod
APP_DEBUG=0
```

Nettoyage du cache :

```bash
php bin/console cache:clear --env=prod
```

---

## Résumé

*  Apache configuré en HTTPS
*  Port 9000 fonctionnel
*  Certificat SSL valide pour l’IP
*  Symfony accessible en HTTPS

---

 *Documentation rédigée pour usage personnel et déploiement Symfony*