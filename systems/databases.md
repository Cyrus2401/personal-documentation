# Bases de données : MariaDB & PostgreSQL

Installation, gestion des utilisateurs, dump/restore. Ce sont les deux SGBD installés par `setup-debian-devstack.sh` (Debian 11/12/13).

## Sommaire
- [MariaDB](#mariadb)
- [PostgreSQL](#postgresql)
- [Dump & Restore](#dump--restore)
- [Backup automatique (cron)](#backup-automatique-cron)
- [Dépannage](#dépannage)

## MariaDB

### Installation
```bash
sudo apt install mariadb-server mariadb-client

# Sécuriser l'installation (root sans mot de passe, users anonymes, base test)
sudo mariadb-secure-installation

# Écoute locale uniquement (défaut Debian), vérifier :
ss -tlnp | grep 3306
```

### Connexion
```bash
sudo mariadb                 # root via socket unix (sans mot de passe)
mysql -u root -p             # avec mot de passe
mysql -h 127.0.0.1 -u app -p nom_base
```

### Utilisateurs & bases
```sql
-- Créer une base
CREATE DATABASE app_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Utilisateur local (accès via localhost uniquement)
CREATE USER 'app'@'localhost' IDENTIFIED BY 'mot_de_passe_fort';
GRANT ALL PRIVILEGES ON app_db.* TO 'app'@'localhost';
FLUSH PRIVILEGES;

-- Afficher / supprimer
SELECT User, Host FROM mysql.user;
DROP USER 'app'@'localhost';

-- Changer un mot de passe
ALTER USER 'app'@'localhost' IDENTIFIED BY 'nouveau_mot_de_passe';
```

> Ne jamais ouvrir `'app'@'%'` sur un serveur exposé. Pour un accès distant, passer par un tunnel SSH (`ssh -L 3306:127.0.0.1:3306 user@serveur`).

### Administration
```bash
mysqladmin status                              # État du serveur
mysqladmin ping                                # Le serveur répond ?
mariadb-check -u root -p --all-databases       # Vérifier les tables
mysql_secure_installation                      # Alias historique (Debian)
mariadb -u root -p -e "SHOW DATABASES;"
journalctl -u mariadb -n 50                    # Logs
```

## PostgreSQL

### Installation
```bash
sudo apt install postgresql postgresql-contrib
psql --version
sudo systemctl status postgresql
```

### Connexion
```bash
sudo -u postgres psql          # via peer auth (par défaut sur Debian)
sudo -u postgres psql -d app_db
psql -h 127.0.0.1 -U app -d app_db
```

### Utilisateurs & bases
```sql
-- Créer un rôle et une base
CREATE ROLE app WITH LOGIN PASSWORD 'mot_de_passe_fort';
CREATE DATABASE app_db OWNER app ENCODING 'UTF8' TEMPLATE template0;

-- Lister
\du            -- rôles
\l             -- bases
\dt            -- tables (connecté à la base)
\q             -- quitter

-- Droits
GRANT ALL PRIVILEGES ON DATABASE app_db TO app;
ALTER ROLE app WITH PASSWORD 'nouveau';
DROP DATABASE app_db;
DROP ROLE app;
```

### Authentification (`pg_hba.conf`)
```bash
cd /etc/postgresql/<version>/main
sudo nano pg_hba.conf
sudo systemctl restart postgresql
```
```
# TYPE  DATABASE  USER      ADDRESS       METHOD
local   all       postgres                peer    # défaut Debian
local   all       all                     scram-sha-256
host    all       all       127.0.0.1/32  scram-sha-256
```
Paramètres utiles dans `postgresql.conf` : `listen_addresses = 'localhost'` (jamais `'*'` en dev).

### Administration
```bash
psql -c "\l+"
psql -c "\dn"
sudo -u postgres vacuumdb --all --analyze    # Maintenance
journalctl -u postgresql -n 50
```

## Dump & Restore

### MariaDB
```bash
# Dump complet (structure + données)
mysqldump -u root -p --single-transaction --routines --triggers nom_base > nom_base.sql

# Dump compressé, toutes les bases
mysqldump -u root -p --all-databases --single-transaction | gzip > all_$(date +%F).sql.gz

# Restore
mysql -u root -p nom_base < nom_base.sql
gunzip < all_2026-11-02.sql.gz | mysql -u root -p
```

### PostgreSQL
```bash
# Format custom (recommandé : compression + restauration sélective)
pg_dump -U postgres -Fc app_db > app_db.dump

# Format SQL brut
pg_dump -U postgres app_db > app_db.sql
pg_dumpall -U postgres > all.sql

# Restore
pg_restore -U postgres -d app_db --clean --if-exists app_db.dump
psql -U postgres -d app_db < app_db.sql
```

### Distant via tunnel SSH
```bash
ssh -L 3306:127.0.0.1:3306 user@serveur
mysqldump -h 127.0.0.1 -u root -p nom_base > local.sql

ssh -L 5432:127.0.0.1:5432 user@serveur
pg_dump -h 127.0.0.1 -U postgres -Fc app_db > local.dump
```

## Backup automatique (cron)

```bash
sudo mkdir -p /var/backups/db && sudo chown postgres:postgres /var/backups/db

# /etc/cron.d/db-backup
0 3 * * * postgres pg_dump -Fc app_db > /var/backups/db/app_$(date +\%F).dump
0 3 * * * root mysqldump -u root --all-databases --single-transaction | gzip > /var/backups/db/all_$(date +\%F).sql.gz
```
> Dans `/etc/cron.d`, `%` doit être échappé (`\%`).

Purge des vieux dumps :
```bash
find /var/backups/db -mtime +14 -delete
```

## Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| `Access denied for user 'root'@'localhost'` | Auth par socket vs mot de passe | `sudo mariadb` (socket) ou `-h 127.0.0.1` (TCP) |
| `Peer authentication failed` (Postgres) | Pas de `sudo -u postgres` | `sudo -u postgres psql` |
| `Connection refused` sur 5432/3306 | Service arrêté ou `listen_addresses` / `bind-address` | `systemctl status`, vérifier `postgresql.conf` / `mariadb.cnf` |
| `Too many connections` | `max_connections` atteint | Augmenter dans `my.cnf` / `postgresql.conf` |
| `Disk full` | WAL/binlogs | Purger binlogs : `PURGE BINARY LOGS BEFORE NOW()` / `SELECT pg_switch_wal()` |

Accès web aux bases : Adminer installé par le script → `http://localhost/adminer`.
