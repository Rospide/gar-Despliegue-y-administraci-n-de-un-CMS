#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./fase4_desplegar_roles.sh <usuario_vm>"
  echo "Ejemplo: ./fase4_desplegar_roles.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"

ARCHIVOS=(
  "hosts.ini"
  "desplegar_galera.sh"
  "preparar_jumpstart.yml"
  "backend.yml"
  "frontend_wordpress.yml"
  "zabbix_server_backend1.yml"
  "zabbix_agents.yml"
)

echo "=============================================="
echo " FASE 4: Despliegue de roles con Ansible"
echo " Usuario VM: ${USUARIO_VM}"
echo "=============================================="
echo

echo "[1/6] Comprobando que estamos en jumpstart..."

HOSTNAME_ACTUAL="$(hostname)"

echo "Hostname actual: ${HOSTNAME_ACTUAL}"

if [[ "$HOSTNAME_ACTUAL" != "jumpstart" ]]; then
  echo "AVISO: Este script está pensado para ejecutarse dentro de jumpstart."
  echo "Si no estás en jumpstart, sal con exit y entra con:"
  echo "ssh -p 2225 ${USUARIO_VM}@127.0.0.1"
  exit 1
fi

echo
echo "[2/6] Comprobando archivos necesarios..."

for ARCHIVO in "${ARCHIVOS[@]}"; do
  if [[ ! -f "$ARCHIVO" ]]; then
    echo "ERROR: No existe $ARCHIVO en la home de jumpstart."
    exit 1
  fi
done

echo "Todos los archivos existen."
echo

echo "[3/6] Dando permisos a desplegar_galera.sh..."

chmod +x desplegar_galera.sh

echo
echo "[4/6] Desplegando MariaDB Galera en backend1 y backend2..."
echo "Este paso puede pedir contraseña sudo."

./desplegar_galera.sh "$USUARIO_VM"

echo
echo "[5/6] Desplegando WordPress en frontend1 y frontend2..."

ansible-playbook -i hosts.ini frontend_wordpress.yml --syntax-check
ansible-playbook -i hosts.ini frontend_wordpress.yml -K

echo
echo "[6/6] Desplegando Zabbix Server y agentes..."

echo
echo "Instalando Zabbix Server en backend1..."
ansible-playbook -i hosts.ini zabbix_server_backend1.yml --syntax-check
ansible-playbook -i hosts.ini zabbix_server_backend1.yml -K

echo
echo "Instalando agentes Zabbix en el resto de nodos..."
ansible-playbook -i hosts.ini zabbix_agents.yml --syntax-check
ansible-playbook -i hosts.ini zabbix_agents.yml -K

echo
echo "=============================================="
echo " FASE 4 completada correctamente"
echo "=============================================="
echo
echo "Comprobaciones recomendadas:"
echo
echo "1) Galera:"
echo "ssh ${USUARIO_VM}@10.10.10.20"
echo "sudo mysql -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\""
echo
echo "2) WordPress:"
echo "curl -I http://10.0.0.10"
echo "curl -I http://10.0.0.11"
echo
echo "3) Zabbix:"
echo "Desde el PC anfitrión abre:"
echo "http://192.168.56.20/zabbix"
echo
echo "Usuario: Admin"
echo "Contraseña: zabbix"
