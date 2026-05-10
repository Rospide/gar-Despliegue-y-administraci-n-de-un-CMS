#!/bin/bash

set -e

BASE_VM="base-ubuntu"
VM_NAME="backend1"

echo "[1/5] Comprobando si existe $VM_NAME..."

if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    echo "La VM $VM_NAME ya existe. No se clona."
else
    echo "[2/5] Clonando $BASE_VM como $VM_NAME..."
    VBoxManage clonevm "$BASE_VM" \
        --name "$VM_NAME" \
        --register \
        --mode all
fi

echo "[3/5] Configurando red de $VM_NAME..."

VBoxManage modifyvm "$VM_NAME" --nic1 intnet
VBoxManage modifyvm "$VM_NAME" --intnet1 internal

# Aseguramos que no haya adaptadores extra activos
VBoxManage modifyvm "$VM_NAME" --nic2 none
VBoxManage modifyvm "$VM_NAME" --nic3 none
VBoxManage modifyvm "$VM_NAME" --nic4 none

echo "[4/5] Reconfigurando MAC..."

VBoxManage modifyvm "$VM_NAME" --macaddress1 auto

echo "[5/5] Arrancando $VM_NAME..."

VBoxManage startvm "$VM_NAME" --type gui

echo
echo "backend1 creado y arrancado."
echo
echo "Configuración esperada:"
echo "- Adaptador 1: Red interna internal"
echo "- IP futura: 10.10.10.20/24"
echo "- Ruta a main: 10.0.0.0/24 vía 10.10.10.100"
echo
echo "Siguiente paso:"
echo "Ejecutar dentro de backend1 el script configurar_backend_red.sh"
