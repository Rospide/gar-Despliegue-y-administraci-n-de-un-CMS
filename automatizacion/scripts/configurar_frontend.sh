#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Uso: sudo ./configurar_frontend.sh <hostname> <ip-interna> [gateway]"
  echo "Ejemplo: sudo ./configurar_frontend.sh frontend1 10.0.0.10"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script debe ejecutarse con sudo."
  exit 1
fi

HOSTNAME_VALUE="$1"
INTERNAL_IP="$2"
GATEWAY="${3:-10.0.0.20}"

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

  if [[ "${#IFACES[@]}" -lt 2 ]]; then
    echo "Se esperaban al menos dos interfaces de red distintas de loopback." >&2
    exit 1
  fi

  local default_iface=""
  default_iface="$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}' || true)"

  if [[ -n "${default_iface}" ]]; then
    EXTERNAL_IFACE="${default_iface}"
  else
    EXTERNAL_IFACE="${IFACES[0]}"
  fi

  for iface in "${IFACES[@]}"; do
    if [[ "${iface}" != "${EXTERNAL_IFACE}" ]]; then
      INTERNAL_IFACE="${iface}"
      break
    fi
  done

  if [[ -z "${INTERNAL_IFACE:-}" ]]; then
    echo "No se ha podido detectar la interfaz interna." >&2
    exit 1
  fi
}

write_netplan() {
  local target_file="$1"

  cat > "${target_file}" <<EOF
network:
  version: 2
  ethernets:
    ${EXTERNAL_IFACE}:
      dhcp4: true
    ${INTERNAL_IFACE}:
      dhcp4: false
      addresses:
        - ${INTERNAL_IP}/24
      routes:
        - to: 10.10.10.0/24
          via: ${GATEWAY}
          on-link: true
EOF
}

print_summary() {
  echo
  echo "Configuración aplicada:"
  echo "- Hostname: ${HOSTNAME_VALUE}"
  echo "- Interfaz externa: ${EXTERNAL_IFACE}"
  echo "- Interfaz interna: ${INTERNAL_IFACE}"
  echo "- IP interna: ${INTERNAL_IP}/24"
  echo "- Gateway a backends: ${GATEWAY}"
  echo
  ip a show "${EXTERNAL_IFACE}" || true
  ip a show "${INTERNAL_IFACE}" || true
  ip route || true
}

NETPLAN_FILE="$(find_netplan_file)"
EXTERNAL_IFACE=""
INTERNAL_IFACE=""

detect_interfaces
write_netplan "${NETPLAN_FILE}"
hostnamectl set-hostname "${HOSTNAME_VALUE}"
netplan generate
netplan apply

print_summary
