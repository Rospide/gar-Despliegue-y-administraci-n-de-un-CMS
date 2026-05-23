#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./crear_todas_las_vm.sh <usuario_vm>"
  echo "Ejemplo: ./crear_todas_las_vm.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"

echo "======================================"
echo " Creación automática de todas las VMs"
echo " Usuario VM: ${USUARIO_VM}"
echo "======================================"
echo

SCRIPTS=(
  "crear_jumpstart.sh"
  "crear_balanceador.sh"
  "crear_frontend1.sh"
  "crear_frontend2.sh"
  "crear_backend1.sh"
  "crear_backend2.sh"
  "crear_router_linux.sh"
)

echo "[1/6] Comprobando scripts..."

for SCRIPT in "${SCRIPTS[@]}"; do
  if [[ ! -f "$SCRIPT" ]]; then
    echo "ERROR: No existe $SCRIPT en esta carpeta."
    exit 1
  fi
done

chmod +x "${SCRIPTS[@]}"

echo
echo "[2/6] Creando máquinas virtuales..."
echo

./crear_jumpstart.sh "$USUARIO_VM"
./crear_balanceador.sh "$USUARIO_VM"
./crear_frontend1.sh "$USUARIO_VM"
./crear_frontend2.sh "$USUARIO_VM"
./crear_backend1.sh
./crear_backend2.sh
./crear_router_linux.sh "$USUARIO_VM"

echo
echo "[3/6] Apagando VMs para poder cambiar la RAM..."
echo

VBoxManage controlvm jumpstart poweroff 2>/dev/null || true
VBoxManage controlvm balanceador poweroff 2>/dev/null || true
VBoxManage controlvm frontend1 poweroff 2>/dev/null || true
VBoxManage controlvm frontend2 poweroff 2>/dev/null || true
VBoxManage controlvm backend1 poweroff 2>/dev/null || true
VBoxManage controlvm backend2 poweroff 2>/dev/null || true
VBoxManage controlvm "Router-Linux" poweroff 2>/dev/null || true

sleep 5

echo
echo "[4/6] Ajustando memoria RAM..."
echo

VBoxManage modifyvm jumpstart --memory 2048

VBoxManage modifyvm balanceador --memory 1024
VBoxManage modifyvm frontend1 --memory 1024
VBoxManage modifyvm frontend2 --memory 1024
VBoxManage modifyvm backend1 --memory 1024
VBoxManage modifyvm backend2 --memory 1024
VBoxManage modifyvm "Router-Linux" --memory 1024

echo
echo "[5/6] Arrancando VMs otra vez..."
echo

VBoxManage startvm jumpstart --type gui
VBoxManage startvm balanceador --type gui
VBoxManage startvm frontend1 --type gui
VBoxManage startvm frontend2 --type gui
VBoxManage startvm backend1 --type gui
VBoxManage startvm backend2 --type gui
VBoxManage startvm "Router-Linux" --type gui

echo
echo "[6/6] Resumen de RAM configurada:"
echo

echo "jumpstart:"
VBoxManage showvminfo jumpstart --machinereadable | grep '^memory='

echo "balanceador:"
VBoxManage showvminfo balanceador --machinereadable | grep '^memory='

echo "frontend1:"
VBoxManage showvminfo frontend1 --machinereadable | grep '^memory='

echo "frontend2:"
VBoxManage showvminfo frontend2 --machinereadable | grep '^memory='

echo "backend1:"
VBoxManage showvminfo backend1 --machinereadable | grep '^memory='

echo "backend2:"
VBoxManage showvminfo backend2 --machinereadable | grep '^memory='

echo "Router-Linux:"
VBoxManage showvminfo "Router-Linux" --machinereadable | grep '^memory='

echo
echo "======================================"
echo " Todas las VMs han sido creadas"
echo "======================================"
echo
echo "RAM esperada:"
echo "- jumpstart:     2048 MB"
echo "- balanceador:   1024 MB"
echo "- frontend1:     1024 MB"
echo "- frontend2:     1024 MB"
echo "- backend1:      1024 MB"
echo "- backend2:      1024 MB"
echo "- Router-Linux:  1024 MB"
echo
echo "Puertos SSH temporales:"
echo "- frontend1:     ssh -p 2210 ${USUARIO_VM}@127.0.0.1"
echo "- frontend2:     ssh -p 2211 ${USUARIO_VM}@127.0.0.1"
echo "- jumpstart:     ssh -p 2225 ${USUARIO_VM}@127.0.0.1"
echo "- balanceador:   ssh -p 2226 ${USUARIO_VM}@127.0.0.1"
echo "- router-linux:  ssh -p 2227 ${USUARIO_VM}@127.0.0.1"
