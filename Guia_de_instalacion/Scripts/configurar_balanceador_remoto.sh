#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./configurar_balanceador_remoto.sh <usuario_vm>"
  echo "Ejemplo: ./configurar_balanceador_remoto.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"
PUERTO="2226"
SCRIPT="configurar_balanceador.sh"

if [[ ! -f "$SCRIPT" ]]; then
  echo "ERROR: No existe $SCRIPT en esta carpeta."
  exit 1
fi

echo "Copiando $SCRIPT al balanceador..."
scp -P "$PUERTO" "$SCRIPT" "${USUARIO_VM}@127.0.0.1:~/"

echo "Ejecutando configuración en balanceador..."
ssh -p "$PUERTO" -t "${USUARIO_VM}@127.0.0.1" \
  "chmod +x $SCRIPT && sudo ./$SCRIPT balanceador"

echo "Balanceador configurado."
