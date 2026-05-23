#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./configurar_frontend1_remoto.sh <usuario_vm>"
  echo "Ejemplo: ./configurar_frontend1_remoto.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"
PUERTO="2210"
SCRIPT="configurar_frontend.sh"

if [[ ! -f "$SCRIPT" ]]; then
  echo "ERROR: No existe $SCRIPT en esta carpeta."
  exit 1
fi

echo "Copiando $SCRIPT a frontend1..."
scp -P "$PUERTO" "$SCRIPT" "${USUARIO_VM}@127.0.0.1:~/"

echo "Ejecutando configuración en frontend1..."
ssh -p "$PUERTO" -t "${USUARIO_VM}@127.0.0.1" \
  "chmod +x $SCRIPT && sudo ./$SCRIPT frontend1 10.0.0.10"

echo "frontend1 configurado."
