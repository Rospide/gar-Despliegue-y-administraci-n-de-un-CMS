#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Uso: sudo ./configurar_backend_red.sh <hostname> <ip-internal> [gateway]"
  echo "Ejemplo backend1: sudo ./configurar_backend_red.sh backend1 10.10.10.10"
  echo "Ejemplo backend2: sudo ./configurar_backend_red.sh backend2 10.10.10.11"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script debe ejecutarse con sudo."
  exit 1
fi

HOSTNAME_VALUE="$1"
INTERNAL_IP="$2"
GATEWAY="${3:-10.10.10.1}"
MAIN_NET="192.168.50.0/24"

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
      INTERNAL_IFACE="${iface}"
      break
    fi
  done

  if [[ -z "${INTERNAL_IFACE:-}" ]]; then
    echo "No se ha podido detectar la interfaz internal."
    exit 1
  fi
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

    ${INTERNAL_IFACE}:
      dhcp4: false
      addresses:
        - ${INTERNAL_IP}/24
      routes:
        - to: ${MAIN_NET}
          via: ${GATEWAY}
          on-link: true
EOF
}

print_summary() {
  echo
  echo "Configuración aplicada:"
  echo "- Hostname: ${HOSTNAME_VALUE}"
  echo "- Interfaz NAT: ${NAT_IFACE}"
  echo "- Interfaz internal: ${INTERNAL_IFACE}"
  echo "- IP internal: ${INTERNAL_IP}/24"
  echo "- Ruta a main: ${MAIN_NET} vía ${GATEWAY}"
  echo
  ip a show "${NAT_IFACE}" || true
  ip a show "${INTERNAL_IFACE}" || true
  ip route || true
  hostname || true
}

NETPLAN_FILE="$(find_netplan_file)"
NAT_IFACE=""
INTERNAL_IFACE=""

echo "[1/5] Detectando interfaces..."
detect_interfaces

echo "[2/5] Haciendo backup de netplan..."
backup_netplan

echo "[3/5] Configurando hostname..."
set_hostname

echo "[4/5] Escribiendo netplan..."
write_netplan "${NETPLAN_FILE}"

echo "[5/5] Aplicando configuración..."
netplan generate
netplan apply

print_summary
