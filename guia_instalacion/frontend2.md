k# 🚀 GUÍA COMPLETA – CREACIÓN DE frontend1 (VERSIÓN FINAL)

## 🧠 OBJETIVO

Crear una máquina virtual `frontend1` a partir de una plantilla base, configurarla con IP fija y dejarla lista para comunicarse con otras máquinas.

---

# 🥇 1. CLONAR LA MÁQUINA BASE

En VirtualBox:

1. Click derecho sobre la VM base (ej: `base-ubuntu`)
2. Seleccionar → **Clonar**

### 🔹 Opciones:

* Nombre: `frontend1`
* Tipo: **Clon completo**
* ✔ Reinitializar MAC address

👉 Finalizar clonación

---

# 🥈 2. CONFIGURAR RED EN VIRTUALBOX

Ir a:

👉 Configuración → Red

---

## 🔹 Adaptador 1

* Conectado a: **NAT**
  👉 (para tener internet)

---

## 🔹 Adaptador 2

* ✔ Habilitar
* Conectado a: **Red interna**
* Nombre: `main` ⚠️ (MUY IMPORTANTE)

👉 Este nombre debe ser EXACTAMENTE igual en todas las máquinas

---

# 🥉 3. ARRANCAR LA MÁQUINA

Iniciar `frontend1` desde VirtualBox

---

# 🧪 4. COMPROBAR INTERFACES

En la terminal:

```bash
ip a
```

👉 Deben aparecer:

* `enp0s3` (NAT)
* `enp0s8` (red interna)

---

# ✍️ 5. CONFIGURAR IP FIJA

Editar archivo de red:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

---

## 🔥 CONFIGURACIÓN COMPLETA

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: yes
      

    enp0s8:
      dhcp4: no
      addresses:
        - 10.0.0.11/24
      routes:
        - to: 10.10.10.0/24
          via: 10.0.0.20
```

---

# 💾 6. GUARDAR Y SALIR

En nano:

* `CTRL + O` → Enter
* `CTRL + X`

---

# ▶️ 7. APLICAR CONFIGURACIÓN

```bash
sudo netplan apply
```

---

# ✅ 8. COMPROBAR RESULTADO

```bash
ip a
```

👉 Debe aparecer:

* `192.168.100.10` → red NAT (internet)
* `10.0.0.11` → red interna (comunicación entre máquinas)

---

# 🎯 RESULTADO FINAL

La máquina `frontend1` queda:

✔ Con internet
✔ Con IP fija
✔ Conectada a red interna (`main`)
✔ Preparada para comunicarse con otras VMs
✔ Lista para arquitectura distribuida

---

# ⚠️ ERRORES COMUNES

❌ Usar nombres distintos en la red interna (`main` debe ser igual en todas)
❌ Fallos de indentación en YAML
❌ Escribir mal `/24`
❌ No ejecutar `netplan apply`

---

# 🚀 SIGUIENTE PASO

Crear más máquinas:

* frontend2
* backend1
* backend2
* balanceador
* monitor

👉 Todas clonadas desde la misma base

