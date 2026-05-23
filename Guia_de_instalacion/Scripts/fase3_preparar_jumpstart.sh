#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./fase3_preparar_jumpstart.sh <usuario_vm>"
  echo "Ejemplo: ./fase3_preparar_jumpstart.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"
PUERTO_JUMPSTART="2225"
HOST_JUMPSTART="127.0.0.1"

ARCHIVOS=(
  "configurar_jumpstart.sh"
  "preparar_ansible.sh"
  "preparar_jumpstart.yml"
  "backend.yml"
  "desplegar_galera.sh"
  "frontend_wordpress.yml"
  "zabbix_server_backend1.yml"
  "zabbix_agents.yml"
  "limpiar_bloqueos_apt.yml"
  "configurar_apt_proxy_backends.yml"
  "hosts.ini"
  "fase4_desplegar_roles.sh"
  "probar_balanceador.sh"
  "comprobar_despliegue_final.sh"
  "reset_fase4.sh"
)

echo "=============================================="
echo " FASE 3: Preparación del nodo Jumpstart"
echo " Usuario VM: ${USUARIO_VM}"
echo "=============================================="
echo

echo "[1/5] Comprobando archivos necesarios..."

for ARCHIVO in "${ARCHIVOS[@]}"; do
  if [[ ! -f "$ARCHIVO" ]]; then
    echo "ERROR: No existe $ARCHIVO en esta carpeta."
    echo "Ejecuta este script desde la carpeta donde tienes los playbooks y scripts."
    exit 1
  fi
done

echo "Todos los archivos existen."
echo

echo "[2/5] Copiando archivos a jumpstart..."

scp -o StrictHostKeyChecking=accept-new \
    -P "$PUERTO_JUMPSTART" \
    "${ARCHIVOS[@]}" \
    "${USUARIO_VM}@${HOST_JUMPSTART}:~/"

echo
echo "[3/5] Configurando jumpstart..."
echo "Te pedirá la contraseña sudo de la VM."

ssh -o StrictHostKeyChecking=accept-new \
    -p "$PUERTO_JUMPSTART" \
    -tt "${USUARIO_VM}@${HOST_JUMPSTART}" \
    "chmod +x configurar_jumpstart.sh && sudo ./configurar_jumpstart.sh jumpstart"

echo
echo "[4/5] Preparando permisos de scripts en jumpstart..."

ssh -o StrictHostKeyChecking=accept-new \
    -p "$PUERTO_JUMPSTART" \
    -tt "${USUARIO_VM}@${HOST_JUMPSTART}" \
    "chmod +x preparar_ansible.sh desplegar_galera.sh fase4_desplegar_roles.sh probar_balanceador.sh comprobar_despliegue_final.sh"

echo
echo "[5/5] Ejecutando preparar_ansible.sh..."
echo "Durante este paso ssh-copy-id puede pedir la contraseña de las VMs."

ssh -o StrictHostKeyChecking=accept-new \
    -p "$PUERTO_JUMPSTART" \
    -tt "${USUARIO_VM}@${HOST_JUMPSTART}" \
    "./preparar_ansible.sh ${USUARIO_VM}"

echo
echo "=============================================="
echo " FASE 3 completada correctamente"
echo "=============================================="
echo
echo "Ahora entra en jumpstart:"
echo "ssh -p ${PUERTO_JUMPSTART} ${USUARIO_VM}@127.0.0.1"
echo
echo "Y ejecuta la fase 4:"
echo "./fase4_desplegar_roles.sh ${USUARIO_VM}"
