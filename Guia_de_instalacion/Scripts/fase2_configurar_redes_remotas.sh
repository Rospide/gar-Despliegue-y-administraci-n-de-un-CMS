#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./fase2_configurar_redes_remotas.sh <usuario_vm>"
  echo "Ejemplo: ./fase2_configurar_redes_remotas.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"

echo "=========================================="
echo " FASE 2: Configuración remota de redes"
echo " Usuario VM: ${USUARIO_VM}"
echo "=========================================="
echo

SCRIPTS=(
  "configurar_balanceador_remoto.sh"
  "configurar_frontend1_remoto.sh"
  "configurar_frontend2_remoto.sh"
  "configurar_router_linux_remoto.sh"
)

echo "[1/2] Comprobando scripts necesarios..."

for SCRIPT in "${SCRIPTS[@]}"; do
  if [[ ! -f "$SCRIPT" ]]; then
    echo "ERROR: No existe $SCRIPT en esta carpeta."
    exit 1
  fi
done

chmod +x "${SCRIPTS[@]}"

echo "Scripts encontrados correctamente."
echo

echo "[2/2] Ejecutando configuración de red..."
echo

echo "------------------------------------------"
echo " Configurando balanceador"
echo "------------------------------------------"
./configurar_balanceador_remoto.sh "$USUARIO_VM"

echo
echo "------------------------------------------"
echo " Configurando frontend1"
echo "------------------------------------------"
./configurar_frontend1_remoto.sh "$USUARIO_VM"

echo
echo "------------------------------------------"
echo " Configurando frontend2"
echo "------------------------------------------"
./configurar_frontend2_remoto.sh "$USUARIO_VM"

echo
echo "------------------------------------------"
echo " Configurando Router-Linux"
echo "------------------------------------------"
./configurar_router_linux_remoto.sh "$USUARIO_VM"

echo
echo "=========================================="
echo " FASE 2 remota completada"
echo "=========================================="
echo
echo "Resultado esperado:"
echo "- balanceador: 10.0.0.1"
echo "- frontend1:   10.0.0.10"
echo "- frontend2:   10.0.0.11"
echo "- router-linux main:     10.0.0.254"
echo "- router-linux internal: 10.10.10.254"
echo
echo "Ahora falta configurar backend1 y backend2 desde la consola de VirtualBox:"
echo
echo "backend1:"
echo "sudo mkdir -p /mnt/compartida"
echo "sudo mount -t vboxsf CompartidaVM /mnt/compartida"
echo "bash /mnt/compartida/configurar_backend1_local.sh"
echo
echo "backend2:"
echo "sudo mkdir -p /mnt/compartida"
echo "sudo mount -t vboxsf CompartidaVM /mnt/compartida"
echo "bash /mnt/compartida/configurar_backend2_local.sh"
