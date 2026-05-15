# Instalación y configuración de `frontend1` en UTM

Esta máquina forma parte de la parte 4, frontend web y CMS. El objetivo es dejar `frontend1` sirviendo WordPress con Apache y conectado a la base de datos MariaDB/Galera de los backends.

Datos usados en UTM:

```text
frontend1  192.168.50.30
frontend2  192.168.50.31
backend DB 10.10.10.10
```

## 1. Clonar la máquina base

Desde UTM:

- Seleccionar `base-ubuntu`
- Clonar la máquina
- Nombre: `frontend1`

## 2. Configuración de red en UTM

La máquina debe tener dos adaptadores:

### Adaptador 1

- Tipo: **Red compartida**
- Uso: salida a Internet

### Adaptador 2

- Tipo: **Sólo host**
- Uso: red `main`

Importante: este segundo adaptador debe estar en la misma red `Sólo host` que `frontend2` y `jumpstart`.

## 3. Arrancar la máquina y comprobar interfaces

Arrancar `frontend1` y ejecutar:

```bash
ip a
```

En UTM normalmente aparecerán:

- `enp0s1` -> red compartida / NAT
- `enp0s2` -> red `main`

Importante: usa los nombres de interfaz que te aparezcan realmente a ti.

## 4. Configurar red y hostname con script

La configuración dentro de Ubuntu se hace con el script del repositorio:

```bash
automatizacion/PcCarlota/scripts/configurar_frontend.sh
```
Desde nuestro terminal local en la carpeta donde se encuentra el archivo o usando la ruta completa:
   
```bash
scp configurar_frontend.sh carlotamo@tbworkers4.esi.uclm.es:~
```

Eso lo copia en Eso lo copia a tu carpeta personal remota, es decir, al home de carlotamo en tbworkers4.
   
Ejecutar:

```bash
chmod +x automatizacion/PcCarlota/scripts/configurar_frontend.sh
sudo ./automatizacion/PcCarlota/scripts/configurar_frontend.sh frontend1 192.168.50.30
```

El script hace automáticamente:

- detectar la interfaz con salida a Internet
- detectar la interfaz interna
- escribir el fichero correcto de `netplan`
- configurar la IP `192.168.50.30/24`
- añadir la ruta hacia `10.10.10.0/24` vía `192.168.50.10`
- cambiar el hostname a `frontend1`

## 5. Qué configura el script

```yaml
network:
  version: 2
  ethernets:
    <interfaz-externa>:
      dhcp4: true
    <interfaz-interna>:
      dhcp4: false
      addresses:
        - 192.168.50.30/24
      routes:
        - to: 10.10.10.0/24
          via: 192.168.50.10
          on-link: true
```

## 6. Comprobar el resultado

```bash
ip a
ip route
hostname
```

Debe aparecer:

- una IP tipo `192.168.2.X` en la interfaz externa
- `192.168.50.30/24` en la interfaz interna
- la ruta:

```bash
10.10.10.0/24 via 192.168.50.10 dev <interfaz-interna>
```

## 7. Comprobar conectividad con `frontend2`

Con las dos máquinas encendidas:

```bash
ping -c 4 192.168.50.31
```

Si no responde, revisar:

- que `frontend1` y `frontend2` estén encendidas
- que el segundo adaptador de ambas esté en la misma red `Sólo host`
- que las IPs configuradas sean correctas

## 8. Comprobar SSH desde `jumpstart`

Antes de desplegar WordPress, `jumpstart` debe poder entrar por SSH en `frontend1`.

Desde `jumpstart`:

```bash
ping -c 4 192.168.50.30
ssh carlotamo@192.168.50.30
```

Si se usan claves SSH:

```bash
ssh-copy-id carlotamo@192.168.50.30
```

Comprobar también que Ansible llega al frontend:

```bash
ansible -i automatizacion/PcCarlota/hosts.ini frontend1 -m ping
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
automatizacion/PcCarlota/playbooks/frontend_wordpress.yml
```

Desde `jumpstart`, en la carpeta del repositorio, ejecutar:

```bash
ansible-playbook -i automatizacion/PcCarlota/hosts.ini automatizacion/PcCarlota/playbooks/frontend_wordpress.yml -K
```

Si todavía no hay claves SSH copiadas:

```bash
ansible-playbook -i automatizacion/PcCarlota/hosts.ini automatizacion/PcCarlota/playbooks/frontend_wordpress.yml -k -K
```

Este playbook:

- instala Apache, PHP, extensiones PHP de WordPress y cliente MySQL
- descarga WordPress en `jumpstart`
- copia WordPress a `/var/www/html`
- genera `wp-config.php`
- conecta WordPress con la base de datos `10.10.10.10`
- activa `mod_rewrite` y la configuración de Apache para WordPress
- reinicia Apache

## 10. Comprobar WordPress

Desde `jumpstart`:

```bash
curl -I http://192.168.50.30
```

El resultado esperado es:

```text
HTTP/1.1 302 Found
Location: http://192.168.50.30/wp-admin/install.php
```

Si no hay navegador gráfico, se puede usar `lynx` desde `jumpstart`:

```bash
sudo apt install lynx -y
lynx http://192.168.50.30
```

Si aparece el instalador de WordPress, `frontend1` está correctamente desplegado.

## 11. Comprobar Apache, WordPress y base de datos

En `frontend1`:

```bash
systemctl status apache2 --no-pager
ls -l /var/www/html/wp-config.php
curl -I http://localhost
mysql -h 10.10.10.10 -u wpuser -ppassword -e "SHOW DATABASES;"
```

La conexión MySQL debe mostrar las bases de datos. Si `curl` funciona pero MySQL no, Apache y WordPress están bien, pero falta revisar la parte 3 o la conectividad hacia la base de datos.

El fichero `wp-config.php` debe usar estos datos:

```text
DB_NAME=wordpress
DB_USER=wpuser
DB_HOST=10.10.10.10
```

## 12. Checklist de entrega

- `frontend1` tiene IP `192.168.50.30/24`.
- `frontend1` tiene ruta hacia `10.10.10.0/24` vía `192.168.50.10`.
- `jumpstart` puede hacer SSH a `frontend1`.
- Apache está instalado y habilitado.
- WordPress está desplegado en `/var/www/html`.
- `wp-config.php` está generado con la base de datos correcta.
- `frontend1` responde por HTTP.
- WordPress redirige al instalador inicial.
- `frontend1` puede conectar con la base de datos por el puerto 3306.
