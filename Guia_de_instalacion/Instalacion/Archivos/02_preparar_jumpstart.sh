#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./02_preparar_jumpstart.sh <usuario_vm>"
  echo "Ejemplo: ./02_preparar_jumpstart.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"
PUERTO_JUMPSTART="2225"
HOST_JUMPSTART="127.0.0.1"

JUMPSTART_MAIN_IP="10.0.0.20"
JUMPSTART_INTERNAL_IP="10.10.10.10"
VIP_MAIN="10.0.0.100"
VIP_INTERNAL="10.10.10.100"

ARCHIVOS=(
  "03_desplegar_todo.sh"
  "04_comprobar_despliegue.sh"
  "reset_fase4.sh"
)

echo "=============================================="
echo " FASE 2: Preparación del nodo Jumpstart"
echo " Usuario VM: ${USUARIO_VM}"
echo "=============================================="
echo

read -rsp "Contraseña de las VMs: " VM_PASS
echo
echo

echo "[1/5] Comprobando archivos necesarios..."
for ARCHIVO in "${ARCHIVOS[@]}"; do
  if [[ ! -f "$ARCHIVO" ]]; then
    echo "ERROR: No existe $ARCHIVO en esta carpeta."
    exit 1
  fi
done

echo "Archivos encontrados correctamente."
echo

echo "[2/5] Copiando scripts principales a jumpstart..."
scp -o StrictHostKeyChecking=accept-new \
    -P "$PUERTO_JUMPSTART" \
    "${ARCHIVOS[@]}" \
    "${USUARIO_VM}@${HOST_JUMPSTART}:~/"

echo
echo "[3/5] Configurando red, routing, apt-cacher-ng, Ansible y Keepalived en jumpstart..."
echo

{
  printf '%s\n' "$VM_PASS"
  cat <<REMOTE_ROOT
set -e
export DEBIAN_FRONTEND=noninteractive

hostnamectl set-hostname jumpstart

cat > /etc/netplan/01-jumpstart.yaml <<NETPLAN
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: false
      addresses:
        - ${JUMPSTART_MAIN_IP}/24
    enp0s9:
      dhcp4: false
      addresses:
        - ${JUMPSTART_INTERNAL_IP}/24
NETPLAN

netplan generate
netplan apply

echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-gar-forward.conf
sysctl -p /etc/sysctl.d/99-gar-forward.conf

apt-get update
apt-get install -y ansible sshpass keepalived curl netcat-openbsd apt-cacher-ng

systemctl enable apt-cacher-ng
systemctl restart apt-cacher-ng

cat > /etc/keepalived/keepalived.conf <<KEEPALIVED
vrrp_instance VI_MAIN {
    state MASTER
    interface enp0s8
    virtual_router_id 51
    priority 120
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass garpass
    }
    virtual_ipaddress {
        ${VIP_MAIN}/24
    }
}

vrrp_instance VI_INTERNAL {
    state MASTER
    interface enp0s9
    virtual_router_id 52
    priority 120
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass garpass
    }
    virtual_ipaddress {
        ${VIP_INTERNAL}/24
    }
}
KEEPALIVED

systemctl restart keepalived
systemctl enable keepalived

sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw || true
ufw default allow routed || true
ufw route allow in on enp0s8 out on enp0s9 || true
ufw route allow in on enp0s9 out on enp0s8 || true
ufw allow 22/tcp || true
ufw allow vrrp || true
ufw allow 3142/tcp || true
ufw allow from 10.10.10.0/24 to any port 3142 proto tcp || true
ufw --force enable || true
iptables -P FORWARD ACCEPT || true

echo "jumpstart configurado:"
hostname
ip -br a
ip route
systemctl is-active keepalived
systemctl is-active apt-cacher-ng
ss -lntp | grep 3142 || true
REMOTE_ROOT
} | ssh -o StrictHostKeyChecking=accept-new \
        -p "$PUERTO_JUMPSTART" \
        "${USUARIO_VM}@${HOST_JUMPSTART}" \
        "sudo -S -p '' bash -s"

echo
echo "[4/5] Preparando scripts y hosts.ini en jumpstart..."

ssh -o StrictHostKeyChecking=accept-new \
    -p "$PUERTO_JUMPSTART" \
    "${USUARIO_VM}@${HOST_JUMPSTART}" \
    "bash -s" <<REMOTE_USER
set -e

chmod +x 03_desplegar_todo.sh 04_comprobar_despliegue.sh reset_fase4.sh

cat > hosts.ini <<HOSTS
[frontends]
frontend1 ansible_host=10.0.0.10
frontend2 ansible_host=10.0.0.11

[backends]
backend1 ansible_host=10.10.10.20
backend2 ansible_host=10.10.10.21

[infra]
balanceador ansible_host=10.0.0.1
router-linux ansible_host=10.0.0.254

[zabbix_server]
backend1 ansible_host=10.10.10.20

[zabbix_agent_nodes]
frontend1 ansible_host=10.0.0.10
frontend2 ansible_host=10.0.0.11
backend2 ansible_host=10.10.10.21
balanceador ansible_host=10.0.0.1
router-linux ansible_host=10.0.0.254

[all:vars]
ansible_user=${USUARIO_VM}
ansible_ssh_private_key_file=/home/${USUARIO_VM}/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
HOSTS

echo "hosts.ini creado:"
cat hosts.ini
REMOTE_USER

echo
echo "[5/5] Preparando clave SSH de Ansible..."
echo

PASS_ESCAPED=$(printf '%q' "$VM_PASS")

ssh -o StrictHostKeyChecking=accept-new \
    -p "$PUERTO_JUMPSTART" \
    "${USUARIO_VM}@${HOST_JUMPSTART}" \
    "VM_PASS=${PASS_ESCAPED} TARGET_USER=${USUARIO_VM} bash -s" <<'REMOTE_KEYS'
set -e

if [[ ! -f ~/.ssh/id_ed25519 ]]; then
  ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
fi

NODOS=(
  "10.0.0.10"
  "10.0.0.11"
  "10.10.10.20"
  "10.10.10.21"
  "10.0.0.1"
  "10.0.0.254"
)

for IP in "${NODOS[@]}"; do
  echo "Copiando clave SSH a $IP..."
  ssh-keygen -R "$IP" >/dev/null 2>&1 || true
  sshpass -p "$VM_PASS" ssh-copy-id -o StrictHostKeyChecking=no "${TARGET_USER}@${IP}" || true
done

echo
echo "Probando Ansible..."
ansible -i hosts.ini all -m ping
REMOTE_KEYS

echo
echo "=============================================="
echo " FASE 2 completada correctamente"
echo "=============================================="
echo
echo "Ahora entra en jumpstart:"
echo "ssh -p ${PUERTO_JUMPSTART} ${USUARIO_VM}@127.0.0.1"
echo
echo "Y ejecuta:"
echo "./03_desplegar_todo.sh ${USUARIO_VM}"
