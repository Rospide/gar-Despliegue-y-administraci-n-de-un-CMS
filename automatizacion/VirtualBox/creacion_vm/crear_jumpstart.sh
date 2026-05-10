#!/bin/bash

set -e

BASE_VM="base-ubuntu"
VM_NAME="jumpstart"
SSH_PORT="2225"

if [ -z "$1" ]; then
    echo "Uso: ./crear_jumpstart.sh <usuario_vm>"
    echo "Ejemplo: ./crear_jumpstart.sh alumno"
    exit 1
fi

VM_USER="$1"

echo "[1/6] Comprobando si existe $VM_NAME..."

if VBoxManage list vms | grep -q "\"$VM_NAME\""; then
    echo "La VM $VM_NAME ya existe. No se clona."
else
    echo "[2/6] Clonando $BASE_VM como $VM_NAME..."
    VBoxManage clonevm "$BASE_VM" \
        --name "$VM_NAME" \
        --register \
        --mode all
fi

echo "[3/6] Configurando adaptadores de red..."

VBoxManage modifyvm "$VM_NAME" --nic1 nat

VBoxManage modifyvm "$VM_NAME" --nic2 intnet
VBoxManage modifyvm "$VM_NAME" --intnet2 main

VBoxManage modifyvm "$VM_NAME" --nic3 intnet
VBoxManage modifyvm "$VM_NAME" --intnet3 internal

echo "[4/6] Reconfigurando MACs..."

VBoxManage modifyvm "$VM_NAME" --macaddress1 auto
VBoxManage modifyvm "$VM_NAME" --macaddress2 auto
VBoxManage modifyvm "$VM_NAME" --macaddress3 auto

echo "[5/6] Configurando redirección SSH temporal por NAT..."

VBoxManage modifyvm "$VM_NAME" --natpf1 delete "ssh-jumpstart" 2>/dev/null || true
VBoxManage modifyvm "$VM_NAME" --natpf1 "ssh-jumpstart,tcp,,${SSH_PORT},,22"

echo "[6/6] Arrancando $VM_NAME..."

VBoxManage startvm "$VM_NAME" --type gui

echo
echo "jumpstart creado y arrancado."
echo
echo "Cuando termine de arrancar, entra con:"
echo "ssh -p ${SSH_PORT} ${VM_USER}@127.0.0.1"
echo
echo "Para copiar el script de configuración:"
echo "scp -P ${SSH_PORT} configurar_jumpstart.sh ${VM_USER}@127.0.0.1:~/"
