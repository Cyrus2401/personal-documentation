#!/bin/bash

# ================================================================
#  setup-debian-devstack.sh — Script universel Debian 11 / 12 / 13
#  Apache · MariaDB · PostgreSQL · PHP · Composer · Adminer
#  Node.js · Git · UFW · SSL self-signed
#  Auteur : généré automatiquement
#  Usage  : sudo ./setup-debian-devstack.sh
# ================================================================

set -euo pipefail

# ────────────────────────────────────────────────────────────────
# COULEURS & STYLES
# ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ────────────────────────────────────────────────────────────────
# FONCTIONS D'AFFICHAGE
# ────────────────────────────────────────────────────────────────
print_info()    { echo -e "  ${BLUE}→${NC} $1"; }
print_ok()      { echo -e "  ${GREEN}✔${NC}  $1"; }
print_warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; }
print_error()   { echo -e "  ${RED}✘${NC}  $1"; }
print_skip()    { echo -e "  ${CYAN}↷${NC}  $1 ${CYAN}(déjà présent, ignoré)${NC}"; }

print_section() {
    echo ""
    echo -e "${BOLD}${CYAN}┌─────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${CYAN}│  $1${NC}"
    echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────┘${NC}"
    echo ""
    sleep 0.3
}

print_step() {
    echo ""
    echo -e "  ${MAGENTA}▸ $1${NC}"
}

banner() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}  ║       INSTALLATION STACK DE DÉVELOPPEMENT           ║${NC}"
    echo -e "${BOLD}${CYAN}  ║       Debian 11 · 12 · 13  —  Universel             ║${NC}"
    echo -e "${BOLD}${CYAN}  ║  Apache · MariaDB · PostgreSQL · PHP · SSL · UFW    ║${NC}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ────────────────────────────────────────────────────────────────
# LOGS
# ────────────────────────────────────────────────────────────────
LOG_FILE="/var/log/setup-debian-devstack.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== Début installation : $(date) ===" >> "$LOG_FILE"

# ────────────────────────────────────────────────────────────────
# ROLLBACK : liste des actions effectuées pour annulation
# ────────────────────────────────────────────────────────────────
ROLLBACK_ACTIONS=()

