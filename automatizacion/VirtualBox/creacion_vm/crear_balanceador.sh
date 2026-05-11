#!/bin/bash

set -e

BASE_VM="base-ubuntu"
VM_NAME="balanceador"
SSH_PORT="2226"
WEB_PORT="8080"

if [ -z "$1" ]; then
    echo "Uso: ./crear_balanceador.sh <usuario_vm>"
    echo "Ejemplo: ./crear_balanceador.sh alumno"
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

# Adaptador 1: NAT
VBoxManage modifyvm "$VM_NAME" --nic1 nat

# Adaptador 2: Red interna main
VBoxManage modifyvm "$VM_NAME" --nic2 intnet
VBoxManage modifyvm "$VM_NAME" --intnet2 main

echo "[4/6] Reconfigurando MACs..."

VBoxManage modifyvm "$VM_NAME" --macaddress1 auto
VBoxManage modifyvm "$VM_NAME" --macaddress2 auto

echo "[5/6] Configurando redirecciones temporales por NAT..."

VBoxManage modifyvm "$VM_NAME" --natpf1 delete "ssh-balanceador" 2>/dev/null || true
VBoxManage modifyvm "$VM_NAME" --natpf1 delete "web-balanceador" 2>/dev/null || true

VBoxManage modifyvm "$VM_NAME" --natpf1 "ssh-balanceador,tcp,,${SSH_PORT},,22"
VBoxManage modifyvm "$VM_NAME" --natpf1 "web-balanceador,tcp,,${WEB_PORT},,80"

echo "[6/6] Arrancando $VM_NAME..."

VBoxManage startvm "$VM_NAME" --type gui

echo
echo "Balanceador creado y arrancado."
echo
echo "Cuando termine de arrancar, entra con:"
echo "ssh -p ${SSH_PORT} ${VM_USER}@127.0.0.1"
echo
echo "Para copiar el script de configuración:"
echo "scp -P ${SSH_PORT} configurar_balanceador.sh ${VM_USER}@127.0.0.1:~/"
echo
echo "Una vez configurado, la web debería quedar accesible desde el host en:"
echo "http://127.0.0.1:${WEB_PORT}"
