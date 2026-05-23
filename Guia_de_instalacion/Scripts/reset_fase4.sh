#!/usr/bin/env bash

set -e

echo "========================================"
echo " Limpieza de Fase 4"
echo "========================================"
echo

echo "[1/2] Limpiando frontends..."

ansible -i hosts.ini frontends -b -K -m shell -a 'systemctl stop unattended-upgrades 2>/dev/null || true; systemctl stop apt-daily.service 2>/dev/null || true; systemctl stop apt-daily-upgrade.service 2>/dev/null || true; systemctl stop apt-daily.timer 2>/dev/null || true; systemctl stop apt-daily-upgrade.timer 2>/dev/null || true; systemctl disable apt-daily.timer 2>/dev/null || true; systemctl disable apt-daily-upgrade.timer 2>/dev/null || true; pkill -9 apt 2>/dev/null || true; pkill -9 apt-get 2>/dev/null || true; pkill -9 dpkg 2>/dev/null || true; rm -f /var/lib/dpkg/lock-frontend; rm -f /var/lib/dpkg/lock; rm -f /var/cache/apt/archives/lock; dpkg --configure -a || true; apt clean || true; rm -rf /var/www/html/*; rm -rf /tmp/wordpress'

echo
echo "[2/2] Limpiando Zabbix parcial en backend1..."

ansible -i hosts.ini zabbix_server -b -K -m shell -a 'systemctl stop zabbix-server zabbix-agent apache2 2>/dev/null || true; mysql -e "DROP DATABASE IF EXISTS zabbix;" || true; mysql -e "DROP USER IF EXISTS '\''zabbix'\''@'\''localhost'\'';" || true; rm -f /etc/zabbix/zabbix.conf.php; rm -f /etc/zabbix/web/zabbix.conf.php; rm -f /var/lib/dpkg/lock-frontend; rm -f /var/lib/dpkg/lock; rm -f /var/cache/apt/archives/lock; dpkg --configure -a || true; apt clean || true'

echo
echo "========================================"
echo " Limpieza terminada"
echo "========================================"
echo
echo "Ahora ejecuta:"
echo "./fase4_desplegar_roles.sh alejandroro"
