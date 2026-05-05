# Instalación y configuración de `backend2` en UTM

Esta guía instala y configura `backend2` para UTM. Esta máquina se configura manualmente, sin script de automatización.

## 1. Clonar la máquina base

Desde UTM:

- Seleccionar `base-ubuntu`
- Clonar la máquina
- Nombre: `backend2`

Si UTM te pregunta por la dirección MAC, deja que genere una nueva.

## 2. Configuración de red en UTM

La máquina `backend2` debe tener dos adaptadores:

### Adaptador 1

- Tipo: **Red compartida**
- Uso: salida a Internet

### Adaptador 2

- Tipo: **Sólo host**
- Uso: red `internal`

Debe estar en la misma red `Sólo host` que `backend1` y el adaptador `internal` de `jumpstart`.

## 3. Comprobar interfaces

Arrancar `backend2` y ejecutar:

```bash
ip a
```

En UTM normalmente aparecerán:

- `enp0s1` -> red compartida / NAT
- `enp0s2` -> red `internal`

Usa los nombres reales que te aparezcan.

## 4. Configurar IP fija y hostname

Editar netplan:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
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
        - 10.10.10.11/24
      routes:
        - to: 192.168.50.0/24
          via: 10.10.10.1
          on-link: true
```

Cambiar hostname:

```bash
sudo hostnamectl set-hostname backend2
```

## 5. Aplicar configuración

```bash
sudo netplan generate
sudo netplan apply
```

## 6. Comprobar resultado

```bash
ip a
ip route
hostname
```

Debe aparecer:

- `10.10.10.11/24` en la interfaz `internal`
- ruta hacia `192.168.50.0/24` vía `10.10.10.1`

## 7. Probar conectividad

```bash
ping -c 4 10.10.10.1
ping -c 4 10.10.10.10
```

Desde `jumpstart`:

```bash
ping -c 4 10.10.10.11
```

## 8. Instalar servidor web NGINX

```bash
sudo apt update
sudo apt install nginx -y
```

## 9. Crear página identificativa

```bash
echo "SOY BACKEND2" | sudo tee /var/www/html/index.html
```

## 10. Reiniciar y comprobar

```bash
sudo systemctl restart nginx
curl localhost
```

Debe devolver:

```bash
SOY BACKEND2
```
