#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: sudo ./configurar_balanceador.sh <hostname>"
  echo "Ejemplo: sudo ./configurar_balanceador.sh balanceador"
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "Este script debe ejecutarse con sudo."
  exit 1
fi

HOSTNAME_VALUE="$1"

NAT_IFACE="enp0s3"
MAIN_IFACE="enp0s8"

MAIN_IP="10.0.0.1"
MAIN_CIDR="24"

ROUTE_INTERNAL_NET="10.10.10.0/24"
ROUTE_VIA="10.0.0.100"

FRONTEND1_IP="10.0.0.10"
FRONTEND2_IP="10.0.0.11"

JUMPSTART_IP="10.0.0.20"

backup_netplan() {
  BACKUP_DIR="/etc/netplan/backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${BACKUP_DIR}"

  if ls /etc/netplan/*.yaml >/dev/null 2>&1; then
    cp -a /etc/netplan/*.yaml "${BACKUP_DIR}/"
  fi

  echo "Backup de netplan guardado en: ${BACKUP_DIR}"
}

backup_nginx() {
  BACKUP_DIR="/etc/nginx/backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${BACKUP_DIR}"

  if [[ -f /etc/nginx/sites-available/default ]]; then
    cp -a /etc/nginx/sites-available/default "${BACKUP_DIR}/default"
  fi

  echo "Backup de Nginx guardado en: ${BACKUP_DIR}"
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
        - ${MAIN_IP}/${MAIN_CIDR}
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
upstream frontend_servers {
    server ${FRONTEND1_IP}:80;
    server ${FRONTEND2_IP}:80;
}

server {
    listen 80;

    location / {
        proxy_pass http://frontend_servers;
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
  echo "- Main: ${MAIN_IFACE} ${MAIN_IP}/${MAIN_CIDR}"
  echo "- Ruta hacia ${ROUTE_INTERNAL_NET} vía ${ROUTE_VIA}"
  echo "- Frontend 1: ${FRONTEND1_IP}"
  echo "- Frontend 2: ${FRONTEND2_IP}"
  echo "- Nginx instalado y configurado como balanceador hacia los frontends"
  echo "- Firewall UFW activado"
  echo "- SSH permitido solo desde Jumpstart: ${JUMPSTART_IP}"
  echo "- HTTP permitido por puerto 80"
  echo

  echo "IPs:"
  ip a

  echo
  echo "Rutas:"
  ip route

  echo
  echo "Nginx:"
  systemctl --no-pager --full status nginx | head -n 20 || true

  echo
  echo "UFW:"
  ufw status verbose || true

  echo
  echo "Configuración Nginx:"
  cat /etc/nginx/sites-available/default

  echo
  echo "Prueba local:"
  curl -m 5 -I http://localhost || true
}

echo "[1/9] Haciendo backup de netplan..."
backup_netplan

echo "[2/9] Configurando hostname..."
set_hostname

echo "[3/9] Escribiendo netplan..."
write_netplan

echo "[4/9] Aplicando netplan..."
netplan generate
netplan apply

echo "[5/9] Instalando Nginx, UFW y curl..."
install_packages

echo "[6/9] Haciendo backup de configuración Nginx..."
backup_nginx

echo "[7/9] Configurando Nginx como balanceador..."
configure_nginx

echo "[8/9] Configurando firewall..."
configure_ufw

echo "[9/9] Mostrando resumen..."
print_summary
