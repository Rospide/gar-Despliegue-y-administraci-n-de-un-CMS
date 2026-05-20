## 1. Archivos necesarios

crear_balanceador.sh
configurar_balanceador.sh

## 2. Creación vm

Desde el host:
```bash
chmod +x crear_balanceador.sh
./crear_balanceador.sh usuario_vm
```  
Ejemplo:

./crear_balanceador.sh alejandroro

El script clonará base-ubuntu como balanceador, configurará las redes y arrancará la VM.

## 3. Configuración de las redes

Primero, desde el host, entrar por SSH temporal:
```bash
ssh -p 2226 usuario_vm@127.0.0.1
``` 
Si entra correctamente, salimos:
```bash
exit
``` 
Después copiamos el script desde el host hacia la VM:
```bash
scp -P 2226 configurar_balanceador.sh usuario_vm@127.0.0.1:~/
``` 
Ejemplo:

scp -P 2226 configurar_balanceador.sh alejandroro@127.0.0.1:~/

Importante: este scp se ejecuta desde el host, no desde dentro de la VM.


## 4. Ejecutar la configuración dentro del balanceador

Entramos al balanceador:
```bash  
ssh -p 2226 usuario_vm@127.0.0.1
```  
Damos permisos al script:
```bash
chmod +x configurar_balanceador.sh
``` 
Ejecutamos:
```bash
sudo ./configurar_balanceador.sh balanceador
``` 
No hay que pasarle la IP del balanceador porque la IP ya está definida dentro del script:

MAIN_IP="10.0.0.1"

El parámetro balanceador solo sirve para cambiar el hostname de la máquina.


## 5. Comprobaciones dentro del balanceador

Dentro de la VM:
```bash
hostname
```
Debe devolver:

balanceador

Comprobar interfaces:
```bash
ip a
``` 
Debe aparecer:

enp0s3 → 10.0.2.15 aproximadamente, por NAT
enp0s8 → 10.0.0.1/24

Comprobar rutas:
```bash
ip route
``` 
Debe aparecer una ruta como esta:

10.10.10.0/24 via 10.0.0.100 dev enp0s8

Comprobar Nginx:
```bash
sudo systemctl status nginx
``` 
Comprobar firewall:
```bash
sudo ufw status verbose
``` 
Debe aparecer algo parecido a:

Status: active

Default: deny (incoming), allow (outgoing)

80/tcp     ALLOW IN    Anywhere
22/tcp     ALLOW IN    10.0.0.20

Comprobar balanceo:
```bash
curl http://localhost
curl http://localhost
curl http://localhost
``` 
Debe alternar entre:

SOY BACKEND1

y:

SOY BACKEND2


## 6. Comprobación desde el host

Desde el equipo anfitrión:

curl http://127.0.0.1:8080

También puedes abrir en el navegador:

http://127.0.0.1:8080

Debería mostrar el contenido de los backends.








## LA ESTOY MODIFICANDO QUE HAY COSAS INCOMPLETAS

# Guía de instalación y configuración del balanceador

## 1. Archivos necesarios

```bash
crear_balanceador.sh
configurar_balanceador.sh
``` 
## 2. Crear la VM balanceador

Desde el PC anfitrión:
```bash
chmod +x crear_balanceador.sh
./crear_balanceador.sh <USUARIO_VM>
``` 
Ejemplo:

./crear_balanceador.sh alejandroro
## 3. Copiar el script de configuración

Desde el PC anfitrión:
```bash
scp -P 2226 configurar_balanceador.sh <USUARIO_VM>@127.0.0.1:~/
``` 
Ejemplo:

scp -P 2226 configurar_balanceador.sh alejandroro@127.0.0.1:~/
## 4. Entrar al balanceador
```bash
ssh -p 2226 <USUARIO_VM>@127.0.0.1
``` 
Ejemplo:
```bash
ssh -p 2226 alejandroro@127.0.0.1
``` 
5. Ejecutar configuración

