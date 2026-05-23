#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./configurar_router_linux_remoto.sh <usuario_vm>"
  echo "Ejemplo: ./configurar_router_linux_remoto.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"
PUERTO="2227"
SCRIPT="configurar_router_linux.sh"

if [[ ! -f "$SCRIPT" ]]; then
  echo "ERROR: No existe $SCRIPT en esta carpeta."
  exit 1
fi

echo "Copiando $SCRIPT a Router-Linux..."
scp -P "$PUERTO" "$SCRIPT" "${USUARIO_VM}@127.0.0.1:~/"

echo "Ejecutando configuración en Router-Linux..."
ssh -p "$PUERTO" -t "${USUARIO_VM}@127.0.0.1" \
  "chmod +x $SCRIPT && sudo ./$SCRIPT router-linux"

echo "Router-Linux configurado."
