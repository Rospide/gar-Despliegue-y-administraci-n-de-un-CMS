#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 || $# -gt 5 ]]; then
  echo "Uso: sudo ./configurar_frontend.sh <hostname> <ip-main> [gateway] [iface-nat] [iface-main]"
  echo "Ejemplo: sudo ./configurar_frontend.sh frontend1 10.0.0.10"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script debe ejecutarse con sudo."
  exit 1
fi

HOSTNAME_VALUE="$1"
MAIN_IP="$2"
GATEWAY="${3:-10.0.0.20}"
NAT_IFACE="${4:-}"
MAIN_IFACE="${5:-}"

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
      local iface
      for iface in "${IFACES[@]}"; do
        if [[ "${iface}" != "${NAT_IFACE}" ]]; then
          MAIN_IFACE="${iface}"
          break
        fi
      done
    fi
  fi

  if [[ ! -d "/sys/class/net/${NAT_IFACE}" || ! -d "/sys/class/net/${MAIN_IFACE}" ]]; then
    echo "No se han encontrado las interfaces esperadas: NAT=${NAT_IFACE}, main=${MAIN_IFACE}" >&2
    echo "Comprueba los nombres con: ip a" >&2
    exit 1
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
        - to: 10.10.10.0/24
          via: ${GATEWAY}
          on-link: true
EOF
}

print_summary() {
  echo
  echo "Configuración aplicada:"
  echo "- Hostname: ${HOSTNAME_VALUE}"
  echo "- Interfaz NAT: ${NAT_IFACE}"
  echo "- Interfaz main: ${MAIN_IFACE}"
  echo "- IP main: ${MAIN_IP}/24"
  echo "- Gateway a internal: ${GATEWAY}"
  echo
  ip a show "${NAT_IFACE}" || true
  ip a show "${MAIN_IFACE}" || true
  ip route || true
}

NETPLAN_FILE="$(find_netplan_file)"

detect_interfaces
write_netplan "${NETPLAN_FILE}"
hostnamectl set-hostname "${HOSTNAME_VALUE}"
netplan generate
netplan apply

print_summary