Dentro del balanceador:
```bash
chmod +x configurar_balanceador.sh
sudo ./configurar_balanceador.sh balanceador
``` 
## 6. Script configurar_balanceador.sh corregido
```bash
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

FRONTEND1_IP="10.0.0.10"
FRONTEND2_IP="10.0.0.11"

VIP_MAIN="10.0.0.100"

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
      routes:
        - to: 10.10.10.0/24
          via: ${VIP_MAIN}
          on-link: true
EOF
}

install_packages() {
  apt update
  apt install nginx ufw curl -y
}

configure_nginx() {
  BACKUP_DIR="/etc/nginx/backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "${BACKUP_DIR}"

  if [ -f /etc/nginx/sites-available/default ]; then
    cp -a /etc/nginx/sites-available/default "${BACKUP_DIR}/default.bak"
  fi

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

configure_firewall() {
  ufw --force reset
  ufw default deny incoming
  ufw default allow outgoing

  ufw allow 80/tcp
  ufw allow from 10.0.0.20 to any port 22 proto tcp

  ufw --force enable
}

print_summary() {
  echo
  echo "Configuración aplicada en balanceador:"
  echo "- Hostname: ${HOSTNAME_VALUE}"
  echo "- NAT: ${NAT_IFACE} DHCP"
  echo "- Main: ${MAIN_IFACE} ${MAIN_IP}/24"
  echo "- Ruta hacia 10.10.10.0/24 vía ${VIP_MAIN}"
  echo "- Frontend 1: ${FRONTEND1_IP}"
  echo "- Frontend 2: ${FRONTEND2_IP}"
  echo "- Nginx instalado y configurado como balanceador hacia frontends"
  echo "- Firewall UFW activado"
  echo "- SSH permitido solo desde Jumpstart: 10.0.0.20"
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
  echo
  echo "Prueba local:"
  curl -I http://localhost || true
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

echo "[6/9] Configurando Nginx como balanceador..."
configure_nginx

echo "[7/9] Configurando firewall..."
configure_firewall

echo "[8/9] Mostrando resumen..."
print_summary

echo "[9/9] Configuración terminada."
7. Comprobar que el balanceador ve los frontends

Dentro del balanceador:

ping -c 3 10.0.0.10
ping -c 3 10.0.0.11
8. Comprobar que WordPress responde en los frontends
curl -I http://10.0.0.10
curl -I http://10.0.0.11

Debe aparecer:

HTTP/1.1 302 Found
Location: http://10.0.0.10/wp-admin/install.php

y:

HTTP/1.1 302 Found
Location: http://10.0.0.11/wp-admin/install.php
```


AHORA DARA MAL PORQUE AUN NO ESTA LO DE WORDPRESS

## 9. Comprobar el balanceador
```bash
curl -I http://localhost
``` 
Debe aparecer:

HTTP/1.1 302 Found
Location: http://localhost/wp-admin/install.php

Esto significa que el balanceador está enviando tráfico correctamente a WordPress.

## 10. Comprobar balanceo entre frontend1 y frontend2

Como ahora el balanceador apunta a los frontends, la prueba ya no es SOY BACKEND1 / SOY BACKEND2.

Ahora la prueba correcta es:

SOY FRONTEND1
SOY FRONTEND2

Crear archivo de prueba en frontend1:
```bash
ssh <USUARIO_VM>@10.0.0.10
echo "SOY FRONTEND1" | sudo tee /var/www/html/origen.txt
exit
``` 
Crear archivo de prueba en frontend2:
```bash
ssh <USUARIO_VM>@10.0.0.11
echo "SOY FRONTEND2" | sudo tee /var/www/html/origen.txt
exit
``` 
Desde el balanceador:

curl http://localhost/origen.txt
curl http://localhost/origen.txt
curl http://localhost/origen.txt
curl http://localhost/origen.txt

Debe ir alternando entre:

SOY FRONTEND1
SOY FRONTEND2
11. Ver desde el navegador del PC anfitrión

Si el script crear_balanceador.sh dejó la redirección:

8080 -> 80

en el navegador del PC anfitrión abrir:

http://127.0.0.1:8080

Debe aparecer el instalador de WordPress.

## 12. Explicación para la defensa

El balanceador usa Nginx como reverse proxy.

Antes se podía probar con SOY BACKEND1 y SOY BACKEND2 porque los backends tenían Nginx con páginas identificativas.

Ahora la arquitectura correcta es:

balanceador -> frontend1/frontend2 -> WordPress -> MariaDB Galera

Por eso el balanceador debe apuntar a:

frontend1 -> 10.0.0.10
frontend2 -> 10.0.0.11

y no a:

backend1 -> 10.10.10.20
backend2 -> 10.10.10.21

Los backends quedan reservados para la base de datos Galera.


En resumen: tu balanceador ahora está bien cuando `curl -I http://localhost` devuelve `302 Found` hacia `/wp-admin/
