# 🖥️ Instalación y configuración de frontend2

## 🥇 1. Clonar máquina base

Desde VirtualBox:

- Click derecho en `base-ubuntu` → Clonar
- Nombre: `frontend2`
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


network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: yes

    enp0s8:
      dhcp4: no
      addresses:
        - 10.0.0.11/24



▶️ 4. Aplicar configuración.
sudo netplan apply

5. Comprobar IP

ip a

Debe aparecer:

192.168.100.11
10.0.0.11


🔁 6. Probar conexión

Desde frontend1:(que este el frontend2 encendido)

ping 10.0.0.11

✔ Si responde → TODO CORRECTO
