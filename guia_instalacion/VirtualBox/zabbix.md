# Zabbix

## 1. Definir por nodo qué puertos son legítimos y cerrar el resto

### Frontend1

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 10.0.0.0/24 to any port 80 proto tcp
sudo ufw allow from 10.0.0.20 to any port 22 proto tcp
sudo ufw allow from 10.10.10.20 to any port 10050 proto tcp
sudo ufw enable
sudo ufw status verbose
```

### Frontend2

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 10.0.0.0/24 to any port 80 proto tcp
sudo ufw allow from 10.0.0.20 to any port 22 proto tcp
sudo ufw allow from 10.10.10.20 to any port 10050 proto tcp
sudo ufw enable
sudo ufw status verbose
```

### Backend2

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 10.0.0.0/24 to any port 80 proto tcp
sudo ufw allow from 10.10.10.10 to any port 22 proto tcp
sudo ufw allow from 10.10.10.20 to any port 10050 proto tcp
sudo ufw enable
sudo ufw status verbose
```

### Balanceador

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow from 10.0.0.20 to any port 22 proto tcp
sudo ufw allow from 10.10.10.20 to any port 10050 proto tcp
sudo ufw enable
sudo ufw status verbose
```

### Backend1

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 10.10.10.10 to any port 22 proto tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 10051/tcp
sudo ufw allow from 127.0.0.1 to any port 10050 proto tcp
sudo ufw enable
sudo ufw status verbose
```

## 2. Instalar y configurar `zabbix-agent` en todos los nodos

Toda la instalación inicial del servidor Zabbix se realiza en `backend1`, utilizando `jumpstart` como máquina intermedia para descargar el paquete del repositorio y transferirlo a la red interna.

### 2.1 Descargar el paquete en `jumpstart` y copiarlo a `backend1`

Desde `jumpstart`, descargar el paquete del repositorio oficial de Zabbix 6.0 para Ubuntu 20.04.

```bash
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_6.0+ubuntu20.04_all.deb
```

A continuación, copiar el archivo a `backend1` mediante `scp`. Sustituir `usuario` por el nombre real del usuario del sistema en `backend1`.

```bash
scp zabbix-release_latest_6.0+ubuntu20.04_all.deb usuario@10.10.10.20:/home/usuario/
```

Después, entrar en `backend1` e instalar el paquete descargado.

```bash
ssh usuario@10.10.10.20
sudo dpkg -i /home/usuario/zabbix-release_latest_6.0+ubuntu20.04_all.deb
sudo apt update
```

### 2.2 Instalar los paquetes de Zabbix en `backend1`

Antes de instalar Zabbix, se deshabilita Nginx para evitar conflictos con Apache en el puerto 80.

```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
sudo systemctl restart apache2
```

Instalar servidor, frontend, configuración web, scripts SQL y agente.

```bash
sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server -y
```

### 2.3 Crear la base de datos

Entrar en MySQL:

```bash
sudo mysql
```

Ejecutar:

```sql
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user 'zabbix'@'localhost' identified by 'zabbix';
grant all privileges on zabbix.* to 'zabbix'@'localhost';
set global log_bin_trust_function_creators = 1;
quit;
```

### 2.4 Importar el esquema

```bash
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```

Después, restaurar el valor de confianza en MySQL:

```bash
sudo mysql
```

```sql
set global log_bin_trust_function_creators = 0;
quit;
```

### 2.5 Configurar Zabbix Server

Editar el fichero de configuración:

```bash
sudo nano /etc/zabbix/zabbix_server.conf
```

Configurar la contraseña de la base de datos:

```ini
DBPassword=zabbix
```

### 2.6 Arrancar servicios

```bash
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
sudo systemctl status zabbix-server
sudo systemctl status apache2
sudo systemctl status zabbix-agent
```

### 2.7 Abrir acceso web

```bash
sudo ufw allow Apache
sudo ufw enable
sudo ufw reload
```

Acceder desde el navegador del host a:

```text
http://<IP_enp0s8>/zabbix
```

### 2.8 Completar instalación web

Si aparece un error con el idioma, instalar las locales necesarias en `backend1`.

```bash
sudo apt update
sudo apt install locales -y
sudo locale-gen en_US.UTF-8
sudo systemctl restart apache2
```

Credenciales iniciales habituales de Zabbix:

- Usuario: `Admin`
- Contraseña: `zabbix`

### 2.9 Instalar el agente en el resto de nodos

Esta instalación se realiza en las siguientes VMs:

- `backend2`
- `balanceador`
- `frontend1`
- `frontend2`

Instalar el paquete:

```bash
sudo apt update
sudo apt install zabbix-agent -y
```

Editar el fichero del agente:

```bash
sudo nano /etc/zabbix/zabbix_agentd.conf
```

Configurar estas líneas:

```ini
Server=10.10.10.20
ServerActive=10.10.10.20
Hostname=nombre-de-la-vm
ListenPort=10050
```

### 2.10 Arrancar y comprobar el agente

```bash
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent
sudo systemctl status zabbix-agent
```

### 2.11 Ajustar firewall en nodos monitorizados

En `frontend1`, `frontend2`, `backend2` y `balanceador`:

```bash
sudo ufw allow from 10.10.10.20 to any port 10050 proto tcp
sudo ufw reload
sudo ufw status
```

### 2.12 Verificación desde `backend1`

Antes de verificar conectividad, ejecutar en jumpstart:

```bash
sudo ufw status verbose
sudo iptables -L -n -v
sudo iptables -L FORWARD -n -v
sudo iptables -P FORWARD ACCEPT
```

Desde `backend1`, probar conectividad hacia cada nodo monitorizado (con `jumpstart` abierto).

```bash
nc -vz 10.0.0.10 10050
nc -vz 10.0.0.11 10050
nc -vz 10.10.10.21 10050
nc -vz 10.0.0.1 10050
```

## 3. Crear los hosts en Zabbix y aplicar plantillas Linux

En la interfaz web de Zabbix, ir a `Configuration -> Hosts -> Create host`.

Para cada VM, configurar:

- **Host name**: nombre del host.
- **Groups**: `Linux servers`.
- **Interfaces**: añadir una interfaz tipo `Agent` con la IP del nodo y puerto `10050`.
- **Templates**: `Linux by Zabbix agent`.

## 4. Añadir monitorización de servicios

### 4.1 Frontend1 y Frontend2: Apache by HTTP

Añadir la plantilla `Apache by HTTP` en `frontend1` y `frontend2` sin eliminar la plantilla Linux existente.

Ruta:

```text
Configuration -> Hosts -> frontend1/frontend2 -> Template: Apache by HTTP
```

#### Ajustar macros

En la pestaña `Macros` de ambos hosts, comprobar en `Inherited and host macros`:

- `{$APACHE.STATUS.PORT}` en el puerto `80`.
- `{$APACHE.STATUS.SCHEME}` en `http`.

#### Habilitar `server-status`

Antes de configurar Apache, permitir acceso desde `backend1` al puerto 80 en ambos frontends.

```bash
sudo ufw allow from 10.10.10.20 to any port 80 proto tcp
sudo ufw reload
sudo ufw status verbose
```

Habilitar `mod_status`:

```bash
sudo a2enmod status
```

Crear el fichero de configuración:

```bash
sudo nano /etc/apache2/conf-available/server-status.conf
```

Contenido sugerido:

```apache
ExtendedStatus On
<Location /server-status>
    SetHandler server-status
    Require ip 127.0.0.1 10.10.10.20
