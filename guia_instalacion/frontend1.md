# Instalación y configuración del frontend1

## 1. Clonar máquina base

Desde VirtualBox:

- Click derecho en `base-ubuntu` → Clonar
- Nombre: `backend1`
- Tipo: **Clon completo**
- Reinitializar MAC address

## 2. Configuración de red (VirtualBox)

Ir a configuración y luego a red

### Adaptador 1

- Conectado a: **NAT**

### Adaptador 2

- Tipo: **Red interna**
- Nombre: **main**

## 3. ARRANCAR LA MÁQUINA Y COMPROBAMOS INTEERFACES

Iniciamos `frontend1` desde VirtualBox. En la terminal ponemos:

```bash
ip a
```

 Deben aparecer:

* `enp0s3` (NAT)
* `enp0s8` (main)

## 4. CONFIGURAR IP FIJA

Editamos el archivo de red:
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
        - 10.0.0.10/24
      routes:
        - to: 10.10.10.0/24
          via: 10.0.0.20
```


## 4. APLICAR CONFIGURACIÓN

```bash
sudo netplan apply
```


## 5. COMPROBAR RESULTADO

```bash
ip a
```

Debe aparecer:

* `192.168.100.10` → red NAT (internet)
* `10.0.0.10` → red main




## 6. SIGUIENTE PASO

Crear las máquinas:

* frontend2
* backend1
* backend2
* balanceador
* jumpstart