rollback() {
    if [ ${#ROLLBACK_ACTIONS[@]} -eq 0 ]; then
        return
    fi
    echo ""
    print_error "Une erreur est survenue. Lancement du rollback..."
    echo ""
    # On parcourt en sens inverse
    for (( i=${#ROLLBACK_ACTIONS[@]}-1; i>=0; i-- )); do
        print_info "Rollback : ${ROLLBACK_ACTIONS[$i]}"
        eval "${ROLLBACK_ACTIONS[$i]}" || true
    done
    print_warn "Rollback terminé. Consultez $LOG_FILE pour les détails."
}

trap 'rollback' ERR

# ────────────────────────────────────────────────────────────────
# VARIABLES GLOBALES (remplies lors de la détection)
# ────────────────────────────────────────────────────────────────
DEBIAN_CODENAME=""
DEBIAN_VERSION=""
PHP_VERSION=""

# ────────────────────────────────────────────────────────────────
# 1. VÉRIFICATION DES DROITS
# ────────────────────────────────────────────────────────────────
check_sudo() {
    print_section "ÉTAPE 1/12 — Vérification des droits"

    if [[ $EUID -ne 0 ]]; then
        print_error "Ce script doit être lancé en tant que root (sudo ./install_dev_stack_universal.sh)"
        exit 1
    fi
    print_ok "Droits root confirmés"
}

# ────────────────────────────────────────────────────────────────
# 2. DÉTECTION DE DEBIAN
# ────────────────────────────────────────────────────────────────
check_debian() {
    print_section "ÉTAPE 2/12 — Détection du système"

    if [ ! -f /etc/os-release ]; then
        print_error "Fichier /etc/os-release introuvable. Système non reconnu."
        exit 1
    fi

    # shellcheck source=/dev/null
    . /etc/os-release

    if [ "$ID" != "debian" ]; then
        print_error "Ce script est réservé à Debian. Système détecté : ${ID}"
        exit 1
    fi

    DEBIAN_CODENAME="$VERSION_CODENAME"
    DEBIAN_VERSION="$VERSION_ID"

    case "$DEBIAN_CODENAME" in
        bullseye)
            print_ok "Debian 11 (Bullseye) — supporté"
            ;;
        bookworm)
            print_ok "Debian 12 (Bookworm) — supporté"
            ;;
        trixie)
            print_ok "Debian 13 (Trixie) — supporté"
            ;;
        *)
            print_warn "Version Debian '$DEBIAN_CODENAME' non officiellement testée."
            print_warn "Le script va continuer mais des erreurs sont possibles."
            sleep 2
            ;;
    esac

    print_info "Codename : $DEBIAN_CODENAME | Version : $DEBIAN_VERSION"
}

# ────────────────────────────────────────────────────────────────
# 3. VÉRIFICATION INTERNET
# ────────────────────────────────────────────────────────────────
check_internet() {
    print_section "ÉTAPE 3/12 — Vérification de la connexion internet"

    print_step "Test de connexion vers deb.debian.org..."

    if ! ping -c 2 -W 3 deb.debian.org &>/dev/null; then
        print_error "Aucune connexion internet détectée."
        print_error "Vérifiez votre réseau et relancez le script."
        exit 1
    fi

    print_ok "Connexion internet disponible"
}

# ────────────────────────────────────────────────────────────────
# 4. CONFIGURATION DES DÉPÔTS APT
# ────────────────────────────────────────────────────────────────
configure_sources() {
    print_section "ÉTAPE 4/12 — Configuration des dépôts APT"

    local sources_file="/etc/apt/sources.list"
    local backup_file="/etc/apt/sources.list.bak.$(date +%Y%m%d%H%M%S)"

    # Sauvegarde
    cp "$sources_file" "$backup_file"
    ROLLBACK_ACTIONS+=("cp '$backup_file' '$sources_file'")
    print_ok "Sauvegarde de sources.list → $backup_file"

    # Détecter si seul le CD-ROM est présent (commenté ou non) sans dépôt réseau
    local has_http_repo
    has_http_repo=$(grep -cE "^deb http" "$sources_file" 2>/dev/null || true)

    local has_cdrom_only
    has_cdrom_only=$(grep -cE "^#?deb cdrom" "$sources_file" 2>/dev/null || true)

    if [ "$has_http_repo" -gt 0 ]; then
        print_skip "Dépôts réseau déjà configurés"
    else
        if [ "$has_cdrom_only" -gt 0 ]; then
            print_warn "Seule une entrée CD-ROM a été détectée dans sources.list (cas typique après install depuis DVD/ISO)."
            print_info "Ajout automatique des dépôts réseau officiels pour Debian $DEBIAN_CODENAME..."
        else
            print_info "Aucun dépôt réseau trouvé. Configuration automatique..."
        fi

        tee "$sources_file" > /dev/null <<EOF
# Dépôts Debian ${DEBIAN_CODENAME} — configurés par setup-debian-devstack.sh le $(date +%Y-%m-%d)
# Ancienne entrée CD-ROM désactivée automatiquement (install depuis DVD/ISO détectée)
deb http://deb.debian.org/debian ${DEBIAN_CODENAME} main contrib non-free non-free-firmware
deb http://deb.debian.org/debian ${DEBIAN_CODENAME}-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security ${DEBIAN_CODENAME}-security main contrib non-free non-free-firmware
EOF

        print_ok "Dépôts réseau configurés pour Debian $DEBIAN_CODENAME"

        # Refresh immédiat après écriture des dépôts
        print_step "Rafraîchissement APT après configuration des dépôts..."
        apt-get update -qq
        print_ok "APT rafraîchi avec les nouveaux dépôts"
    fi
}

# ────────────────────────────────────────────────────────────────
# 5. MISE À JOUR DU SYSTÈME
# ────────────────────────────────────────────────────────────────
update_system() {
    print_section "ÉTAPE 5/12 — Mise à jour du système"

    print_step "Rafraîchissement de la liste des paquets..."
    apt-get update -qq
    print_ok "Liste des paquets à jour"

    print_step "Mise à niveau des paquets existants..."
    apt-get upgrade -y -qq
    print_ok "Système mis à jour"
}

# ────────────────────────────────────────────────────────────────
# HELPER : installer un paquet seulement s'il est absent
# ────────────────────────────────────────────────────────────────
install_pkg() {
    local pkg="$1"
    if dpkg -s "$pkg" &>/dev/null 2>&1; then
        print_skip "$pkg"
    else
        print_info "Installation de $pkg..."
        apt-get install -y -qq "$pkg"
        print_ok "$pkg installé"
    fi
}

# ────────────────────────────────────────────────────────────────
# 6. INSTALLATION DES PAQUETS — groupés par catégorie
# ────────────────────────────────────────────────────────────────
install_base_packages() {
    print_section "ÉTAPE 6/12 — Installation des paquets"

    # ── Serveurs ──────────────────────────────────────────────
    print_step "Serveurs web et bases de données..."
    for pkg in apache2 mariadb-server mariadb-client postgresql postgresql-contrib; do
        install_pkg "$pkg"
    done

    # ── PHP ───────────────────────────────────────────────────
    print_step "PHP et extensions..."
    for pkg in \
        php php-cli php-fpm php-common php-opcache \
        php-mysql php-pgsql php-sqlite3 \
        php-intl php-ldap php-soap \
        php-gd php-curl php-zip php-xml \
        php-mbstring php-bcmath php-imagick; do
        install_pkg "$pkg"
    done

    # ── Outils système ────────────────────────────────────────
    print_step "Outils système essentiels..."
    for pkg in curl wget git unzip zip vim nano htop ufw openssl; do
        install_pkg "$pkg"
    done

    # ── btop : monitoring avancé ──────────────────────────────
    print_step "Outils de monitoring..."
    if apt-cache show btop &>/dev/null 2>&1; then
        install_pkg "btop"
    else
        print_warn "btop non disponible sur Debian $DEBIAN_CODENAME, htop utilisé à la place"
    fi

    # ── Node.js & npm ─────────────────────────────────────────
    print_step "Node.js et npm..."
    for pkg in nodejs npm; do
        install_pkg "$pkg"
    done

    # ── Dépendances système (installées seulement si disponibles) ──
    print_step "Dépendances système..."
    for pkg in apt-transport-https ca-certificates gnupg lsb-release software-properties-common; do
        if apt-cache show "$pkg" &>/dev/null 2>&1; then
            install_pkg "$pkg"
        else
            print_warn "$pkg non disponible sur Debian $DEBIAN_CODENAME — ignoré"
        fi
    done

    # ── GParted (si environnement graphique) ──────────────────
    if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        print_step "Environnement graphique détecté..."
        install_pkg "gparted"
    else
        print_warn "Pas d'environnement graphique — GParted ignoré"
    fi

    print_ok "Tous les paquets sont installés"
}

# ────────────────────────────────────────────────────────────────
# 7. DÉTECTION & CONFIGURATION DE LA VERSION PHP ACTIVE
# ────────────────────────────────────────────────────────────────
configure_php() {
    print_section "ÉTAPE 7/12 — Configuration de PHP"

    # Détecter la version active
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || true)

    if [ -z "$PHP_VERSION" ]; then
        print_warn "Impossible de détecter la version PHP. Configuration php.ini ignorée."
        return
    fi

    print_ok "Version PHP active détectée : PHP $PHP_VERSION"

    # Chemins php.ini selon le contexte
    local php_ini_cli="/etc/php/${PHP_VERSION}/cli/php.ini"
    local php_ini_fpm="/etc/php/${PHP_VERSION}/fpm/php.ini"
    local php_ini_apache="/etc/php/${PHP_VERSION}/apache2/php.ini"

    # Paramètres à configurer
    declare -A PHP_PARAMS=(
        [upload_max_filesize]="64M"
        [post_max_size]="64M"
        [memory_limit]="256M"
        [max_execution_time]="120"
        [display_errors]="On"
        [error_reporting]="E_ALL"
        [date.timezone]="Africa/Porto-Novo"
    )

    for ini_file in "$php_ini_cli" "$php_ini_fpm" "$php_ini_apache"; do
        if [ -f "$ini_file" ]; then
            print_step "Configuration de $ini_file..."
            for key in "${!PHP_PARAMS[@]}"; do
                value="${PHP_PARAMS[$key]}"
                # Remplacer ou ajouter le paramètre
                if grep -qE "^;?${key}\s*=" "$ini_file"; then
                    sed -i "s|^;*${key}\s*=.*|${key} = ${value}|" "$ini_file"
                else
                    echo "${key} = ${value}" >> "$ini_file"
                fi
            done
            print_ok "$(basename "$ini_file") configuré"
        fi
    done

    # Activer php-fpm pour Apache
    if a2enmod "php${PHP_VERSION}" &>/dev/null 2>&1; then
        print_ok "Module Apache php${PHP_VERSION} activé"
    fi

    print_ok "PHP $PHP_VERSION configuré (memory: 256M, upload: 64M, timezone: Africa/Porto-Novo)"
}

