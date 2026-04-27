# Instalación y configuración del frontend2

## 1. Clonar máquina base

Desde VirtualBox:

- Click derecho en `base-ubuntu` → Clonar
- Nombre: `frontend2`
- Tipo: **Clon completo**
- Reinitializar MAC address

## 2. Configuración de red (VirtualBox)

Ir a configuración y luego a red

### Adaptador 1

- Conectado a: **NAT**

### Adaptador 2

- Tipo: **Red interna**
- Nombre: **main**

## 3. ARRANCAR LA MÁQUINA

Iniciar `frontend2` desde VirtualBox

---

## 4. COMPROBAR INTERFACES

En la terminal:

```bash
ip a
```
 
Deben aparecer:

* `enp0s3` (NAT)
* `enp0s8` (red interna)


## 5. CONFIGURAR IP FIJA

Editar archivo de red:

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
      dhcp4: no
      addresses:
        - 10.0.0.11/24
      routes:
        - to: 10.10.10.0/24
          via: 10.0.0.20
```



## 7. APLICAR CONFIGURACIÓN

```bash
sudo netplan apply
```


## 8. COMPROBAR RESULTADO

```bash
ip a
```

Debe aparecer:

* `192.168.100.10` → red NAT (internet)
* `10.0.0.11` → red interna (comunicación entre máquinas)



## 9. SIGUIENTE PASO

Crear más máquinas:

* frontend2
* backend1
* backend2
* balanceador
* jumpstart

