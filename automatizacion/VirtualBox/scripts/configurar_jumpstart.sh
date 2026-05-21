#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 1 ]]; then
  echo "Uso: sudo ./configurar_jumpstart.sh <hostname>"
  echo "Ejemplo: sudo ./configurar_jumpstart.sh jumpstart"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script debe ejecutarse con sudo."
  exit 1
fi

HOSTNAME_VALUE="$1"

NAT_IFACE="enp0s3"
MAIN_IFACE="enp0s8"
INTERNAL_IFACE="enp0s9"

MAIN_IP="10.0.0.20"
INTERNAL_IP="10.10.10.10"

VIP_MAIN="10.0.0.100"
VIP_INTERNAL="10.10.10.100"

backup_netplan() {
  BACKUP_DIR="/etc/netplan/backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${BACKUP_DIR}"

  if ls /etc/netplan/*.yaml >/dev/null 2>&1; then
    cp -a /etc/netplan/*.yaml "${BACKUP_DIR}/"
  fi

  echo "Backup de netplan guardado en: ${BACKUP_DIR}"
}

set_hostname() {
  hostnamectl set-hostname "${HOSTNAME_VALUE}"

  if grep -q "^127.0.1.1" /etc/hosts; then
    sed -i "s/^127.0.1.1.*/127.0.1.1 ${HOSTNAME_VALUE}/" /etc/hosts
  else
    echo "127.0.1.1 ${HOSTNAME_VALUE}" >> /etc/hosts
  fi
}

write_netplan() {
  cat > /etc/netplan/00-installer-config.yaml <<EOF
network:
  version: 2
  ethernets:
    ${NAT_IFACE}:
      dhcp4: true

    ${MAIN_IFACE}:
      dhcp4: false
      addresses:
        - ${MAIN_IP}/24

    ${INTERNAL_IFACE}:
      dhcp4: false
      addresses:
        - ${INTERNAL_IP}/24
EOF
}

enable_forwarding() {
  if grep -q "^#net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    sed -i "s/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/" /etc/sysctl.conf
  elif grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    true
  else
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  fi

  sysctl -p
}

install_packages() {
  apt update
  apt install keepalived ansible -y
}

configure_keepalived() {
  mkdir -p /etc/keepalived

  cat > /etc/keepalived/keepalived.conf <<EOF
vrrp_instance VI_MAIN {
    state MASTER
    interface ${MAIN_IFACE}
    virtual_router_id 51
    priority 100
    advert_int 1

    virtual_ipaddress {
        ${VIP_MAIN}/24
    }
}

vrrp_instance VI_INTERNAL {
    state MASTER
    interface ${INTERNAL_IFACE}
    virtual_router_id 52
    priority 100
    advert_int 1

    virtual_ipaddress {
        ${VIP_INTERNAL}/24
    }
}
EOF

  systemctl unmask keepalived || true
  systemctl enable keepalived
  systemctl restart keepalived
}

print_summary() {
  echo
  echo "Configuración aplicada en jumpstart:"
  echo "- Hostname: ${HOSTNAME_VALUE}"
  echo "- NAT: ${NAT_IFACE} DHCP"
  echo "- Main: ${MAIN_IFACE} ${MAIN_IP}/24"
  echo "- Internal: ${INTERNAL_IFACE} ${INTERNAL_IP}/24"
  echo "- VIP main: ${VIP_MAIN}"
  echo "- VIP internal: ${VIP_INTERNAL}"
  echo "- Forwarding activado"
  echo "- Keepalived instalado y configurado"
  echo "- Ansible instalado"
  echo

  echo "IPs:"
  ip a

  echo
  echo "Rutas:"
  ip route

  echo
  echo "Forwarding:"
  cat /proc/sys/net/ipv4/ip_forward

  echo
  echo "Keepalived:"
  systemctl --no-pager --full status keepalived | head -n 20 || true

  echo
  echo "Ansible:"
  ansible --version | head -n 1 || true
}

echo "[1/8] Haciendo backup de netplan..."
backup_netplan

echo "[2/8] Configurando hostname..."
set_hostname

echo "[3/8] Escribiendo netplan..."
write_netplan

echo "[4/8] Aplicando netplan..."
netplan generate
netplan apply

echo "[5/8] Activando forwarding..."
enable_forwarding

echo "[6/8] Instalando keepalived y Ansible..."
install_packages

echo "[7/8] Configurando keepalived..."
configure_keepalived

echo "[8/8] Mostrando resumen..."
print_summary
