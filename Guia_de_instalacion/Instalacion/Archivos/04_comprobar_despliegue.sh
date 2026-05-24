#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./05_comprobar_despliegue.sh <usuario_vm>"
  echo "Ejemplo: ./05_comprobar_despliegue.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"

BACKEND1_IP="10.10.10.20"
FRONTEND1_IP="10.0.0.10"
FRONTEND2_IP="10.0.0.11"
BALANCEADOR_IP="10.0.0.1"

echo "=========================================="
echo " COMPROBACIÓN FINAL DEL DESPLIEGUE GAR"
echo " Usuario VM: ${USUARIO_VM}"
echo "=========================================="
echo

echo "[1/4] Comprobando Galera en backend1..."
echo "Puede pedir contraseña sudo de backend1."
echo

ssh -tt "${USUARIO_VM}@${BACKEND1_IP}" "
  echo '--- wsrep_cluster_size ---'
  sudo mysql -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\"

  echo '--- wsrep_cluster_status ---'
  sudo mysql -e \"SHOW STATUS LIKE 'wsrep_cluster_status';\"

  echo '--- wsrep_ready ---'
  sudo mysql -e \"SHOW STATUS LIKE 'wsrep_ready';\"
"

echo
echo "Resultado esperado:"
echo "wsrep_cluster_size = 2"
echo "wsrep_cluster_status = Primary"
echo "wsrep_ready = ON"
echo

echo "------------------------------------------"
echo "[2/4] Comprobando WordPress en frontend1 y frontend2..."
echo

echo "frontend1:"
curl -I "http://${FRONTEND1_IP}" || true

echo
echo "frontend2:"
curl -I "http://${FRONTEND2_IP}" || true

echo
echo "Resultado esperado: HTTP/1.1 302 Found o HTTP/1.1 200 OK"
echo

echo "------------------------------------------"
echo "[3/4] Comprobando balanceador..."
echo

curl -I "http://${BALANCEADOR_IP}" || true

echo
echo "Resultado esperado:"
echo "HTTP/1.1 302 Found"
echo "X-Redirect-By: WordPress"
echo

echo "------------------------------------------"
echo "[4/4] Probando balanceo entre frontend1 y frontend2..."
echo

echo "Creando origen.txt en frontend1..."
ssh -tt "${USUARIO_VM}@${FRONTEND1_IP}" "
  echo 'SOY FRONTEND1' | sudo tee /var/www/html/origen.txt >/dev/null
  curl -s http://localhost/origen.txt
"

echo
echo "Creando origen.txt en frontend2..."
ssh -tt "${USUARIO_VM}@${FRONTEND2_IP}" "
  echo 'SOY FRONTEND2' | sudo tee /var/www/html/origen.txt >/dev/null
  curl -s http://localhost/origen.txt
"

echo
echo "Probando balanceador varias veces:"
echo

curl -s "http://${BALANCEADOR_IP}/origen.txt" || true
curl -s "http://${BALANCEADOR_IP}/origen.txt" || true
curl -s "http://${BALANCEADOR_IP}/origen.txt" || true
curl -s "http://${BALANCEADOR_IP}/origen.txt" || true
curl -s "http://${BALANCEADOR_IP}/origen.txt" || true
curl -s "http://${BALANCEADOR_IP}/origen.txt" || true

echo
echo "=========================================="
echo " COMPROBACIÓN FINAL TERMINADA"
echo "=========================================="
echo
echo "Debe haberse visto:"
echo "- Galera con cluster_size = 2"
echo "- WordPress respondiendo en frontend1 y frontend2"
echo "- Balanceador devolviendo 302 Found o 200 OK"
echo "- SOY FRONTEND1 y SOY FRONTEND2 en la prueba de balanceo"
echo
echo "Desde el PC anfitrión también puedes comprobar:"
echo "curl -I http://127.0.0.1:8080"
echo "o abrir en Firefox:"
echo "http://127.0.0.1:8080"
