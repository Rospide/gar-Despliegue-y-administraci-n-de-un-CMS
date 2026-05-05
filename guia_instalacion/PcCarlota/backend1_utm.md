# Instalación y configuración de `backend1` en UTM

Esta guía instala y configura `backend1` para tus máquinas en UTM.

## 1. Clonar la máquina base

Desde UTM:

- Seleccionar `base-ubuntu`
- Clonar la máquina
- Nombre: `backend1`

Si UTM te pregunta por la dirección MAC, deja que genere una nueva para evitar conflictos con la máquina base.

## 2. Configuración de red en UTM

La máquina `backend1` debe tener dos adaptadores:

### Adaptador 1

- Tipo: **Red compartida**
- Uso: salida a Internet para poder ejecutar `apt update` e instalar paquetes

### Adaptador 2

- Tipo: **Sólo host**
- Uso: red `internal`

Importante: este segundo adaptador debe estar en la misma red `Sólo host` que `backend2`, `balanceador` y el adaptador `internal` de `jumpstart`.

## 3. Arrancar la máquina y comprobar interfaces

Arrancar `backend1` y ejecutar:

```bash
ip a
```

En UTM normalmente aparecerán:

- `enp0s1` -> red compartida / NAT
- `enp0s2` -> red `internal`

Importante: usa en el fichero de red los nombres que te aparezcan realmente a ti. Si tus interfaces no se llaman `enp0s1` y `enp0s2`, cambia esos nombres en el `netplan`.

## 4. Configurar IP fija y hostname

Editar el fichero de red:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Si ese fichero no existe, mira cuál tienes con:

```bash
ls /etc/netplan
```

Configuración recomendada para `backend1`:

```yaml
network:
  version: 2
  ethernets:
    enp0s1:
      dhcp4: true
    enp0s2:
      dhcp4: false
      addresses:
        - 10.10.10.10/24
      routes:
        - to: 192.168.50.0/24
          via: 10.10.10.1
          on-link: true
```

Después cambiar el hostname:

```bash
sudo hostnamectl set-hostname backend1
```

## 5. Aplicar configuración

```bash
sudo netplan generate
sudo netplan apply
```

## 6. Comprobar el resultado

```bash
ip a
ip route
hostname
```

Debe aparecer:

- una IP tipo `192.168.X.X` en la interfaz de red compartida
- `10.10.10.10/24` en la interfaz `internal`
- la ruta:

```bash
192.168.50.0/24 via 10.10.10.1 dev <interfaz-internal>
```

## 7. Probar conectividad

Probar Internet desde `backend1`:

```bash
ping -c 4 8.8.8.8
ping -c 4 google.com
```

Probar conexión con `jumpstart` por la red `internal`:

```bash
ping -c 4 10.10.10.1
```

Cuando `backend2` y `balanceador` estén creados, también se podrá probar:

```bash
ping -c 4 10.10.10.11
ping -c 4 192.168.50.20
```

Desde `jumpstart`, probar que se ve `backend1`:

```bash
ping -c 4 10.10.10.10
```

Si no responde, revisar:

- que `backend1` esté encendida
- que el segundo adaptador esté en la red `Sólo host` `internal`
- que `jumpstart` tenga configurada la IP `10.10.10.1/24`
- que la IP de `backend1` sea `10.10.10.10/24`

## 8. Instalar servidor web NGINX

```bash
sudo apt update
sudo apt install nginx -y
```

## 9. Crear página identificativa

Esto sirve para comprobar después el balanceo de carga:

```bash
echo "SOY BACKEND1" | sudo tee /var/www/html/index.html
```

## 10. Reiniciar servicio

```bash
sudo systemctl restart nginx
sudo systemctl status nginx
```

Para salir del estado del servicio, pulsar `q`.

## 11. Comprobar funcionamiento local

Desde `backend1`:

```bash
curl localhost
```

Debe devolver:

```bash
SOY BACKEND1
```

## 12. Siguiente paso

Después de terminar `backend1`, crear y configurar:

- `backend2`
- `balanceador`
- `jumpstart`, si todavía no está lista

La base de datos Galera se configurará después con Ansible desde `jumpstart`, no manualmente desde `backend1`.
