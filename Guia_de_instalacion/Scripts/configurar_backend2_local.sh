#!/usr/bin/env bash

set -euo pipefail

SCRIPT="configurar_backend_red.sh"
CARPETA_COMPARTIDA="CompartidaVM"
MOUNT_POINT="/mnt/compartida"

echo "Montando carpeta compartida..."
sudo mkdir -p "$MOUNT_POINT"
sudo mount -t vboxsf "$CARPETA_COMPARTIDA" "$MOUNT_POINT"

if [[ ! -f "$MOUNT_POINT/$SCRIPT" ]]; then
  echo "ERROR: No existe $SCRIPT en $MOUNT_POINT"
  echo "Comprueba que la carpeta compartida de VirtualBox se llama CompartidaVM."
  exit 1
fi

echo "Copiando script a la home..."
cp "$MOUNT_POINT/$SCRIPT" ~/

echo "Dando permisos..."
chmod +x ~/"$SCRIPT"

echo "Configurando backend2..."
sudo ~/"$SCRIPT" backend2 10.10.10.21

echo "backend2 configurado."
