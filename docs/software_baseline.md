# Software baseline

Esta tabla resume el software usado por la solucion, su version objetivo y su origen.

Las versiones de paquetes instalados con `apt` dependen del repositorio de Ubuntu disponible en el momento del despliegue. Para cerrar una entrega reproducible, despues de desplegar se recomienda ejecutar los comandos de verificacion del final de este documento y guardar la salida.

## Plataforma base

| Software | Version objetivo | Uso | Origen |
| --- | --- | --- | --- |
| VirtualBox | Version instalada en el anfitrion | Creacion y ejecucion de VMs | https://www.virtualbox.org/ |
| VBoxManage | Misma version que VirtualBox | Automatizacion de VMs | https://www.virtualbox.org/manual/ch08.html |
| Ubuntu Server | 24.04.4 LTS segun ISO usada en el laboratorio | Sistema operativo base de las VMs | https://ubuntu.com/download/server |
| OpenSSH Server/Client | Paquete de Ubuntu 24.04 | Acceso remoto y copia de claves | https://packages.ubuntu.com/ |
| Bash | Paquete de Ubuntu 24.04 | Ejecucion de scripts | https://www.gnu.org/software/bash/ |

## Automatizacion

| Software | Version objetivo | Uso | Origen |
| --- | --- | --- | --- |
| Ansible | Paquete de Ubuntu/PPA usado en `jumpstart` | Ejecucion de playbooks | https://docs.ansible.com/ |
| Python 3 | Paquete de Ubuntu 24.04 | Interprete requerido por Ansible | https://www.python.org/ |
| sshpass | Paquete de Ubuntu 24.04 | Apoyo a conexiones SSH iniciales si no hay claves | https://packages.ubuntu.com/ |
| apt-rdepends | Paquete de Ubuntu 24.04 | Descarga de dependencias para repositorio local MariaDB | https://packages.ubuntu.com/ |
| dpkg-dev | Paquete de Ubuntu 24.04 | Generacion de indice `Packages.gz` | https://packages.ubuntu.com/ |
| apt-cacher-ng | Paquete de Ubuntu 24.04 | Proxy APT para Zabbix | https://www.unix-ag.uni-kl.de/~bloch/acng/ |

## Red y balanceo

| Software | Version objetivo | Uso | Origen |
| --- | --- | --- | --- |
| Netplan | Paquete de Ubuntu 24.04 | Configuracion de red | https://netplan.io/ |
| UFW | Paquete de Ubuntu 24.04 | Firewall local | https://launchpad.net/ufw |
| keepalived | Paquete de Ubuntu 24.04 | VIPs `10.0.0.100` y `10.10.10.100` | https://www.keepalived.org/ |
| Nginx | Paquete de Ubuntu 24.04 | Balanceador HTTP | https://nginx.org/ |
| netcat-openbsd | Paquete de Ubuntu 24.04 | Comprobaciones de puertos | https://packages.ubuntu.com/ |

## CMS y capa web

| Software | Version objetivo | Uso | Origen |
| --- | --- | --- | --- |
| Apache HTTP Server | Paquete de Ubuntu 24.04 | Servidor web de WordPress y Zabbix | https://httpd.apache.org/ |
| PHP | Paquete de Ubuntu 24.04 | Ejecucion de WordPress y Zabbix frontend | https://www.php.net/ |
| libapache2-mod-php | Paquete de Ubuntu 24.04 | Integracion PHP con Apache | https://packages.ubuntu.com/ |
| php-mysql | Paquete de Ubuntu 24.04 | Conexion PHP con MariaDB/MySQL | https://packages.ubuntu.com/ |
| php-curl | Paquete de Ubuntu 24.04 | Extension PHP para peticiones HTTP | https://packages.ubuntu.com/ |
| php-gd | Paquete de Ubuntu 24.04 | Extension grafica PHP | https://packages.ubuntu.com/ |
| php-mbstring | Paquete de Ubuntu 24.04 | Extension PHP para cadenas multibyte | https://packages.ubuntu.com/ |
| php-xml | Paquete de Ubuntu 24.04 | Extension XML para PHP | https://packages.ubuntu.com/ |
| php-xmlrpc | Paquete de Ubuntu 24.04 | Extension XML-RPC para PHP | https://packages.ubuntu.com/ |
| php-soap | Paquete de Ubuntu 24.04 | Extension SOAP para PHP | https://packages.ubuntu.com/ |
| php-intl | Paquete de Ubuntu 24.04 | Internacionalizacion PHP | https://packages.ubuntu.com/ |
| php-zip | Paquete de Ubuntu 24.04 | Manejo de ZIP en PHP | https://packages.ubuntu.com/ |
| WordPress | `latest.tar.gz` descargado en el despliegue | CMS | https://wordpress.org/latest.tar.gz |
| unzip | Paquete de Ubuntu 24.04 | Descompresion de archivos | https://packages.ubuntu.com/ |
| tar | Paquete de Ubuntu 24.04 | Empaquetado y descompresion | https://www.gnu.org/software/tar/ |

