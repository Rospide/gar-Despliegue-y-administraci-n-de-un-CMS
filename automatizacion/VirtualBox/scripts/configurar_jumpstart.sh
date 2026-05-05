#!/usr/bin/env bash

set -euo pipefail

if [[ $# -gt 4 ]]; then
  echo "Uso: sudo ./configurar_jumpstart.sh [hostname] [iface-nat] [iface-main] [iface-internal]"
  echo "Ejemplo: sudo ./configurar_jumpstart.sh jumpstart"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script debe ejecutarse con sudo."
  exit 1
fi

HOSTNAME_VALUE="${1:-jumpstart}"
NAT_IFACE="${2:-}"
MAIN_IFACE="${3:-}"
INTERNAL_IFACE="${4:-}"
MAIN_IP="10.0.0.20/24"
INTERNAL_IP="10.10.10.10/24"

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

  echo "No se ha encontrado ningún fichero .yaml en /etc/netplan" >&2
  exit 1
}

detect_interfaces() {
  mapfile -t IFACES < <(find /sys/class/net -mindepth 1 -maxdepth 1 -type l -printf '%f\n' | grep -v '^lo$' | sort)

  if [[ "${#IFACES[@]}" -lt 3 ]]; then
    echo "Se esperaban al menos tres interfaces de red distintas de loopback." >&2
    exit 1
  fi

  if [[ -z "${NAT_IFACE}" ]]; then
    NAT_IFACE="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}' || true)"
  fi
  if [[ -z "${NAT_IFACE}" ]]; then
    NAT_IFACE="enp0s3"
  fi
  if [[ -z "${MAIN_IFACE}" ]]; then
    MAIN_IFACE="enp0s8"
  fi
  if [[ -z "${INTERNAL_IFACE}" ]]; then
    INTERNAL_IFACE="enp0s9"
  fi

  for iface in "${NAT_IFACE}" "${MAIN_IFACE}" "${INTERNAL_IFACE}"; do
    if [[ ! -d "/sys/class/net/${iface}" ]]; then
      echo "No se ha encontrado la interfaz ${iface}." >&2
      echo "Comprueba los nombres con: ip a" >&2
      exit 1
    fi
  done
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
        - ${MAIN_IP}
    ${INTERNAL_IFACE}:
      dhcp4: false
      addresses:
        - ${INTERNAL_IP}
EOF
}

print_summary() {
  echo
  echo "Configuración aplicada:"
  echo "- Hostname: ${HOSTNAME_VALUE}"
  echo "- Interfaz NAT: ${NAT_IFACE}"
  echo "- Interfaz main: ${MAIN_IFACE} -> ${MAIN_IP}"
  echo "- Interfaz internal: ${INTERNAL_IFACE} -> ${INTERNAL_IP}"
  echo
  ip a show "${NAT_IFACE}" || true
  ip a show "${MAIN_IFACE}" || true
  ip a show "${INTERNAL_IFACE}" || true
  ip route || true
}

NETPLAN_FILE="$(find_netplan_file)"

detect_interfaces
write_netplan "${NETPLAN_FILE}"
hostnamectl set-hostname "${HOSTNAME_VALUE}"
netplan generate
netplan apply

print_summary