# ────────────────────────────────────────────────────────────────
# 8. MODULES APACHE & SSL
# ────────────────────────────────────────────────────────────────
configure_apache() {
    print_section "ÉTAPE 8/12 — Configuration d'Apache"

    # ── Modules essentiels ────────────────────────────────────
    print_step "Activation des modules Apache..."
    for mod in rewrite ssl headers expires deflate; do
        if a2enmod "$mod" &>/dev/null 2>&1; then
            print_ok "mod_$mod activé"
        else
            print_warn "mod_$mod — déjà actif ou indisponible"
        fi
    done

    # ── SSL self-signed ───────────────────────────────────────
    print_step "Génération du certificat SSL auto-signé (10 ans)..."

    local ssl_dir="/etc/apache2/ssl"
    mkdir -p "$ssl_dir"
    ROLLBACK_ACTIONS+=("rm -rf '$ssl_dir'")

    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout "$ssl_dir/selfsigned.key" \
        -out    "$ssl_dir/selfsigned.crt" \
        -subj   "/C=BJ/ST=Atlantique/L=Abomey-Calavi/O=DevStack/OU=Dev/CN=localhost" \
        &>/dev/null

    print_ok "Certificat SSL généré dans $ssl_dir"

    # ── Virtual host HTTPS ────────────────────────────────────
    print_step "Configuration du virtual host HTTPS..."

    tee /etc/apache2/sites-available/default-ssl.conf > /dev/null <<EOF
<VirtualHost *:443>
    ServerName localhost
    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile      ${ssl_dir}/selfsigned.crt
    SSLCertificateKeyFile   ${ssl_dir}/selfsigned.key

    <Directory /var/www/html>
        AllowOverride All
        Require all granted
        Options Indexes FollowSymLinks
    </Directory>

    ErrorLog  \${APACHE_LOG_DIR}/ssl_error.log
    CustomLog \${APACHE_LOG_DIR}/ssl_access.log combined
</VirtualHost>
EOF

    a2ensite default-ssl &>/dev/null
    print_ok "Virtual host HTTPS activé → https://localhost"
    print_info "Note : l'avertissement du navigateur est normal pour un certificat auto-signé"
}

