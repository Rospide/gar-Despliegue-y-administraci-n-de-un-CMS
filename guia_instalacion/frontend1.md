# Instalación y configuración de `frontend1`

## 1. Clonar la máquina base

Debido a que una compañera utiliza Mac y por lo tanto va a hacer la configuración de las máquinas virtuales en UTM en vez de Virtualbox esta guía especifíca las dos configuraciones. En las que el cambio más significativo es el nombre de las interfaces.

### En VirtualBox

- Click derecho en `base-ubuntu`
- Seleccionar `Clonar`
- Nombre: `frontend1`
- Tipo: **Clon completo**
- Reinitializar la MAC si lo pide

### En UTM

- Click derecho en `base-ubuntu`
- Seleccionar `Clonar`
- Nombre: `frontend1`

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

## 3. Arrancar la máquina y comprobar interfaces

Arrancar `frontend1` y ejecutar:

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
        - 10.0.0.10/24
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
        - 10.0.0.10/24
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
- que el segundo adaptador de ambas esté en la misma red interna
- que las IPs configuradas sean correctas

## 8. Cambiar hostname

```bash
sudo hostnamectl set-hostname frontend1
```

Cerrar sesión o reiniciar para ver el nuevo nombre.

## 9. Siguiente paso

Preparar `frontend2` con la misma configuración cambiando solo la IP interna.
