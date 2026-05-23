#!/usr/bin/env bash

set -euo pipefail

echo "=========================================="
echo " Reparando base de datos Zabbix"
echo "=========================================="
echo

echo "[1/7] Matando posibles importaciones colgadas..."
sudo pkill -9 -f "mysql --default-character-set=utf8mb4 zabbix" 2>/dev/null || true
sudo pkill -9 -f "zcat /usr/share/zabbix-server-mysql/schema.sql.gz" 2>/dev/null || true

echo "[2/7] Borrando base de datos anterior..."
sudo mysql -e "DROP DATABASE IF EXISTS zabbix;"

echo "[3/7] Creando base de datos limpia..."
sudo mysql -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"

echo "[4/7] Creando usuario zabbix..."
sudo mysql -e "DROP USER IF EXISTS 'zabbix'@'localhost';"
sudo mysql -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'zabbix';"
sudo mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "[5/7] Importando esquema principal..."
echo "OJO: este paso puede tardar varios minutos. NO pulses Ctrl+C ni Ctrl+Z."
sudo bash -c 'zcat /usr/share/zabbix-server-mysql/schema.sql.gz | mysql --default-character-set=utf8mb4 zabbix'

echo "[6/7] Importando imagenes..."
sudo bash -c 'zcat /usr/share/zabbix-server-mysql/images.sql.gz | mysql --default-character-set=utf8mb4 zabbix'

echo "[7/7] Importando datos..."
sudo bash -c 'zcat /usr/share/zabbix-server-mysql/data.sql.gz | mysql --default-character-set=utf8mb4 zabbix'

echo
echo "Comprobando version de la base de datos..."
sudo mysql -e "SELECT mandatory, optional FROM zabbix.dbversion;"

echo
echo "Reiniciando servicios..."
sudo systemctl restart zabbix-server zabbix-agent apache2

echo
echo "=========================================="
echo " Base de datos Zabbix reparada"
echo "=========================================="
