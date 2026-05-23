#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./probar_balanceador.sh <usuario_vm>"
  echo "Ejemplo: ./probar_balanceador.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"

FRONTEND1_IP="10.0.0.10"
FRONTEND2_IP="10.0.0.11"
BALANCEADOR_IP="10.0.0.1"

echo "========================================"
echo " Prueba de balanceador"
echo "========================================"
echo

echo "[1/4] Creando origen.txt en frontend1..."
ssh -tt "${USUARIO_VM}@${FRONTEND1_IP}" \
  "echo 'SOY FRONTEND1' | sudo tee /var/www/html/origen.txt >/dev/null && curl -s http://localhost/origen.txt"

echo
echo "[2/4] Creando origen.txt en frontend2..."
ssh -tt "${USUARIO_VM}@${FRONTEND2_IP}" \
  "echo 'SOY FRONTEND2' | sudo tee /var/www/html/origen.txt >/dev/null && curl -s http://localhost/origen.txt"

echo
echo "[3/4] Comprobando que WordPress responde desde el balanceador..."
ssh "${USUARIO_VM}@${BALANCEADOR_IP}" \
  "curl -I http://localhost"

echo
echo "[4/4] Probando balanceo con /origen.txt..."
ssh "${USUARIO_VM}@${BALANCEADOR_IP}" "
  curl -s http://localhost/origen.txt
  curl -s http://localhost/origen.txt
  curl -s http://localhost/origen.txt
  curl -s http://localhost/origen.txt
  curl -s http://localhost/origen.txt
  curl -s http://localhost/origen.txt
"

echo
echo "========================================"
echo " Prueba terminada"
echo "========================================"
