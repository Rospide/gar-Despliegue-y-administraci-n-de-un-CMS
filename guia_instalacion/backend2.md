# 🖥️ Instalación y configuración de backend2

## 🥇 1. Clonar máquina base

Desde VirtualBox:

- Click derecho en `base-ubuntu` → Clonar
- Nombre: `backend2`
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

## 🔧 Configuración
```yalm
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: yes

    enp0s8:
      dhcp4: no
      addresses:
        - 10.10.10.21/24
```
        

## ▶️ 4. Aplicar configuración

sudo netplan apply

🔍 5. Comprobar IP

ip a

Debe aparecer:

192.168.100.21
10.10.10.21


🧪 6. Probar conexión

Desde frontend1:

ping 10.0.0.21

✔ Si responde → TODO CORRECTO
