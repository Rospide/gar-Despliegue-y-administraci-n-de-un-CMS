# Instalación y configuración de Router-Linux

Esta máquina virtual sirve para crear redundancia, y si el jumpstart se cae que siga habiendo conexión entre la red main e internal

## 1. Clonar máquina base

Desde VirtualBox:

- Click derecho en `base-ubuntu` → Clonar
- Nombre: `Router-Linux`
- Tipo: **Clon completo**
- Reinitializar MAC address

## 2. Configuración de red (VirtualBox)

Ir a configuración y luego a red

### Adaptador 1
- Tipo: **NAT**
- Nombre: **internal**

### Adaptador 2
- Tipo: **Red Interna**
- Nombre: **main**

### Adaptador 3
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
      dhcp4: yes
    enp0s8:
      addresses:
        - 10.0.0.254/24
    enp0s9:
      addresses:
        - 10.10.10.254/24
```

## 4. Aplicar configuración

```bash
sudo netplan apply
```

## 5. Instalacion de keepalived

```bash
sudo apt update
```

```bash
sudo apt install keepalived
```

## 6. Archivo de configuración de keepalived
Hay que editar este archivo

```bash
sudo nano /etc/keepalived/keepalived.conf
```

Configuración:
```yaml
vrrp_instance VI_MAIN {
    state BACKUP
    interface enp0s8
    virtual_router_id 51
    priority 50
    virtual_ipaddress {
         10.0.0.100
    }
}

vrrp_instance VI_INTERNAL{
    state BACKUP
    interface enp0s9
    virtual_router_id 52
    priority 50
    virtual_ipaddress {
         10.10.10.100
    }
}
```

A continuación, escribir estos comandos para quitar el bloqueo, habiliarlo, arrancarlo y verificarlo:

```bash
sudo systemctl unmask keepalived
```

```bash
sudo systemctl enable keepalived
```

```bash
sudo systemctl start keepalived
```

```bash
sudo systemctl enable keepalived
```

Este ultimo comando, debe poner 'Active (running)' para que este activo: 
<img width="918" height="198" alt="imagen" src="https://github.com/user-attachments/assets/0e041d9e-edc0-4682-a656-2102932d948a" />

## 7. Activar forwarding
Entramos en:  
```bash
sudo nano /etc/sysctl.conf
```

y descomentamos la linea:
```bash
net.ipv4.ip_forward=1
```

Luego, aplicamos los cambios con: 
```bash
sudo netplan apply
```