## Base de datos

| Software | Version objetivo | Uso | Origen |
| --- | --- | --- | --- |
| MariaDB Server | Paquete de Ubuntu 24.04 descargado para repositorio local | Base de datos WordPress y Zabbix | https://mariadb.org/ |
| MariaDB Client | Paquete de Ubuntu 24.04 descargado para repositorio local | Cliente de administracion | https://mariadb.org/ |
| MariaDB Common | Paquete de Ubuntu 24.04 | Archivos comunes MariaDB | https://mariadb.org/ |
| Galera 3 | Paquete `galera-3` de Ubuntu 24.04 | Replicacion del cluster | https://galeracluster.com/ |
| socat | Paquete de Ubuntu 24.04 | Dependencia de Galera/SST | http://www.dest-unreach.org/socat/ |
| tinyca | Paquete de Ubuntu 24.04 | Dependencia incluida en repositorio local | https://packages.ubuntu.com/ |
| mysql-client | Paquete de Ubuntu 24.04 | Cliente usado por frontales para pruebas | https://packages.ubuntu.com/ |

## Monitorizacion

| Software | Version objetivo | Uso | Origen |
| --- | --- | --- | --- |
| Zabbix | 6.0 LTS | Monitorizacion de nodos y servicios | https://www.zabbix.com/download |
| zabbix-release | `zabbix-release_latest_6.0+ubuntu20.04_all.deb` | Repositorio Zabbix | https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/ |
| zabbix-server-mysql | 6.0 LTS desde repositorio Zabbix | Servidor Zabbix con backend MySQL/MariaDB | https://repo.zabbix.com/ |
| zabbix-frontend-php | 6.0 LTS desde repositorio Zabbix | Interfaz web Zabbix | https://repo.zabbix.com/ |
| zabbix-apache-conf | 6.0 LTS desde repositorio Zabbix | Configuracion Apache para Zabbix | https://repo.zabbix.com/ |
| zabbix-sql-scripts | 6.0 LTS desde repositorio Zabbix | Esquema inicial de base de datos | https://repo.zabbix.com/ |
| zabbix-agent | 6.0 LTS desde repositorio Zabbix | Agentes en nodos monitorizados | https://repo.zabbix.com/ |

## Comandos para registrar versiones reales

Ejecutar en el anfitrion:

```bash
VBoxManage --version
```

Ejecutar en `jumpstart`:

```bash
ansible --version
python3 --version
ssh -V
apt-cache policy ansible python3 openssh-client apt-rdepends dpkg-dev apt-cacher-ng
```

Ejecutar en frontales:

```bash
apache2 -v
php -v
mysql --version
dpkg -l | grep -E 'apache2|php|mysql-client|zabbix-agent'
```

Ejecutar en backends:

```bash
mariadb --version
mysql --version
dpkg -l | grep -E 'mariadb|galera|socat|tinyca|zabbix'
```

Ejecutar en el balanceador:

```bash
nginx -v
dpkg -l | grep -E 'nginx|zabbix-agent'
```

Ejecutar en `router-linux`:

```bash
keepalived --version
dpkg -l | grep -E 'keepalived|ufw|zabbix-agent'
```
