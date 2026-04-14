# 🖥️ Instalación y configuración de backend1

## 🥇 1. Clonar máquina base

Desde VirtualBox:

- Click derecho en `base-ubuntu` → Clonar
- Nombre: `backend1`
- Tipo: **Clon completo**
- ✔ Reinitializar MAC address

---

## 🥈 2. Configuración de red (VirtualBox)

Ir a:

Configuración → Red

### Adaptador 1
- Tipo: NAT

### Adaptador 2
- Tipo: Red interna
- Nombre: main ⚠️ (MUY IMPORTANTE)

---

## 🥉 3. Configurar IP fija

Dentro de la VM:


sudo nano /etc/netplan/00-installer-config.yaml

🔧 Configuración dentro de eso

network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.100.20/24
      gateway4: 192.168.100.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

    enp0s8:
      dhcp4: no
      addresses:
        - 10.0.0.20/24


▶️ 4. Aplicar configuración

sudo netplan apply

🔍 5. Comprobar IP

ip a

Debe aparecer:

192.168.100.20
10.0.0.20


🧪 6. Probar conexión

Desde frontend1:   ping 10.0.0.20 si va bien deberia de hacer ping