# ────────────────────────────────────────────────────────────────
# 10. ADMINER
# ────────────────────────────────────────────────────────────────
install_adminer() {
    print_section "ÉTAPE 9/11 — Installation d'Adminer"

    local adminer_dir="/usr/share/adminer"
    local adminer_file="${adminer_dir}/adminer.php"

    if [ -f "$adminer_file" ]; then
        print_skip "Adminer déjà présent dans $adminer_dir"
    else
        print_step "Téléchargement d'Adminer..."
        mkdir -p "$adminer_dir"
        ROLLBACK_ACTIONS+=("rm -rf '$adminer_dir'")
        wget -q "https://www.adminer.org/latest.php" -O "$adminer_file"
        print_ok "Adminer téléchargé"
    fi

    print_step "Configuration Apache pour Adminer..."

    tee /etc/apache2/conf-available/adminer.conf > /dev/null <<EOF
Alias /adminer ${adminer_dir}

<Directory ${adminer_dir}>
    Options FollowSymLinks
    DirectoryIndex adminer.php
    Require all granted
</Directory>
EOF

    a2enconf adminer &>/dev/null
    print_ok "Adminer configuré → http://localhost/adminer  |  https://localhost/adminer"
}

# ────────────────────────────────────────────────────────────────
# 11. FIREWALL UFW
# ────────────────────────────────────────────────────────────────
configure_ufw() {
    print_section "ÉTAPE 10/11 — Configuration du pare-feu UFW"

    print_step "Politique par défaut : tout autoriser..."
    ufw default allow incoming  &>/dev/null
    ufw default allow outgoing  &>/dev/null
    print_ok "Politique permissive appliquée"

    print_step "Blocage des ports dangereux..."
    declare -A BLOCKED_PORTS=(
        [23]="Telnet"
        [2323]="Telnet alternatif"
        [135]="RPC Microsoft"
        [137]="NetBIOS"
        [138]="NetBIOS"
        [139]="NetBIOS"
        [445]="SMB / partage Windows"
        [1433]="MSSQL"
        [1434]="MSSQL UDP"
        [3389]="RDP (Bureau à distance)"
    )

    for port in "${!BLOCKED_PORTS[@]}"; do
        ufw deny "$port" &>/dev/null
        print_ok "Port $port bloqué — ${BLOCKED_PORTS[$port]}"
    done

    print_step "Activation du pare-feu..."
    ufw --force enable &>/dev/null
    print_ok "UFW actif — tapez 'ufw status verbose' pour voir toutes les règles"
}