</Location>
```

Habilitar la configuración y reiniciar Apache:

```bash
sudo a2enconf server-status
sudo systemctl restart apache2
sudo systemctl status apache2
```

Comprobaciones:

```bash
curl http://localhost/server-status?auto
curl http://10.0.0.10/server-status?auto
curl http://10.0.0.11/server-status?auto
```

### 4.2 Backend1, Backend2 y balanceador: Nginx y checks HTTP

Añadir la plantilla `Nginx by Zabbix agent` en `backend1`, `backend2` y `balanceador` sin eliminar la plantilla Linux existente.

Ruta:

```text
Configuration -> Hosts -> backend1/backend2/balanceador -> Template: Nginx by Zabbix agent
```

#### Crear ítems manuales

En la pantalla donde se listan los hosts, abrir el enlace `Items` de `backend1`, `backend2` y `balanceador`, y crear los siguientes ítems.

Para `backend1` y `backend2`:

- **Estado HTTP puerto 80** → `net.tcp.service[http,,80]`
- **Tiempo respuesta HTTP puerto 80** → `net.tcp.service.perf[http,,80]`

Para `balanceador`:

- **Estado HTTP puerto 80** → `net.tcp.service[http,,80]`
- **Tiempo respuesta HTTP puerto 80** → `net.tcp.service.perf[http,,80]`
