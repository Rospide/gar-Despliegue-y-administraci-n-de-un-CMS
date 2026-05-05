# Instalación y configuración de `balanceador` en UTM

Esta guía instala y configura el balanceador en UTM. Esta máquina se configura manualmente, sin script de automatización.

## 1. Clonar la máquina base

Desde UTM:

- Seleccionar `base-ubuntu`
- Clonar la máquina
- Nombre: `balanceador`

## 2. Configuración de red en UTM

La máquina `balanceador` debe tener dos adaptadores:

### Adaptador 1

- Tipo: **Red compartida**
- Uso: salida a Internet

### Adaptador 2

- Tipo: **Sólo host**
- Uso: red `main`

Debe estar en la misma red `Sólo host` que `frontend1`, `frontend2` y el adaptador `main` de `jumpstart`.

## 3. Comprobar interfaces

```bash
ip a
```

En UTM normalmente aparecerán:

- `enp0s1` -> red compartida / NAT
- `enp0s2` -> red `main`

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
        - 192.168.50.20/24
      routes:
        - to: 10.10.10.0/24
          via: 192.168.50.10
          on-link: true
```

Cambiar hostname:

```bash
sudo hostnamectl set-hostname balanceador
```

## 5. Aplicar configuración

```bash
sudo netplan generate
sudo netplan apply
```

## 6. Comprobar conectividad

```bash
ping -c 4 192.168.50.10
ping -c 4 10.10.10.10
ping -c 4 10.10.10.11
```

Si no responde a los backends, revisar que `jumpstart` tenga activado el forwarding entre `main` e `internal`.

## 7. Instalar NGINX

```bash
sudo apt update
sudo apt install nginx -y
```

## 8. Configurar balanceo

Editar:

```bash
sudo nano /etc/nginx/sites-available/default
```

Contenido:

```nginx
upstream backend_servers {
    server 10.10.10.10;
    server 10.10.10.11;
}

server {
    listen 80;

    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Validar y reiniciar:

```bash
sudo nginx -t
sudo systemctl restart nginx
```

## 9. Probar funcionamiento

```bash
curl http://localhost
```

Debe alternar entre:

```bash
SOY BACKEND1
SOY BACKEND2
```

Desde `frontend1` o `frontend2` también se puede probar:

```bash
curl http://192.168.50.20
```

## 10. Firewall opcional

```bash
sudo ufw default deny incoming
sudo ufw allow 80/tcp
sudo ufw allow from 192.168.50.10 to any port 22 proto tcp
sudo ufw enable
```
