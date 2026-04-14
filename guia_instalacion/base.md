# 🚀 GUÍA COMPLETA – CREACIÓN DE MÁQUINA BASE (Ubuntu Server)

## 🧠 OBJETIVO

Crear una máquina base en VirtualBox que servirá como plantilla para clonar el resto de máquinas (frontend, backend, etc.).

---

# 🥇 1. CREAR MÁQUINA VIRTUAL

En VirtualBox:

1. Click en **Nueva**

### 🔹 Configuración:

* Nombre: `base-ubuntu`
* Tipo: Linux
* Versión: Ubuntu (64-bit)

---

# 🥈 2. RECURSOS

* RAM: 2 GB (2048 MB)
* CPU: 2 (opcional pero recomendado)

---

# 🥉 3. DISCO DURO

* Tipo: VDI
* Reserva: Dinámica
* Tamaño: 20 GB

---

# 🧪 4. CARGAR ISO

1. Configuración → **Almacenamiento**
2. Añadir ISO de Ubuntu Server:
   👉 `ubuntu-20.04-live-server-amd64.iso`

---

# 🟢 5. ARRANCAR LA MÁQUINA

👉 Iniciar la VM

---

# ⚙️ 6. INSTALACIÓN DE UBUNTU

Seguir el instalador:

### 🔹 Idioma:

* English (o el que prefieras)

### 🔹 Teclado:

* Spanish

---

## 🌐 RED

👉 Automática (DHCP)

---

## 💾 DISCO

👉 Usar todo el disco (instalación guiada)

---

## 👤 USUARIO

Ejemplo:

* Nombre: Alejandro
* Usuario: `alejandroro`
* Contraseña: (la que elijas)

---

## 🔐 SSH (MUY IMPORTANTE)

👉 Activar:

✔ **Install OpenSSH server**

👉 Permitir contraseña ✔

---

## 📦 Snaps

👉 NO seleccionar nada

---

# ⏳ 7. FINALIZAR INSTALACIÓN

👉 Esperar a que termine
👉 Reiniciar cuando lo pida

---

# ⚠️ IMPORTANTE

Cuando aparezca:

👉 “Remove installation medium”

En VirtualBox:

* Dispositivos → Unidades ópticas
* Quitar ISO

👉 Luego Enter

---

# 🖥️ 8. INICIAR SESIÓN

Entrar con:

```bash
usuario: alejandroro
contraseña: (la elegida)
```

---

# 🔄 9. ACTUALIZAR SISTEMA

```bash
sudo apt update && sudo apt upgrade -y
```

---

# 🔐 10. COMPROBAR SSH

```bash
sudo systemctl status ssh
```

👉 Debe aparecer:

```bash
active (running)
```

---

# 🌐 11. COMPROBAR IP

```bash
hostname -I
```

👉 Ejemplo:

```bash
10.0.2.15
```

---

# 🔧 12. CONFIGURAR PORT FORWARDING (VirtualBox)

Apagar la VM:

```bash
sudo poweroff
```

---

## En VirtualBox:

Configuración → Red → NAT → Avanzado → Reenvío de puertos

---

## Añadir regla:

* Nombre: ssh
* Protocolo: TCP
* Puerto anfitrión: 2222
* Puerto invitado: 22

---

# 🚀 13. CONECTARSE POR SSH

Desde el PC:

```bash
ssh alejandroro@localhost -p 2222
```

---

# 🎯 RESULTADO FINAL

La máquina base queda:

✔ Ubuntu instalado
✔ SSH activo
✔ Acceso remoto configurado
✔ Lista para clonar

---

# 🚀 SIGUIENTE PASO

👉 Clonar esta máquina para crear:

* frontend1
* frontend2
* backend1
* backend2
* balanceador
* monitor

---
