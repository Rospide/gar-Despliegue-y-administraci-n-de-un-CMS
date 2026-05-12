#!/usr/bin/env bash

set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "Uso: sudo ./configurar_router_linux.sh [hostname]"
  echo "Ejemplo: sudo ./configurar_router_linux.sh router-linux"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script debe ejecutarse con sudo."
  exit 1
fi

HOSTNAME_VALUE="${1:-router-linux}"

MAIN_IP="192.168.50.254"
INTERNAL_IP="10.10.10.254"
VIP_MAIN="192.168.50.100"
VIP_INTERNAL="10.10.10.100"

find_netplan_file() {
  local candidates=(
    "/etc/netplan/50-cloud-init.yaml"
    "/etc/netplan/00-installer-config.yaml"
  )

  local file
  for file in "${candidates[@]}"; do
    if [[ -f "${file}" ]]; then
      echo "${file}"
      return 0
    fi
  done

  file="$(find /etc/netplan -maxdepth 1 -type f -name '*.yaml' | sort | head -n 1 || true)"
  if [[ -n "${file}" ]]; then
    echo "${file}"
    return 0
  fi

  echo "/etc/netplan/00-installer-config.yaml"
}

backup_netplan() {
  local backup_dir="/etc/netplan/backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${backup_dir}"

  if ls /etc/netplan/*.yaml >/dev/null 2>&1; then
    cp -a /etc/netplan/*.yaml "${backup_dir}/"
  fi

  echo "Backup de netplan guardado en: ${backup_dir}"
}

backup_keepalived() {
  local backup_dir="/etc/keepalived/backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${backup_dir}"

  if [[ -f /etc/keepalived/keepalived.conf ]]; then
    cp -a /etc/keepalived/keepalived.conf "${backup_dir}/keepalived.conf"
  fi

  echo "Backup de keepalived guardado en: ${backup_dir}"
}

detect_interfaces() {
  mapfile -t IFACES < <(find /sys/class/net -mindepth 1 -maxdepth 1 -type l -printf '%f\n' | grep -v '^lo$' | sort)

  if [[ "${#IFACES[@]}" -lt 3 ]]; then
    echo "Error: se esperaban al menos tres interfaces de red distintas de loopback."
    echo "Comprueba con: ip a"
    exit 1
  fi

  NAT_IFACE="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}' || true)"
  if [[ -z "${NAT_IFACE}" ]]; then
    NAT_IFACE="${IFACES[0]}"
  fi

  local remaining=()
  local iface
  for iface in "${IFACES[@]}"; do
    if [[ "${iface}" != "${NAT_IFACE}" ]]; then
      remaining+=("${iface}")
    fi
  done

  MAIN_IFACE="${remaining[0]}"
  INTERNAL_IFACE="${remaining[1]}"
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
  local target_file="$1"

  cat > "${target_file}" <<EOF
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
  apt install keepalived -y
}

configure_keepalived() {
  mkdir -p /etc/keepalived

  cat > /etc/keepalived/keepalived.conf <<EOF
vrrp_instance VI_MAIN {
    state BACKUP
    interface ${MAIN_IFACE}
    virtual_router_id 51
    priority 50
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
    interface ${INTERNAL_IFACE}
    virtual_router_id 52
    priority 50
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass garpass
    }
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
  echo "Configuración aplicada en router-linux:"
  echo "- Hostname: ${HOSTNAME_VALUE}"
  echo "- NAT: ${NAT_IFACE} DHCP"
  echo "- Main: ${MAIN_IFACE} ${MAIN_IP}/24"
  echo "- Internal: ${INTERNAL_IFACE} ${INTERNAL_IP}/24"
  echo "- VIP main backup: ${VIP_MAIN}"
  echo "- VIP internal backup: ${VIP_INTERNAL}"
  echo "- Forwarding activado"
  echo
  ip a show "${NAT_IFACE}" || true
  ip a show "${MAIN_IFACE}" || true
  ip a show "${INTERNAL_IFACE}" || true
  ip route || true
  cat /proc/sys/net/ipv4/ip_forward || true
  systemctl --no-pager --full status keepalived | head -n 20 || true
}

NETPLAN_FILE="$(find_netplan_file)"
NAT_IFACE=""
MAIN_IFACE=""
INTERNAL_IFACE=""

echo "[1/8] Detectando interfaces..."
detect_interfaces

echo "[2/8] Haciendo backup de netplan..."
backup_netplan

echo "[3/8] Configurando hostname..."
set_hostname

echo "[4/8] Escribiendo netplan..."
write_netplan "${NETPLAN_FILE}"

echo "[5/8] Aplicando netplan..."
netplan generate
netplan apply

echo "[6/8] Activando forwarding..."
enable_forwarding

echo "[7/8] Instalando y configurando keepalived..."
install_packages
backup_keepalived
configure_keepalived

echo "[8/8] Mostrando resumen..."
print_summary