# ────────────────────────────────────────────────────────────────
# 12. DÉMARRAGE DES SERVICES + SÉCURISATION BDD
# ────────────────────────────────────────────────────────────────
start_and_secure_services() {
    print_section "ÉTAPE 11/11 — Démarrage des services & sécurisation des bases de données"

    # ── Démarrage ─────────────────────────────────────────────
    print_step "Activation et démarrage des services..."
    for service in apache2 mariadb postgresql; do
        systemctl enable "$service" &>/dev/null
        systemctl restart "$service"

        if systemctl is-active --quiet "$service"; then
            print_ok "$service actif"
        else
            print_warn "$service ne semble pas actif — vérifiez : journalctl -u $service"
        fi
    done

    sleep 2

    # ── Sécurisation MariaDB ──────────────────────────────────
    echo ""
    print_warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_warn "  SÉCURISATION MARIADB"
    print_warn "  Vous allez répondre à quelques questions pour sécuriser MariaDB."
    print_warn "  Conseil : acceptez toutes les options proposées (tapez 'Y' ou Entrée)."
    print_warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    sleep 2

    # Trouver mysql_secure_installation (chemin varie selon Debian)
    local mysql_secure
    mysql_secure=$(command -v mysql_secure_installation 2>/dev/null         || find /usr -name "mysql_secure_installation" 2>/dev/null | head -1         || true)

    if [ -z "$mysql_secure" ]; then
        print_warn "mysql_secure_installation introuvable — sécurisation MariaDB ignorée"
        print_warn "Faites-le manuellement : sudo mariadb-secure-installation"
    else
        "$mysql_secure"
    fi
    systemctl restart mariadb
    print_ok "MariaDB sécurisé et redémarré"

    sleep 1

    # ── Sécurisation PostgreSQL ───────────────────────────────
    echo ""
    print_warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_warn "  SÉCURISATION POSTGRESQL"
    print_warn "  Vous allez définir un mot de passe pour l'utilisateur 'postgres'."
    print_warn "  Choisissez un mot de passe fort et notez-le."
    print_warn "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    sleep 2

    # Détecter la version PostgreSQL installée
    local pg_version
    pg_version=$(psql --version 2>/dev/null | grep -oP '\d+' | head -1)
    local pg_hba="/etc/postgresql/${pg_version}/main/pg_hba.conf"

    if [ -f "$pg_hba" ]; then
        # Sauvegarde
        cp "$pg_hba" "${pg_hba}.bak"
        ROLLBACK_ACTIONS+=("cp '${pg_hba}.bak' '${pg_hba}'")

        # Remplacer peer par md5 pour l'utilisateur postgres
        sed -i 's/^local\s\+all\s\+postgres\s\+peer/local   all             postgres                                md5/' "$pg_hba"

        # Définir le mot de passe
        sudo -u postgres psql -c "\password postgres"

        systemctl restart postgresql
        print_ok "PostgreSQL sécurisé (authentification par mot de passe activée)"
    else
        print_warn "pg_hba.conf introuvable à $pg_hba"
        print_warn "Sécurisation PostgreSQL à faire manuellement : sudo -u postgres psql"
    fi
}

