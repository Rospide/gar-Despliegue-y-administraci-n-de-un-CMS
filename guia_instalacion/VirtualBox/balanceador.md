# Instalación y configuración del balenceador
## 1. Clonar máquina base

Desde VirtualBox:

- Click derecho en `base-ubuntu` → Clonar
- Nombre: `balenceador`
- Tipo: **Clon completo**
- Reinitializar MAC address

##  2. Configuración de red (VirtualBox)

Ir a configuración y luego a red

### Adaptador 1
- Tipo: **Red interna**
- Nombre: **main**

## 3. Configuración de red en Ubuntu
```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Configuración del archivo:

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: yes

    enp0s8:
      dhcp4: no
      addresses:
        - 10.0.0.1/24
      routes:
        - to: 10.10.10.0/24
          via: 10.0.0.20
```

Aplicar cambios con:

```bash
sudo netplan apply
```
 y comprobar con:

```bash
ip a
```
## 4. Comprobación de conectividad

Verificar conexión con los backends:

```bash
ping 10.10.10.20
```
```bash
ping 10.10.10.21
```

## 5. Instalación de Nginx
```bash
sudo apt update
```
```bash
sudo apt install nginx -y
```

## 6. Configuración del balanceador

Editar archivo:
```bash
sudo nano /etc/nginx/sites-available/default
```

Contenido:
```yaml
upstream backend_servers {
    server 10.10.10.20;
    server 10.10.10.21;
}

server {
    listen 80;

    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## 7. Verificación de configuración
```bash
sudo nginx -t
```

## 8. Reinicio del servicio
```bash
sudo systemctl restart nginx
```

## 9. Prueba de funcionamiento

```bash
curl http://localhost
```

Debe alternar entre los servidores backend:

SOY BACKEND1

SOY BACKEND2


## 10. Acceso al balanceador desde el host (Port Forwarding)

Para poder acceder al balanceador desde el equipo anfitrión (host), es necesario configurar una redirección de puertos en VirtualBox.

Para ello, apagamos la máquina virtual del balenceador, vamos a configuración, luego a red y en el adaptador 1 (NAT) pulsamos avanzado y le damos a la opción de redirección de puertos.
Hay que añadir la siguiente regla para el acceso remoto: 
```yaml
Nombre: ssh
Protocolo: TCP
Puerto anfitrión: 2222
Puerto invitado: 22
```

Y la siguiente regla web:
```yaml
Nombre: web
Protocolo: TCP
Puerto anfitrión: 8080
Puerto invitado: 80
```


## 11. Configuración de Seguridad y Firewall 

Para garantizar que el*Balanceador sea el único punto de entrada seguro desde internet y proteger el resto de la infraestructura, se ha configurado el firewall `UFW` (Uncomplicated Firewall) siguiendo una política de **mínimo privilegio**.


Se han aplicado las siguientes reglas para cerrar cualquier acceso no autorizado fuera de la red:

### 12.1. Política de denegación por defecto
Bloqueamos cualquier conexión entrante que no esté explícitamente permitida por una regla específica.
```bash
sudo ufw default deny incoming
```

### 12.2. Apertura del servicio web (CMS)
Permitimos el tráfico a través del puerto 80 para que los usuarios puedan acceder al servicio web expuesto por el balanceador.
```bash
sudo ufw allow 80/tcp
```

### 12.3. Acceso administrativo restringido (SSH)
Por seguridad, el acceso por SSH al balanceador solo está permitido desde la IP del nodo Jumpstart (10.0.0.20). Cualquier otro intento de conexión desde internet o desde otros nodos será descartado.
```bash
sudo ufw allow from 10.0.0.20 to any port 22 proto tcp
```

### 12.4. Activación del Firewall
Una vez definidas las reglas anteriores, procedemos a activar el sistema de filtrado para que entren en vigor.
```bash
sudo ufw enable
```

## 11. SIGUIENTE PASO

Crear las máquinas:

* jumpstart
