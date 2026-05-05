# Instalación y configuración de `jumpstart` en UTM

## 1. Clonar la máquina base

Desde UTM:

- Seleccionar `base-ubuntu`
- Clonar la máquina
- Nombre: `jumpstart`

## 2. Configuración de red en UTM

La máquina `jumpstart` debe tener tres adaptadores:

### Adaptador 1

- Tipo: **Red compartida**
- Uso: salida a Internet

### Adaptador 2

- Tipo: **Sólo host**
- Uso: red `main`

### Adaptador 3

- Tipo: **Sólo host**
- Uso: red `internal`

Importante:

- el adaptador 2 debe estar en la misma red `Sólo host` que `frontend1` y `frontend2`
- el adaptador 3 debe estar en la misma red `Sólo host` que `backend1`, `backend2` y `balanceador`

## 3. Arrancar la máquina y comprobar interfaces

Arrancar `jumpstart` y ejecutar:

```bash
ip a
```

En UTM normalmente aparecerán:

- `enp0s1` -> red compartida / NAT
- `enp0s2` -> red `main`
- `enp0s3` -> red `internal`

Importante: usa en el fichero de red los nombres que te aparezcan realmente a ti.

## 4. Configurar red y hostname con script

La configuración dentro de Ubuntu no se hace a mano, sino con el script del repositorio:

```bash
automatizacion/PcCarlota/scripts/configurar_jumpstart.sh
```

Ejecutar:

```bash
chmod +x automatizacion/PcCarlota/scripts/configurar_jumpstart.sh
sudo ./automatizacion/PcCarlota/scripts/configurar_jumpstart.sh jumpstart
```

El script hace automáticamente:

- detectar la interfaz con salida a Internet
- detectar la interfaz de la red `main`
- detectar la interfaz de la red `internal`
- escribir el fichero correcto de `netplan`
- configurar `192.168.50.10/24` para `main`
- configurar `10.10.10.1/24` para `internal`
- cambiar el hostname a `jumpstart`

## 5. Qué configura el script

```yaml
network:
  version: 2
  ethernets:
    <interfaz-nat>:
      dhcp4: true
    <interfaz-main>:
      dhcp4: false
      addresses:
        - 192.168.50.10/24
    <interfaz-internal>:
      dhcp4: false
      addresses:
        - 10.10.10.1/24
```

## 6. Comprobar el resultado

```bash
ip a
ip route
hostname
```

Debe aparecer:

- una IP tipo `192.168.2.X` en `enp0s1`
- `192.168.50.10/24` en `enp0s2`
- `10.10.10.1/24` en `enp0s3`

## 7. Comprobar conectividad

Probar Internet:

```bash
ping -c 4 8.8.8.8
ping -c 4 google.com
```

Probar máquinas de la red `main`:

```bash
ping -c 4 192.168.50.30
ping -c 4 192.168.50.31
```

Probar máquinas de la red `internal`:

```bash
ping -c 4 10.10.10.10
ping -c 4 10.10.10.11
ping -c 4 10.10.10.20
```

Si alguna no responde, revisar:

- que las máquinas estén encendidas
- que los adaptadores estén en la red `Sólo host` correcta
- que las IPs configuradas sean correctas

## 8. Generar clave SSH

```bash
ssh-keygen -t ed25519
```

Cuando pregunte:

- `Enter file in which to save the key` -> pulsar Enter
- `Enter passphrase` -> pulsar Enter dos veces si no quieres contraseña

Se crearán:

```bash
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

## 9. Copiar la clave SSH al resto de máquinas

Desde `jumpstart`, ejecutar:

```bash
ssh-copy-id usuario@192.168.50.30
ssh-copy-id usuario@192.168.50.31
ssh-copy-id usuario@10.10.10.10
ssh-copy-id usuario@10.10.10.11
ssh-copy-id usuario@192.168.50.20
```

La primera vez aparecerá:

```bash
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Contestar `yes` y escribir la contraseña de la máquina destino.

## 10. Probar SSH sin contraseña

Desde `jumpstart`, comprobar:

```bash
ssh usuario@192.168.50.30
ssh usuario@192.168.50.31
ssh usuario@10.10.10.10
ssh usuario@10.10.10.11
ssh usuario@192.168.50.20
```

Para salir:

```bash
exit
```

## 11. Instalar Ansible

```bash
sudo apt update
sudo apt install ansible -y
ansible --version
```

## 12. Preparar inventario

Usar el inventario común del repositorio:

```bash
inventario/hosts.ini
```

Ahora mismo el inventario del grupo usa:

```bash
ansible_user=alejandroro
```

No lo cambies si tus compañeros han acordado usar ese usuario.

## 13. Comprobar que Ansible llega a los nodos

```bash
ansible all -i inventario/hosts.ini -m ping
```

El resultado esperado es:

```bash
SUCCESS
"ping": "pong"
```

## 14. Desplegar `frontend1` y `frontend2` con Ansible

Desde `jumpstart`, ejecutar:

```bash
ansible-playbook -i inventario/hosts.ini automatizacion/PcCarlota/playbooks/frontend_wordpress.yml --ask-become-pass
```

Este playbook instala automáticamente en los frontends:

- `apache2`
- `php`
- `php-mysql`
- `mysql-client`
- WordPress
- `wp-config.php`

## 15. Activar forwarding entre frontends y backends

Editar:

```bash
sudo nano /etc/sysctl.conf
```

Descomentar esta línea:

```bash
net.ipv4.ip_forward=1
```

Aplicar el cambio:

```bash
sudo sysctl -p
cat /proc/sys/net/ipv4/ip_forward
```

Debe devolver:

```bash
1
```

## 16. Comprobación final

Desde `frontend1` o `frontend2`, cuando `jumpstart` y los backends estén listos:

```bash
ping -c 4 192.168.50.10
ping -c 4 10.10.10.10
```

Si WordPress no termina de cargar pero Apache sí responde, normalmente significa que aún falta la base de datos o la conectividad con la red `internal`.
