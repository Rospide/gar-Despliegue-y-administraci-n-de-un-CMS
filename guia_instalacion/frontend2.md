# Instalación y configuración de `frontend2`

## 1. Clonar la máquina base

Debido a que una compañera utiliza Mac y por lo tanto va a hacer la configuración de las máquinas virtuales en UTM en vez de Virtualbox esta guía especifíca las dos configuraciones. En las que el cambio más significativo es el nombre de las interfaces.

### En VirtualBox

- Click derecho en `base-ubuntu`
- Seleccionar `Clonar`
- Nombre: `frontend2`
- Tipo: **Clon completo**
- Reinitializar la MAC si lo pide

### En UTM

- Click derecho en `base-ubuntu`
- Seleccionar `Clonar`
- Nombre: `frontend2`

## 2. Configuración de red

La máquina debe tener dos adaptadores:

- uno con salida a Internet
- otro para la red interna `main`

### En VirtualBox

#### Adaptador 1

- Conectado a: **NAT**

#### Adaptador 2

- Conectado a: **Red interna**
- Nombre: `main`

### En UTM

#### Adaptador 1

- Tipo: **Red compartida**

#### Adaptador 2

- Tipo: **Sólo host**

Importante: en UTM, el segundo adaptador de `frontend2` debe estar en la misma red `Sólo host` que `frontend1`.

## 3. Arrancar la máquina y comprobar interfaces

Arrancar `frontend2` y ejecutar:

```bash
ip a
```

Las interfaces pueden cambiar según el programa de virtualización:

### Si usas VirtualBox

Normalmente aparecerán:

- `enp0s3` -> NAT
- `enp0s8` -> red interna

### Si usas UTM

Normalmente aparecerán:

- `enp0s1` -> red compartida / NAT
- `enp0s2` -> red interna

Importante: usa en tu fichero netplan los nombres que te aparezcan realmente en `ip a`.

## 4. Configurar IP fija

Editar el fichero de red. Según la instalación puede ser uno de estos:

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

o:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Puedes ver cuál existe con:

```bash
ls /etc/netplan
```

### Ejemplo para VirtualBox

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: false
      addresses:
        - 10.0.0.11/24
      routes:
        - to: 10.10.10.0/24
          via: 10.0.0.20
          on-link: true
```

### Ejemplo para UTM

```yaml
network:
  version: 2
  ethernets:
    enp0s1:
      dhcp4: true
    enp0s2:
      dhcp4: false
      addresses:
        - 10.0.0.11/24
      routes:
        - to: 10.10.10.0/24
          via: 10.0.0.20
          on-link: true
```

*Entre Vistualbox y UTM solo cambian las interfaces*

## 5. Aplicar la configuración

```bash
sudo netplan generate
sudo netplan apply
```

## 6. Comprobar el resultado

```bash
ip a
ip route
```

Debe aparecer:

- una IP de Internet en la interfaz NAT
- `10.0.0.11/24` en la interfaz interna
- la ruta:

```bash
10.10.10.0/24 via 10.0.0.20 dev <interfaz-interna>
```

## 7. Comprobar conectividad con `frontend1`

Con las dos máquinas encendidas:

```bash
ping -c 4 10.0.0.10
```

Si aparece `Destination Host Unreachable`, normalmente significa que:

- `frontend1` está apagada
- `frontend1` no tiene levantada la interfaz interna
- el segundo adaptador no está en la misma red interna

## 8. Cambiar hostname

```bash
sudo hostnamectl set-hostname frontend2
```

Cerrar sesión o reiniciar para ver el nuevo nombre.

## 9. Siguiente paso

Cuando exista `jumpstart`, probar también:

```bash
ping -c 4 10.0.0.20
```

## 10. Instalar Apache, PHP y WordPress

Una vez configurada la red del frontend, instalar el software del servidor web:

```bash
sudo apt update
sudo apt install apache2 php libapache2-mod-php php-mysql mysql-client -y
```

## 11. Descargar WordPress

```bash
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xvzf latest.tar.gz
```

## 12. Copiar WordPress al directorio web de Apache

```bash
sudo rm -rf /var/www/html/*
sudo cp -r wordpress/* /var/www/html/
```

## 13. Ajustar permisos

```bash
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html
```

## 14. Configurar WordPress

```bash
cd /var/www/html
sudo cp wp-config-sample.php wp-config.php
sudo nano wp-config.php
```

Cambiar estas líneas:

```php
define('DB_NAME', 'wordpress');
define('DB_USER', 'wpuser');
define('DB_PASSWORD', 'password');
define('DB_HOST', '10.10.10.20');
```

## 15. Reiniciar Apache

```bash
sudo systemctl restart apache2
sudo systemctl status apache2
```

Apache debe aparecer como:

```bash
active (running)
```

## 16. Comprobar que WordPress responde

```bash
curl http://localhost | head
```

Posibles resultados:

- si devuelve HTML de WordPress o una página de error de base de datos, Apache y PHP están funcionando
- si la petición se queda bloqueada, normalmente significa que WordPress está esperando la conexión con la base de datos

## 17. Comprobar conectividad con la base de datos

Antes de que WordPress funcione del todo, el frontend debe poder llegar a la base de datos:

```bash
ping -c 4 10.0.0.20
ping -c 4 10.10.10.20
```

Importante:

- `10.0.0.20` es `jumpstart`
- `10.10.10.20` es el backend donde está la base de datos

Si `jumpstart` todavía no está creada o configurada, WordPress no podrá terminar de cargar aunque Apache funcione correctamente.
