#!/usr/bin/env bash

set -euo pipefail

# ======================================================
# 01 - Crear y configurar VMs GAR
# ======================================================
# Uso desde PC anfitrión:
#   ./01_crear_y_configurar_vms.sh <usuario_vm> [nombre_vm_base]
#
# Uso dentro de backend1 desde VirtualBox:
#   bash /mnt/compartida/01_crear_y_configurar_vms.sh --backend1-local
#
# Uso dentro de backend2 desde VirtualBox:
#   bash /mnt/compartida/01_crear_y_configurar_vms.sh --backend2-local
# ======================================================

FRONTEND1_IP="10.0.0.10"
FRONTEND2_IP="10.0.0.11"
BALANCEADOR_IP="10.0.0.1"
ROUTER_MAIN_IP="10.0.0.254"
ROUTER_INTERNAL_IP="10.10.10.254"
BACKEND1_IP="10.10.10.20"
BACKEND2_IP="10.10.10.21"
VIP_MAIN="10.0.0.100"
VIP_INTERNAL="10.10.10.100"
HOST_LOCAL="127.0.0.1"
HOSTONLY_IFACE="vboxnet0"

PUERTO_FRONTEND1="2210"
PUERTO_FRONTEND2="2211"
PUERTO_BALANCEADOR="2226"
PUERTO_JUMPSTART="2225"
PUERTO_ROUTER="2227"

# -----------------------------
# Backends locales
# -----------------------------
detectar_interfaz_backend() {
  ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}' | cut -d'@' -f1
}

configurar_backend_local() {
  local NOMBRE="$1"
  local IP_BACKEND="$2"
  local IFACE
  IFACE="$(detectar_interfaz_backend)"

  echo "=========================================="
  echo " Configurando ${NOMBRE}"
  echo " Interfaz detectada: ${IFACE}"
  echo " IP: ${IP_BACKEND}"
  echo "=========================================="

  sudo hostnamectl set-hostname "${NOMBRE}"

  sudo tee /etc/netplan/01-backend.yaml > /dev/null <<NETPLAN
network:
  version: 2
  ethernets:
    ${IFACE}:
      dhcp4: false
      addresses:
        - ${IP_BACKEND}/24
      routes:
        - to: 10.0.0.0/24
          via: ${VIP_INTERNAL}
          on-link: true
NETPLAN

  sudo netplan generate
  sudo netplan apply

  echo
  echo "Configuración aplicada en ${NOMBRE}"
  hostname
  ip -br a
  ip route
}

if [[ "${1:-}" == "--backend1-local" ]]; then
  configurar_backend_local "backend1" "${BACKEND1_IP}"
  exit 0
fi

if [[ "${1:-}" == "--backend2-local" ]]; then
  configurar_backend_local "backend2" "${BACKEND2_IP}"
  exit 0
fi

# -----------------------------
# Modo PC anfitrión
# -----------------------------
if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Uso: ./01_crear_y_configurar_vms.sh <usuario_vm> [nombre_vm_base]"
  echo "Ejemplo: ./01_crear_y_configurar_vms.sh alejandroro base-ubuntu"
  exit 1
fi

USUARIO_VM="$1"
BASE_VM="${2:-base-ubuntu}"

VMS=(jumpstart balanceador frontend1 frontend2 backend1 backend2 "Router-Linux")

declare -A SSH_PORTS=(
  [jumpstart]=2225
  [balanceador]=2226
  [frontend1]=2210
  [frontend2]=2211
  [Router-Linux]=2227
)

vm_exists() {
  VBoxManage list vms | grep -q "\"$1\""
}

clone_if_needed() {
  local vm="$1"
  echo "[VM] Comprobando $vm..."
  if vm_exists "$vm"; then
    echo "La VM $vm ya existe. No se clona."
  else
    echo "Clonando $BASE_VM como $vm..."
    VBoxManage clonevm "$BASE_VM" --name "$vm" --register --mode all
  fi
}

set_nat_rule() {
  local vm="$1" rule="$2" port="$3" guest_port="$4"
  VBoxManage modifyvm "$vm" --natpf1 delete "$rule" 2>/dev/null || true
  VBoxManage modifyvm "$vm" --natpf1 "$rule,tcp,,$port,,$guest_port"
}

ensure_hostonly() {
  if ! VBoxManage list hostonlyifs | grep -q "Name:.*$HOSTONLY_IFACE"; then
    echo "No existe $HOSTONLY_IFACE. Creándolo..."
    VBoxManage hostonlyif create
    VBoxManage hostonlyif ipconfig "$HOSTONLY_IFACE" --ip 192.168.56.1 --netmask 255.255.255.0
  fi
}

