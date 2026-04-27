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
