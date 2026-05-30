#!/bin/bash

set -e

BASE_VM="base-ubuntu"
VM_NAME="backend1"
HOSTONLY_IFACE="vboxnet0"

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

echo "[3/6] Comprobando adaptador solo anfitrión $HOSTONLY_IFACE..."

if ! VBoxManage list hostonlyifs | grep -q "Name:.*$HOSTONLY_IFACE"; then
    echo "No existe $HOSTONLY_IFACE. Creándolo..."
    VBoxManage hostonlyif create
    VBoxManage hostonlyif ipconfig "$HOSTONLY_IFACE" --ip 192.168.56.1 --netmask 255.255.255.0
else
    echo "$HOSTONLY_IFACE ya existe."
fi

echo "[4/6] Configurando red de $VM_NAME..."

# Adaptador 1: red internal para backend1
VBoxManage modifyvm "$VM_NAME" --nic1 intnet
VBoxManage modifyvm "$VM_NAME" --intnet1 internal
VBoxManage modifyvm "$VM_NAME" --cableconnected1 on

# Adaptador 2: solo anfitrión para acceder a Zabbix desde el PC anfitrión
VBoxManage modifyvm "$VM_NAME" --nic2 hostonly
VBoxManage modifyvm "$VM_NAME" --hostonlyadapter2 "$HOSTONLY_IFACE"
VBoxManage modifyvm "$VM_NAME" --cableconnected2 on

# No usar más adaptadores
VBoxManage modifyvm "$VM_NAME" --nic3 none
VBoxManage modifyvm "$VM_NAME" --nic4 none

echo "[5/6] Reconfigurando MACs..."

VBoxManage modifyvm "$VM_NAME" --macaddress1 auto
VBoxManage modifyvm "$VM_NAME" --macaddress2 auto

echo "[6/6] Arrancando $VM_NAME..."

VBoxManage startvm "$VM_NAME" --type gui

echo
echo "backend1 creado y arrancado."
echo
echo "Configuración esperada:"
echo "- Adaptador 1: Red interna internal"
echo "- IP futura internal: 10.10.10.20/24"
echo "- Ruta a main: 10.0.0.0/24 vía 10.10.10.100"
echo
echo "- Adaptador 2: Solo anfitrión $HOSTONLY_IFACE"
echo "- IP futura host-only: 192.168.56.20/24"
echo "- Esta red solo sirve para acceder a Zabbix desde el PC anfitrión"
echo "- No da salida directa a Internet al backend"
echo
echo "Siguiente paso:"
echo "Ejecutar dentro de backend1:"
echo "sudo ./configurar_backend_red.sh backend1 10.10.10.20"
echo
echo "La IP 192.168.56.20 se configurará después automáticamente con zabbix_server_backend1.yml"
