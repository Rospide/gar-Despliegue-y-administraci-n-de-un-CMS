#!/usr/bin/env bash

set -u

USUARIO_VM="${1:-$(whoami)}"
INV="hosts.ini"

DB_HOST="10.10.10.20"
DB_USER="wordpress_user"
DB_PASS="wordpress_pass"
DB_NAME="wordpress_db"

echo "=========================================="
echo " COMPROBACIÓN FINAL COMPLETA GAR"
echo " Usuario VM: ${USUARIO_VM}"
echo "=========================================="

if [[ ! -f "$INV" ]]; then
  echo "ERROR: No existe hosts.ini. Ejecuta este script desde jumpstart."
  exit 1
fi

seccion() {
  echo
  echo "------------------------------------------"
  echo "$1"
  echo "------------------------------------------"
}

seccion "[1/8] Comprobando WordPress en frontend1 y frontend2"

echo "frontend1:"
curl -I http://10.0.0.10 || true

echo
echo "frontend2:"
curl -I http://10.0.0.11 || true

seccion "[2/8] Comprobando balanceador"

curl -I http://10.0.0.1 || true

seccion "[3/8] Probando balanceo frontend1/frontend2"

ansible -i "$INV" frontend1 -b -K -m shell -a "echo 'SOY FRONTEND1' > /var/www/html/origen.txt"
ansible -i "$INV" frontend2 -b -K -m shell -a "echo 'SOY FRONTEND2' > /var/www/html/origen.txt"

echo
echo "Probando balanceador varias veces:"
for i in {1..6}; do
  curl -s http://10.0.0.1/origen.txt || true
  echo
done

seccion "[4/8] Comprobando SSH/Ansible hacia todos los nodos"

ansible -i "$INV" all -m ping

echo
echo "Hostnames e IPs:"
ansible -i "$INV" all -m shell -a "echo HOST=\$(hostname); ip -br a | grep -E '10\.0\.0\.|10\.10\.10\.' || true"

seccion "[5/8] Asegurando Zabbix Agent en balanceador y router-linux"

ansible -i "$INV" infra -b -K -m shell -a "apt-get update; DEBIAN_FRONTEND=noninteractive apt-get install -y zabbix-agent; sed -i 's/^Server=.*/Server=10.10.10.20/' /etc/zabbix/zabbix_agentd.conf; sed -i 's/^ServerActive=.*/ServerActive=10.10.10.20/' /etc/zabbix/zabbix_agentd.conf; sed -i \"s/^Hostname=.*/Hostname=\$(hostname)/\" /etc/zabbix/zabbix_agentd.conf; ufw allow 10050/tcp || true; systemctl enable zabbix-agent; systemctl restart zabbix-agent; systemctl is-active zabbix-agent"

seccion "[6/8] Comprobando puertos relevantes"

check_port() {
  local IP="$1"
  local PORT="$2"
  local NAME="$3"

  if nc -z -w 3 "$IP" "$PORT" >/dev/null 2>&1; then
    echo "OK   ${NAME} (${IP}:${PORT}) accesible"
  else
    echo "FAIL ${NAME} (${IP}:${PORT}) no accesible"
  fi
}

check_port "10.0.0.1" "80" "balanceador HTTP"
check_port "10.0.0.10" "80" "frontend1 HTTP"
check_port "10.0.0.11" "80" "frontend2 HTTP"
check_port "10.10.10.20" "3306" "backend1 MariaDB"
check_port "10.10.10.21" "3306" "backend2 MariaDB"
check_port "10.10.10.20" "4567" "backend1 Galera"
check_port "10.10.10.21" "4567" "backend2 Galera"
check_port "10.10.10.20" "10051" "Zabbix Server"
check_port "10.0.0.10" "10050" "Zabbix Agent frontend1"
check_port "10.0.0.11" "10050" "Zabbix Agent frontend2"
check_port "10.10.10.20" "10050" "Zabbix Agent backend1"
check_port "10.10.10.21" "10050" "Zabbix Agent backend2"
check_port "10.0.0.1" "10050" "Zabbix Agent balanceador"
check_port "10.0.0.254" "10050" "Zabbix Agent router-linux"

seccion "[7/8] Firewall y aislamiento de internal"

ansible -i "$INV" all -b -K -m shell -a "echo HOST=\$(hostname); echo '--- UFW ---'; ufw status verbose || true; echo '--- Puertos escuchando ---'; ss -tuln | grep -E ':(22|80|3306|4444|4567|4568|10050|10051)[[:space:]]' || true"

echo
echo "Comprobando que backend1/backend2 NO tienen Internet directo:"
ansible -i "$INV" backends -m shell -a "echo HOST=\$(hostname); ping -c 2 -W 2 8.8.8.8 >/dev/null 2>&1 && echo 'ERROR: este backend tiene Internet directo' || echo 'OK: no tiene Internet directo por ping'"

echo
echo "Comprobando que frontends llegan a internal:"
ansible -i "$INV" frontends -m shell -a "ping -c 2 -W 2 ${DB_HOST} >/dev/null 2>&1 && echo 'OK: frontend llega a backend1' || echo 'ERROR: frontend no llega a backend1'"

seccion "[8/8] WordPress conectado a la base de datos desde ambos frontends"

ansible -i "$INV" frontends -m shell -a "mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} -N -e 'SHOW DATABASES;' 2>/dev/null | grep -q '${DB_NAME}' && echo 'OK: WordPress puede acceder a ${DB_NAME}' || echo 'ERROR: no aparece ${DB_NAME}'"

echo
echo "=========================================="
echo " COMPROBACIÓN FINAL COMPLETA TERMINADA"
echo "=========================================="
echo
echo "Debe haberse visto:"
echo "- WordPress respondiendo en frontend1/frontend2"
echo "- Balanceador respondiendo"
echo "- Balanceo con SOY FRONTEND1 y SOY FRONTEND2"
echo "- Ansible SUCCESS/pong en todos los nodos"
echo "- Puertos HTTP, MariaDB, Galera y Zabbix OK"
echo "- Backends sin Internet directo"
echo "- Frontends accediendo a wordpress_db"
echo
echo "Comprobación Galera manual recomendada:"
echo "ssh ${USUARIO_VM}@10.10.10.20"
echo "sudo mysql -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\""
echo "sudo mysql -e \"SHOW STATUS LIKE 'wsrep_cluster_status';\""
echo "sudo mysql -e \"SHOW STATUS LIKE 'wsrep_ready';\""
echo
echo "Desde el PC anfitrión:"
echo "curl -I http://127.0.0.1:8080"
echo
echo "WordPress:"
echo "http://127.0.0.1:8080/wp-admin/install.php"
echo
echo "Zabbix:"
echo "http://192.168.56.20/zabbix"
