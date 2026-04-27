# Instalación y configuración de backend1

## 1. Clonar máquina base

Desde VirtualBox:

- Click derecho en `base-ubuntu` → Clonar
- Nombre: `backend1`
- Tipo: **Clon completo**
- Reinitializar MAC address

## 2. Configuración de red (VirtualBox)

Ir a configuración y luego a red

### Adaptador 1
- Tipo: **Red interna**
- Nombre: **internal**

## 3. Configurar IP fija

Dentro de la VM:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Configuración:
```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      addresses:
        - 10.10.10.20/24
      routes:
        - to: 10.0.0.0/24
          via: 10.10.10.10 
```

## 4. Aplicar configuración

```bash
sudo netplan apply
```

 ## 5. Comprobar IP

al poner el comando:
```bash
ip a
```

Debe aparecer:
```bash
192.168.100.20

10.10.10.20
```

## 6. Instalar servidor web (NGINX)
```bash
sudo apt update
```

```bash
sudo apt install nginx -y
```
## 7. Crear página identificativa

Esto es para poder comprobar el balanceo de carga:

```bash
echo "SOY BACKEND1" | sudo tee /var/www/html/index.html
```

## 8. Reiniciar servicio

```bash
sudo systemctl restart nginx
```

## 9. Comprobar funcionamiento

```bash
curl localhost
```

## 10. Probar conexión

Desde frontend1:
```bash
ping 10.0.0.20
```

si va bien deberia de hacer ping

## 11. SIGUIENTE PASO

Crear las máquinas:

* backend2
* balanceador
* jumpstart


