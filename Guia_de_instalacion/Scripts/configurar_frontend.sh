#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 5 ]]; then
  echo "Uso: sudo ./configurar_frontend.sh <hostname> <ip-main> [gateway] [iface-nat] [iface-main]"
  echo "Ejemplo frontend1: sudo ./configurar_frontend.sh frontend1 10.0.0.10"
  echo "Ejemplo frontend2: sudo ./configurar_frontend.sh frontend2 10.0.0.11"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script debe ejecutarse con sudo."
  exit 1
fi

HOSTNAME_VALUE="$1"
MAIN_IP="$2"
GATEWAY="${3:-10.0.0.100}"
NAT_IFACE="${4:-}"
MAIN_IFACE="${5:-}"

detect_interfaces() {
  mapfile -t IFACES < <(find /sys/class/net -mindepth 1 -maxdepth 1 -type l -printf '%f\n' | grep -v '^lo$' | sort)

  if [[ "${#IFACES[@]}" -lt 2 ]]; then
    echo "Error: se esperaban al menos dos interfaces de red distintas de loopback."
    echo "Comprueba con: ip a"
    exit 1
  fi

  if [[ -z "${NAT_IFACE}" ]]; then
    NAT_IFACE="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}' || true)"
  fi

  if [[ -z "${NAT_IFACE}" ]]; then
    NAT_IFACE="enp0s3"
  fi

  if [[ -z "${MAIN_IFACE}" ]]; then
    if [[ -d "/sys/class/net/enp0s8" ]]; then
      MAIN_IFACE="enp0s8"
    else
      for iface in "${IFACES[@]}"; do
        if [[ "${iface}" != "${NAT_IFACE}" ]]; then
          MAIN_IFACE="${iface}"
          break
        fi
      done
    fi
  fi

  if [[ ! -d "/sys/class/net/${NAT_IFACE}" ]]; then
    echo "Error: no existe la interfaz NAT ${NAT_IFACE}"
    echo "Comprueba con: ip a"
    exit 1
  fi

  if [[ ! -d "/sys/class/net/${MAIN_IFACE}" ]]; then
    echo "Error: no existe la interfaz main ${MAIN_IFACE}"
    echo "Comprueba con: ip a"
    exit 1
  fi
}

backup_netplan() {
  BACKUP_DIR="/etc/netplan/backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${BACKUP_DIR}"

  if ls /etc/netplan/*.yaml >/dev/null 2>&1; then
    cp -a /etc/netplan/*.yaml "${BACKUP_DIR}/"
    rm -f /etc/netplan/*.yaml
  fi

  echo "Backup de netplan guardado en: ${BACKUP_DIR}"
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
      routes:
        - to: 10.10.10.0/24
          via: ${GATEWAY}
          on-link: true
EOF
}

set_hostname() {
  hostnamectl set-hostname "${HOSTNAME_VALUE}"

  if grep -q "127.0.1.1" /etc/hosts; then
    sed -i "s/^127.0.1.1.*/127.0.1.1 ${HOSTNAME_VALUE}/" /etc/hosts
  else
    echo "127.0.1.1 ${HOSTNAME_VALUE}" >> /etc/hosts
  fi
}

print_summary() {
  echo
  echo "Configuración aplicada:"
  echo "- Hostname: ${HOSTNAME_VALUE}"
  echo "- Interfaz NAT: ${NAT_IFACE}"
  echo "- Interfaz main: ${MAIN_IFACE}"
  echo "- IP main: ${MAIN_IP}/24"
  echo "- Ruta a internal: 10.10.10.0/24 vía ${GATEWAY}"
  echo

  echo "IP de interfaces:"
  ip a show "${NAT_IFACE}" || true
  ip a show "${MAIN_IFACE}" || true

  echo
  echo "Rutas:"
  ip route || true

  echo
  echo "Hostname:"
  hostname
}

echo "[1/5] Detectando interfaces..."
detect_interfaces

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
