# Instalación y configuración de `frontend1`

Esta máquina forma parte de la parte 4, frontend web y CMS. El objetivo es dejar `frontend1` sirviendo WordPress con Apache y conectado a la base de datos de la red `internal`.

Datos usados en VirtualBox:

```text
frontend1  10.0.0.10
frontend2  10.0.0.11
backend DB 10.10.10.20
```

## 1. Clonar la máquina base

- Click derecho en `base-ubuntu`
- Seleccionar `Clonar`
- Nombre: `frontend1`
- Tipo: **Clon completo**
- Reinitializar la MAC si lo pide

## 2. Configuración de red

La máquina debe tener dos adaptadores:

- uno con salida a Internet
- otro para la red interna `main`

### Adaptador 1

- Conectado a: **NAT**

### Adaptador 2

- Conectado a: **Red interna**
- Nombre: `main`

## 3. Arrancar la máquina y comprobar interfaces

Arrancar `frontend1` y ejecutar:

```bash
ip a
```

Deben aparecer normalmente:

- `enp0s3` -> NAT
- `enp0s8` -> red interna

## 4. Configurar red y hostname con script

La configuración dentro de Ubuntu no se hace a mano, sino con el script del repositorio:

```bash
automatizacion/VirtualBox/scripts/configurar_frontend.sh
```

Ejecutar:

```bash
chmod +x automatizacion/VirtualBox/scripts/configurar_frontend.sh
sudo ./automatizacion/VirtualBox/scripts/configurar_frontend.sh frontend1 10.0.0.10
```

El script hace automáticamente:

- detectar la interfaz con salida a Internet
- detectar la interfaz interna
- escribir el fichero correcto de `netplan`
- configurar la IP `10.0.0.10/24`
- añadir la ruta hacia `10.10.10.0/24` vía `10.0.0.100`
- cambiar el hostname a `frontend1`

## 5. Qué configura el script

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: false
      addresses:
        - 10.0.0.10/24
      routes:
        - to: 10.10.10.0/24
          via: 10.0.0.100
          on-link: true
```

## 6. Comprobar el resultado

```bash
ip a
ip route
hostname
```

Debe aparecer:

- una IP de Internet en la interfaz NAT
- `10.0.0.10/24` en la interfaz interna
- la ruta:

```bash
10.10.10.0/24 via 10.0.0.100 dev <interfaz-interna>
```

En VirtualBox, normalmente será:

```bash
10.10.10.0/24 via 10.0.0.100 dev enp0s8
```

## 7. Comprobar conectividad con `frontend2`

Con las dos máquinas encendidas:

```bash
ping -c 4 10.0.0.11
```

Si no responde, revisar:

- que `frontend1` y `frontend2` estén encendidas
- que el segundo adaptador de ambas esté en la misma red interna
- que las IPs configuradas sean correctas

## 8. Comprobar SSH desde `jumpstart`

Antes de desplegar WordPress, `jumpstart` debe poder entrar por SSH en `frontend1`.

Desde `jumpstart`:

```bash
ping -c 4 10.0.0.10
ssh TU_USUARIO@10.0.0.10
```

Si se usan claves SSH:

```bash
ssh-copy-id TU_USUARIO@10.0.0.10
```

En el inventario de VirtualBox hay que cambiar `TU_USUARIO` por el usuario real de las máquinas:

```bash
automatizacion/VirtualBox/hosts.ini
```

## 9. Despliegue del software

La instalación de Apache, PHP y WordPress no se hace manualmente dentro de `frontend1`.

Importante: el playbook descarga WordPress en `jumpstart` y luego lo copia a los frontends. Así no hace falta que `frontend1` tenga salida directa a Internet.

Una vez que:

- `frontend1` y `frontend2` tienen su red configurada
- ambas aceptan SSH
- `jumpstart` está lista
- Ansible funciona desde `jumpstart`

el despliegue se realiza de forma automatizada con el playbook:

```bash
automatizacion/VirtualBox/playbooks/frontend_wordpress.yml
```

Desde `jumpstart`, en la carpeta del repositorio, ejecutar:

```bash
ansible-playbook -i automatizacion/VirtualBox/hosts.ini automatizacion/VirtualBox/playbooks/frontend_wordpress.yml -K
```

Si todavía no hay claves SSH copiadas:

```bash
ansible-playbook -i automatizacion/VirtualBox/hosts.ini automatizacion/VirtualBox/playbooks/frontend_wordpress.yml -k -K
```

Este playbook:

- instala Apache, PHP, extensiones PHP de WordPress y cliente MySQL
- descarga WordPress en `jumpstart`
- copia WordPress a `/var/www/html`
- genera `wp-config.php`
- conecta WordPress con la base de datos `10.10.10.20`
- activa `mod_rewrite` y la configuración de Apache para WordPress
- reinicia Apache

## 10. Comprobar WordPress

Desde `jumpstart`:

```bash
curl -I http://10.0.0.10
```

El resultado esperado es:

```text
HTTP/1.1 302 Found
Location: http://10.0.0.10/wp-admin/install.php
```

Si no hay navegador gráfico, se puede usar `lynx` desde `jumpstart`:

```bash
sudo apt install lynx -y
lynx http://10.0.0.10
```

Si aparece el instalador de WordPress, `frontend1` está correctamente desplegado.

## 11. Comprobar Apache, WordPress y base de datos

En `frontend1`:

```bash
systemctl status apache2 --no-pager
ls -l /var/www/html/wp-config.php
curl -I http://localhost
mysql -h 10.10.10.20 -u wpuser -ppassword -e "SHOW DATABASES;"
```

La conexión MySQL debe mostrar las bases de datos. Si `curl` funciona pero MySQL no, Apache y WordPress están bien, pero falta revisar la parte 3 o la conectividad hacia la base de datos.

El fichero `wp-config.php` debe usar estos datos:

```text
DB_NAME=wordpress
DB_USER=wpuser
DB_HOST=10.10.10.20
```

## 12. Checklist de entrega

- `frontend1` tiene IP `10.0.0.10/24`.
- `frontend1` tiene ruta hacia `10.10.10.0/24` vía `10.0.0.100`.
- `jumpstart` puede hacer SSH a `frontend1`.
- Apache está instalado y habilitado.
- WordPress está desplegado en `/var/www/html`.
- `wp-config.php` está generado con la base de datos correcta.
- `frontend1` responde por HTTP.
- WordPress redirige al instalador inicial.
- `frontend1` puede conectar con la base de datos por el puerto 3306.
