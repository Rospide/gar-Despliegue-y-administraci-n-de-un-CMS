#!/usr/bin/env bash

set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "Uso: sudo ./configurar_balanceador.sh [hostname]"
  echo "Ejemplo: sudo ./configurar_balanceador.sh balanceador"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script debe ejecutarse con sudo."
  exit 1
fi

HOSTNAME_VALUE="${1:-balanceador}"

MAIN_IP="192.168.50.20"
ROUTE_INTERNAL_NET="10.10.10.0/24"
ROUTE_VIA="192.168.50.10"

BACKEND1_IP="10.10.10.10"
BACKEND2_IP="10.10.10.11"
JUMPSTART_IP="192.168.50.10"

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

backup_nginx() {
  local backup_dir="/etc/nginx/backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${backup_dir}"

  if [[ -f /etc/nginx/sites-available/default ]]; then
    cp -a /etc/nginx/sites-available/default "${backup_dir}/default"
  fi

  echo "Backup de Nginx guardado en: ${backup_dir}"
}

detect_interfaces() {
  mapfile -t IFACES < <(find /sys/class/net -mindepth 1 -maxdepth 1 -type l -printf '%f\n' | grep -v '^lo$' | sort)

  if [[ "${#IFACES[@]}" -lt 2 ]]; then
    echo "Error: se esperaban al menos dos interfaces de red distintas de loopback."
    echo "Comprueba con: ip a"
    exit 1
  fi

  NAT_IFACE="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}' || true)"
  if [[ -z "${NAT_IFACE}" ]]; then
    NAT_IFACE="${IFACES[0]}"
  fi

  local iface
  for iface in "${IFACES[@]}"; do
    if [[ "${iface}" != "${NAT_IFACE}" ]]; then
      MAIN_IFACE="${iface}"
      break
    fi
  done
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
      routes:
        - to: ${ROUTE_INTERNAL_NET}
          via: ${ROUTE_VIA}
          on-link: true
EOF
}

install_packages() {
  apt update
  apt install nginx ufw curl -y
}

configure_nginx() {
  cat > /etc/nginx/sites-available/default <<EOF
upstream backend_servers {
    server ${BACKEND1_IP};
    server ${BACKEND2_IP};
}

server {
    listen 80;

    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

  nginx -t
  systemctl enable nginx
  systemctl restart nginx
}

configure_ufw() {
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 80/tcp
  ufw allow from "${JUMPSTART_IP}" to any port 22 proto tcp
  ufw --force enable
}

print_summary() {
  echo
  echo "Configuración aplicada en balanceador:"
  echo "- Hostname: ${HOSTNAME_VALUE}"
  echo "- NAT: ${NAT_IFACE} DHCP"
  echo "- Main: ${MAIN_IFACE} ${MAIN_IP}/24"
  echo "- Ruta hacia ${ROUTE_INTERNAL_NET} vía ${ROUTE_VIA}"
  echo "- Backend 1: ${BACKEND1_IP}"
  echo "- Backend 2: ${BACKEND2_IP}"
  echo "- Nginx configurado como balanceador"
  echo
  ip a show "${NAT_IFACE}" || true
  ip a show "${MAIN_IFACE}" || true
  ip route || true
  systemctl --no-pager --full status nginx | head -n 20 || true
  ufw status verbose || true
  curl -m 5 http://localhost || true
}

NETPLAN_FILE="$(find_netplan_file)"
NAT_IFACE=""
MAIN_IFACE=""

echo "[1/9] Detectando interfaces..."
detect_interfaces

echo "[2/9] Haciendo backup de netplan..."
backup_netplan

echo "[3/9] Configurando hostname..."
set_hostname

echo "[4/9] Escribiendo netplan..."
write_netplan "${NETPLAN_FILE}"

echo "[5/9] Aplicando netplan..."
netplan generate
netplan apply

echo "[6/9] Instalando Nginx, UFW y curl..."
install_packages

echo "[7/9] Haciendo backup de configuración Nginx..."
backup_nginx

echo "[8/9] Configurando Nginx y firewall..."
configure_nginx
configure_ufw

echo "[9/9] Mostrando resumen..."
print_summary
