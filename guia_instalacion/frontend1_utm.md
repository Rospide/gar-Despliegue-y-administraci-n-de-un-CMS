# Instalación y configuración de `frontend1` en UTM

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
automatizacion/scripts/configurar_frontend.sh
```

Ejecutar:

```bash
chmod +x automatizacion/scripts/configurar_frontend.sh
sudo ./automatizacion/scripts/configurar_frontend.sh frontend1 10.0.0.10
```

El script hace automáticamente:

- detectar la interfaz con salida a Internet
- detectar la interfaz interna
- escribir el fichero correcto de `netplan`
- configurar la IP `10.0.0.10/24`
- añadir la ruta hacia `10.10.10.0/24` vía `10.0.0.20`
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
        - 10.0.0.10/24
      routes:
        - to: 10.10.10.0/24
          via: 10.0.0.20
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
- `10.0.0.10/24` en la interfaz interna
- la ruta:

```bash
10.10.10.0/24 via 10.0.0.20 dev <interfaz-interna>
```

## 7. Comprobar conectividad con `frontend2`

Con las dos máquinas encendidas:

```bash
ping -c 4 10.0.0.11
```

Si no responde, revisar:

- que `frontend1` y `frontend2` estén encendidas
- que el segundo adaptador de ambas esté en la misma red `Sólo host`
- que las IPs configuradas sean correctas

## 8. Despliegue del software

La instalación de Apache, PHP y WordPress no se hace manualmente dentro de `frontend1`.

Una vez que:

- `frontend1` y `frontend2` tienen su red configurada
- ambas aceptan SSH
- `jumpstart` está lista
- Ansible funciona desde `jumpstart`

el despliegue se realiza de forma automatizada con el playbook:

```bash
automatizacion/playbooks/frontend_wordpress.yml
```

La ejecución se documenta en la guía de `jumpstart_utm.md`.