configure_vm_network() {
  local vm="$1"
  case "$vm" in
    jumpstart)
      VBoxManage modifyvm "$vm" --nic1 nat
      VBoxManage modifyvm "$vm" --nic2 intnet --intnet2 main
      VBoxManage modifyvm "$vm" --nic3 intnet --intnet3 internal
      VBoxManage modifyvm "$vm" --macaddress1 auto --macaddress2 auto --macaddress3 auto
      set_nat_rule "$vm" "ssh-jumpstart" "${SSH_PORTS[$vm]}" 22
      ;;
    balanceador)
      VBoxManage modifyvm "$vm" --nic1 nat
      VBoxManage modifyvm "$vm" --nic2 intnet --intnet2 main
      VBoxManage modifyvm "$vm" --macaddress1 auto --macaddress2 auto
      set_nat_rule "$vm" "ssh-balanceador" "${SSH_PORTS[$vm]}" 22
      set_nat_rule "$vm" "web-balanceador" 8080 80
      ;;
    frontend1|frontend2)
      VBoxManage modifyvm "$vm" --nic1 nat
      VBoxManage modifyvm "$vm" --nic2 intnet --intnet2 main
      VBoxManage modifyvm "$vm" --macaddress1 auto --macaddress2 auto
      set_nat_rule "$vm" "ssh-$vm" "${SSH_PORTS[$vm]}" 22
      ;;
    backend1)
      ensure_hostonly
      VBoxManage modifyvm "$vm" --nic1 intnet --intnet1 internal --cableconnected1 on
      VBoxManage modifyvm "$vm" --nic2 hostonly --hostonlyadapter2 "$HOSTONLY_IFACE" --cableconnected2 on
      VBoxManage modifyvm "$vm" --nic3 none --nic4 none
      VBoxManage modifyvm "$vm" --macaddress1 auto --macaddress2 auto
      ;;
    backend2)
      VBoxManage modifyvm "$vm" --nic1 intnet --intnet1 internal --cableconnected1 on
      VBoxManage modifyvm "$vm" --nic2 none --nic3 none --nic4 none
      VBoxManage modifyvm "$vm" --macaddress1 auto
      ;;
    Router-Linux)
      VBoxManage modifyvm "$vm" --nic1 nat
      VBoxManage modifyvm "$vm" --nic2 intnet --intnet2 main
      VBoxManage modifyvm "$vm" --nic3 intnet --intnet3 internal
      VBoxManage modifyvm "$vm" --macaddress1 auto --macaddress2 auto --macaddress3 auto
      set_nat_rule "$vm" "ssh-router-linux" "${SSH_PORTS[$vm]}" 22
      ;;
  esac
}

start_vm() {
  VBoxManage startvm "$1" --type gui 2>/dev/null || true
}

poweroff_vm() {
  VBoxManage controlvm "$1" poweroff 2>/dev/null || true
}

set_ram() {
  VBoxManage modifyvm jumpstart --memory 2048
  for vm in balanceador frontend1 frontend2 backend1 backend2 "Router-Linux"; do
    VBoxManage modifyvm "$vm" --memory 1024
  done
}

wait_ssh() {
  local port="$1" name="$2"
  echo "Esperando SSH de $name en puerto $port..."
  for i in {1..60}; do
    if nc -z 127.0.0.1 "$port" >/dev/null 2>&1; then
      echo "SSH de $name disponible."
      return 0
    fi
    sleep 5
  done
  echo "ERROR: $name no responde por SSH en el puerto $port."
  return 1
}

ejecutar_root_remoto() {
  local PUERTO="$1"
  local NOMBRE="$2"
  local CONTENIDO="$3"

  echo "------------------------------------------"
  echo " Configurando ${NOMBRE}"
  echo "------------------------------------------"

  {
    printf '%s\n' "${SUDO_PASS}"
    printf '%s\n' "${CONTENIDO}"
  } | ssh -o StrictHostKeyChecking=accept-new \
          -p "${PUERTO}" \
          "${USUARIO_VM}@${HOST_LOCAL}" \
          "sudo -S -p '' bash -s"

  echo
}

crear_vms() {
  echo "======================================"
  echo " Creación automática de VMs GAR"
  echo " Usuario VM: $USUARIO_VM"
  echo " VM base: $BASE_VM"
  echo "======================================"
  echo

  for vm in "${VMS[@]}"; do
    clone_if_needed "$vm"
    configure_vm_network "$vm"
  done

  echo
  echo "Apagando VMs para ajustar RAM..."
  for vm in "${VMS[@]}"; do poweroff_vm "$vm"; done
  sleep 5

  echo "Ajustando RAM..."
  set_ram

  echo "Arrancando VMs..."
  for vm in "${VMS[@]}"; do start_vm "$vm"; done

  echo
  echo "Resumen de RAM:"
  for vm in "${VMS[@]}"; do
    echo "$vm:"
    VBoxManage showvminfo "$vm" --machinereadable | grep '^memory=' || true
  done

  echo
  echo "Esperando a que arranquen las VMs con SSH..."
  wait_ssh "$PUERTO_BALANCEADOR" balanceador
  wait_ssh "$PUERTO_FRONTEND1" frontend1
  wait_ssh "$PUERTO_FRONTEND2" frontend2
  wait_ssh "$PUERTO_ROUTER" router-linux
  wait_ssh "$PUERTO_JUMPSTART" jumpstart
}

