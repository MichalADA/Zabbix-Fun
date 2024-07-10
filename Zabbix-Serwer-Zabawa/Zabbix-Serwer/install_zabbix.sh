#!/bin/bash

# Funkcja do wyświetlania komunikatów
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Sprawdzenie, czy skrypt jest uruchomiony z uprawnieniami roota
if [ "$EUID" -ne 0 ]; then
    log "Ten skrypt musi być uruchomiony jako root."
    exit 1
fi

# Aktualizacja systemu
log "Aktualizacja systemu..."
apt update && apt upgrade -y

# Instalacja repozytorium Zabbix
log "Instalacja repozytorium Zabbix..."
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu$(lsb_release -rs)_all.deb
dpkg -i zabbix-release_7.0-1+ubuntu$(lsb_release -rs)_all.deb
apt update

# Instalacja Zabbix serwera, frontendu i agenta
log "Instalacja Zabbix serwera, frontendu i agenta..."
apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Instalacja i konfiguracja MariaDB
log "Instalacja i konfiguracja MariaDB..."
apt install software-properties-common -y
curl -LsS -O https://downloads.mariadb.com/MariaDB/mariadb_repo_setup
bash mariadb_repo_setup --mariadb-server-version=10.11
apt update
apt -y install mariadb-common mariadb-server-10.11 mariadb-client-10.11

# Tworzenie bazy danych Zabbix
log "Tworzenie bazy danych Zabbix..."
mysql -uroot <<EOF
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user zabbix@localhost identified by 'password';
grant all privileges on zabbix.* to zabbix@localhost;
flush privileges;
EOF

# Import schematu początkowego
log "Import schematu początkowego..."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -ppassword zabbix

# Konfiguracja Zabbix serwera
log "Konfiguracja Zabbix serwera..."
sed -i 's/# DBPassword=/DBPassword=password/' /etc/zabbix/zabbix_server.conf

# Uruchomienie i włączenie usług Zabbix
log "Uruchamianie usług Zabbix..."
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

log "Instalacja Zabbix serwera zakończona."
log "Proszę przejść do http://twój_adres_ip/zabbix aby dokończyć konfigurację przez przeglądarkę."
log "Domyślne dane logowania: Użytkownik - Admin, Hasło - zabbix"
log "Pamiętaj, aby zmienić domyślne hasło po pierwszym logowaniu!"