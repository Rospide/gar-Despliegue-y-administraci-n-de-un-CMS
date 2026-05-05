# Instalación y configuración de `frontend1`

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
- añadir la ruta hacia `10.10.10.0/24` vía `10.0.0.20`
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

- una IP de Internet en la interfaz NAT
- `10.0.0.10/24` en la interfaz interna
- la ruta:

```bash
10.10.10.0/24 via 10.0.0.20 dev <interfaz-interna>
```

En VirtualBox, normalmente será:

```bash
10.10.10.0/24 via 10.0.0.20 dev enp0s8
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

## 8. Despliegue del software

La instalación de Apache, PHP y WordPress no se hace manualmente dentro de `frontend1`.

Una vez que:

- `frontend1` y `frontend2` tienen su red configurada
- ambas aceptan SSH
- `jumpstart` está lista
- Ansible funciona desde `jumpstart`

el despliegue se realiza de forma automatizada con el playbook:

```bash
automatizacion/VirtualBox/playbooks/frontend_wordpress.yml
```

La ejecución se documenta en la guía de `jumpstart`.