configurar_redes_remotas() {
  echo
  echo "=========================================="
  echo " Configuración de redes remotas"
  echo "=========================================="
  echo

  read -rsp "Contraseña sudo de las VMs: " SUDO_PASS
  echo
  echo

  SCRIPT_BALANCEADOR=$(cat <<SCRIPT
set -e
export DEBIAN_FRONTEND=noninteractive
hostnamectl set-hostname balanceador
cat > /etc/netplan/01-balanceador.yaml <<NETPLAN
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: false
      addresses:
        - ${BALANCEADOR_IP}/24
      routes:
        - to: 10.10.10.0/24
          via: ${VIP_MAIN}
          on-link: true
NETPLAN
netplan generate
netplan apply
apt-get update
apt-get install -y nginx
cat > /etc/nginx/sites-available/default <<NGINX
upstream wordpress_frontends {
    server ${FRONTEND1_IP};
    server ${FRONTEND2_IP};
}
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    location / {
        proxy_pass http://wordpress_frontends;
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
    }
}
NGINX
nginx -t
systemctl restart nginx
systemctl enable nginx
ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw --force enable || true
echo "balanceador configurado:"
hostname
ip -br a
ip route
systemctl is-active nginx
SCRIPT
)

  SCRIPT_FRONTEND1=$(cat <<SCRIPT
set -e
hostnamectl set-hostname frontend1
cat > /etc/netplan/01-frontend1.yaml <<NETPLAN
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: false
      addresses:
        - ${FRONTEND1_IP}/24
      routes:
        - to: 10.10.10.0/24
          via: ${VIP_MAIN}
          on-link: true
NETPLAN
netplan generate
netplan apply
echo "frontend1 configurado:"
hostname
ip -br a
ip route
SCRIPT
)

  SCRIPT_FRONTEND2=$(cat <<SCRIPT
set -e
hostnamectl set-hostname frontend2
cat > /etc/netplan/01-frontend2.yaml <<NETPLAN
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: false
      addresses:
        - ${FRONTEND2_IP}/24
      routes:
        - to: 10.10.10.0/24
          via: ${VIP_MAIN}
          on-link: true
NETPLAN
netplan generate
netplan apply
echo "frontend2 configurado:"
hostname
ip -br a
ip route
SCRIPT
)

  SCRIPT_ROUTER=$(cat <<SCRIPT
set -e
export DEBIAN_FRONTEND=noninteractive
hostnamectl set-hostname router-linux
cat > /etc/netplan/01-router-linux.yaml <<NETPLAN
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: false
      addresses:
        - ${ROUTER_MAIN_IP}/24
    enp0s9:
      dhcp4: false
      addresses:
        - ${ROUTER_INTERNAL_IP}/24
NETPLAN
netplan generate
netplan apply
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-gar-forward.conf
sysctl -p /etc/sysctl.d/99-gar-forward.conf
apt-get update
apt-get install -y keepalived
cat > /etc/keepalived/keepalived.conf <<KEEPALIVED
vrrp_instance VI_MAIN {
    state BACKUP
    interface enp0s8
    virtual_router_id 51
    priority 90
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
    state BACKUP
    interface enp0s9
    virtual_router_id 52
    priority 90
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
ufw --force enable || true
iptables -P FORWARD ACCEPT || true
echo "router-linux configurado:"
hostname
ip -br a
ip route
systemctl is-active keepalived
SCRIPT
)

  ejecutar_root_remoto "$PUERTO_BALANCEADOR" "balanceador" "$SCRIPT_BALANCEADOR"
  ejecutar_root_remoto "$PUERTO_FRONTEND1" "frontend1" "$SCRIPT_FRONTEND1"
  ejecutar_root_remoto "$PUERTO_FRONTEND2" "frontend2" "$SCRIPT_FRONTEND2"
  ejecutar_root_remoto "$PUERTO_ROUTER" "router-linux" "$SCRIPT_ROUTER"
}

crear_vms
configurar_redes_remotas

cat <<INFO
==========================================
 CREACIÓN Y CONFIGURACIÓN REMOTA TERMINADA
==========================================

Ahora configura backend1 y backend2 desde VirtualBox.

En VirtualBox, añade a backend1 y backend2 la carpeta compartida:
  Nombre: CompartidaVM
  Ruta: la carpeta donde están estos scripts
  Solo lectura: desactivado
  Automontar: activado

Backend1:
  sudo mkdir -p /mnt/compartida
  sudo mount -t vboxsf CompartidaVM /mnt/compartida
  bash /mnt/compartida/01_crear_y_configurar_vms.sh --backend1-local

Backend2:
  sudo mkdir -p /mnt/compartida
  sudo mount -t vboxsf CompartidaVM /mnt/compartida
  bash /mnt/compartida/01_crear_y_configurar_vms.sh --backend2-local

Después ejecuta:
  ./02_preparar_jumpstart.sh ${USUARIO_VM}
INFO
