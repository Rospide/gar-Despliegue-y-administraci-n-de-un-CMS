#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Uso: sudo ./configurar_backend_red.sh <hostname> <ip-internal> [gateway]"
  echo "Ejemplo backend1: sudo ./configurar_backend_red.sh backend1 10.10.10.20"
  echo "Ejemplo backend2: sudo ./configurar_backend_red.sh backend2 10.10.10.21"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script debe ejecutarse con sudo."
  exit 1
fi

HOSTNAME_VALUE="$1"
INTERNAL_IP="$2"
GATEWAY="${3:-10.10.10.100}"

detect_internal_iface() {
  mapfile -t IFACES < <(find /sys/class/net -mindepth 1 -maxdepth 1 -type l -printf '%f\n' | grep -v '^lo$' | sort)

  if [[ "${#IFACES[@]}" -lt 1 ]]; then
    echo "Error: no se ha encontrado ninguna interfaz de red."
    echo "Comprueba con: ip a"
    exit 1
  fi

  if [[ -d "/sys/class/net/enp0s3" ]]; then
    INTERNAL_IFACE="enp0s3"
  else
    INTERNAL_IFACE="${IFACES[0]}"
  fi
}

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
    ${INTERNAL_IFACE}:
      dhcp4: false
      addresses:
        - ${INTERNAL_IP}/24
      routes:
        - to: 10.0.0.0/24
          via: ${GATEWAY}
          on-link: true
EOF
}

print_summary() {
  echo
  echo "Configuración aplicada:"
  echo "- Hostname: ${HOSTNAME_VALUE}"
  echo "- Interfaz internal: ${INTERNAL_IFACE}"
  echo "- IP internal: ${INTERNAL_IP}/24"
  echo "- Ruta a main: 10.0.0.0/24 vía ${GATEWAY}"
  echo

  echo "IP:"
  ip a show "${INTERNAL_IFACE}" || true

  echo
  echo "Rutas:"
  ip route || true

  echo
  echo "Hostname:"
  hostname
}

echo "[1/5] Detectando interfaz internal..."
detect_internal_iface

echo "[2/5] Haciendo backup de netplan..."
backup_netplan

echo "[3/5] Configurando hostname..."
set_hostname

echo "[4/5] Escribiendo netplan..."
write_netplan

echo "[5/5] Aplicando configuración..."
netplan generate
netplan apply

print_summary