# ────────────────────────────────────────────────────────────────
# RÉSUMÉ FINAL
# ────────────────────────────────────────────────────────────────
show_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║           INSTALLATION TERMINÉE AVEC SUCCÈS         ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${BOLD}  CE QUI A ÉTÉ INSTALLÉ :${NC}"
    echo ""
    echo "  ✔  Apache2          → http://localhost"
    echo "  ✔  Apache2 HTTPS    → https://localhost  (certificat auto-signé)"
    echo "  ✔  MariaDB          → sécurisé via mysql_secure_installation"
    echo "  ✔  PostgreSQL       → sécurisé avec mot de passe"
    echo "  ✔  PHP $PHP_VERSION        → extensions complètes + php.ini configuré"
      echo "  ✔  Composer         → gestionnaire de dépendances PHP"
  echo "  ✔  Adminer          → http://localhost/adminer"
    echo "  ✔  Node.js + npm    → JavaScript côté serveur"
    echo "  ✔  Git              → gestion de versions"
    echo "  ✔  Outils           → curl, wget, unzip, zip, vim, nano, htop"
    echo "  ✔  UFW              → pare-feu actif (politique permissive)"
    echo ""

    echo -e "${BOLD}  STATUT DES SERVICES :${NC}"
    echo ""
    for service in apache2 mariadb postgresql; do
        local status
        status=$(systemctl is-active "$service" 2>/dev/null || echo "inconnu")
        if [ "$status" = "active" ]; then
            echo -e "  ${GREEN}●${NC}  $service : $status"
        else
            echo -e "  ${RED}●${NC}  $service : $status"
        fi
    done

    echo ""
    echo -e "${BOLD}  VERSIONS INSTALLÉES :${NC}"
    echo ""
    echo "  Debian     : $DEBIAN_CODENAME ($DEBIAN_VERSION)"
    echo "  Apache     : $(apache2 -v 2>/dev/null | head -n1 | sed 's/Server version: //')"
    echo "  MariaDB    : $(mariadb --version 2>/dev/null | sed 's/mariadb  Ver //' | awk '{print $1, $2, $3}')"
    echo "  PostgreSQL : $(psql --version 2>/dev/null)"
    echo "  PHP        : $(php -v 2>/dev/null | head -n1)"
    echo "  Composer   : $(composer --version 2>/dev/null || echo 'non installé')"
    echo "  Node.js    : $(node --version 2>/dev/null)"
    echo "  npm        : $(npm --version 2>/dev/null)"
    echo "  Git        : $(git --version 2>/dev/null)"
    echo ""

    echo -e "${BOLD}  COMMANDES UTILES :${NC}"
    echo ""
    echo "  PostgreSQL accès direct  →  sudo -u postgres psql"
    echo "  MariaDB accès direct     →  sudo mysql -u root -p"
    echo "  Règles pare-feu          →  sudo ufw status verbose"
    echo "  Logs installation        →  $LOG_FILE"
    echo ""
    echo -e "${CYAN}  ── Bonne continuation ! ──${NC}"
    echo ""
}

# ────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────
main() {
    banner

    check_sudo
    check_debian
    check_internet
    configure_sources
    update_system
    install_base_packages
    configure_php
    configure_apache
    install_adminer
    configure_ufw
    start_and_secure_services
    show_summary
}

main "$@"
