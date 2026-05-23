#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./configurar_frontend2_remoto.sh <usuario_vm>"
  echo "Ejemplo: ./configurar_frontend2_remoto.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"
PUERTO="2211"
SCRIPT="configurar_frontend.sh"

if [[ ! -f "$SCRIPT" ]]; then
  echo "ERROR: No existe $SCRIPT en esta carpeta."
  exit 1
fi

echo "Copiando $SCRIPT a frontend2..."
scp -P "$PUERTO" "$SCRIPT" "${USUARIO_VM}@127.0.0.1:~/"

echo "Ejecutando configuración en frontend2..."
ssh -p "$PUERTO" -t "${USUARIO_VM}@127.0.0.1" \
  "chmod +x $SCRIPT && sudo ./$SCRIPT frontend2 10.0.0.11"

echo "frontend2 configurado."
