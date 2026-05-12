# Instalación y configuración de `router-linux` en UTM

Esta máquina sirve como router de respaldo entre las redes `main` e `internal`. Si `jumpstart` cae, `router-linux` puede seguir dando conectividad entre ambas redes mediante las IPs virtuales de `keepalived`.

## 1. Clonar la máquina base

Desde UTM:

- Seleccionar `base-ubuntu`
- Clonar la máquina
- Nombre: `router-linux`

Si UTM te pregunta por la dirección MAC, deja que genere una nueva.

## 2. Configuración de red en UTM

La máquina `router-linux` debe tener tres adaptadores:

### Adaptador 1

- Tipo: **Red compartida**
- Uso: salida a Internet

### Adaptador 2

- Tipo: **Sólo host**
- Uso: red `main`

Debe estar en la misma red `Sólo host` que `frontend1`, `frontend2`, `balanceador` y el adaptador `main` de `jumpstart`.

### Adaptador 3

- Tipo: **Sólo host**
- Uso: red `internal`

Debe estar en la misma red `Sólo host` que `backend1`, `backend2` y el adaptador `internal` de `jumpstart`.

## 3. Comprobar interfaces

Arrancar `router-linux` y ejecutar:

```bash
ip a
ip route
```

En UTM normalmente aparecerán:

- `enp0s1` -> red compartida / NAT
- `enp0s2` -> red `main`
- `enp0s3` -> red `internal`

Usa los nombres reales que te aparezcan. Si no coinciden, cambia los nombres en el netplan y en `keepalived.conf`.

## 4. Configurar IP fija y hostname

Editar netplan:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Si ese fichero no existe, mira cuál tienes con:

```bash
ls /etc/netplan
```

Configuración recomendada:

```yaml
network:
  version: 2
  ethernets:
    enp0s1:
      dhcp4: true
    enp0s2:
      dhcp4: false
      addresses:
        - 192.168.50.254/24
    enp0s3:
      dhcp4: false
      addresses:
        - 10.10.10.254/24
```

Cambiar hostname:

```bash
sudo hostnamectl set-hostname router-linux
```

## 5. Aplicar configuración

```bash
sudo netplan generate
sudo netplan apply
```

Comprobar:

```bash
ip a
ip route
hostname
```

## 6. Activar forwarding

Editar:

```bash
sudo nano /etc/sysctl.conf
```

Descomentar o añadir esta línea:

```bash
net.ipv4.ip_forward=1
```

Aplicar:

```bash
sudo sysctl -p
```

Debe devolver:

```bash
net.ipv4.ip_forward = 1
```

## 7. Instalar keepalived

```bash
sudo apt update
sudo apt install keepalived -y
```

## 8. Configurar keepalived

Editar:

```bash
sudo nano /etc/keepalived/keepalived.conf
```

Contenido:

```text
vrrp_instance VI_MAIN {
    state BACKUP
    interface enp0s2
    virtual_router_id 51
    priority 50
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass garpass
    }
    virtual_ipaddress {
        192.168.50.100/24
    }
}

vrrp_instance VI_INTERNAL {
    state BACKUP
    interface enp0s3
    virtual_router_id 52
    priority 50
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass garpass
    }
    virtual_ipaddress {
        10.10.10.100/24
    }
}
```

Si tus interfaces no se llaman `enp0s2` y `enp0s3`, cámbialas aquí también.

## 9. Arrancar keepalived

```bash
sudo systemctl unmask keepalived
sudo systemctl enable keepalived
sudo systemctl restart keepalived
sudo systemctl status keepalived
```

Para salir del estado del servicio, pulsar `q`.

## 10. Comprobar IPs virtuales

```bash
ip a | grep -E "192.168.50.100|10.10.10.100"
```

Si `jumpstart` está encendido y tiene mayor prioridad, es normal que `router-linux` no tenga las IPs virtuales activas. Si paras `keepalived` en `jumpstart`, deberían aparecer en `router-linux`.

## 11. Probar conectividad

Desde `router-linux`:

```bash
ping -c 4 192.168.50.10
ping -c 4 10.10.10.1
ping -c 4 10.10.10.10
ping -c 4 10.10.10.11
```

Desde una máquina de la red `main`, por ejemplo `frontend1`, probar:

```bash
ping -c 4 10.10.10.10
```

Desde una máquina de la red `internal`, por ejemplo `backend1`, probar:

```bash
ping -c 4 192.168.50.20
```
