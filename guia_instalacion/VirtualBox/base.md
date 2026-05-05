# GUIA DE INSTALACIÓN: CREACIÓN DE LA INFRAESTRUCTURA BASE 

Vamos a crear una máquina base en VirtualBox que servirá como plantilla para clonar el resto de máquinas (frontends, backends, jumpstart y balenceador).

## 1. CREAR MÁQUINA VIRTUAL

En VirtualBox hacemos click en **Nueva**

### Configuración:

* Nombre: `base-ubuntu`
* Tipo: Linux
* Versión: Ubuntu (64-bit)

## 2. RECURSOS

* RAM: 2 GB (2048 MB)
* CPU: 2 (opcional pero recomendado)

## 3. DISCO DURO

* Tipo: VDI
* Reserva: Dinámica
* Tamaño: 20 GB

## 4. CARGAR ISO

En configuración y luego alamcenamiento, añades la ISO de Ubuntu Server: `ubuntu-20.04-live-server-amd64.iso` y arrancamos la máquina


## 5. INSTALACIÓN DE UBUNTU

Seguimos el instalador:
1. Eliges el idioma y teclado que quieras.
2. La red la cogemos automatica (DHCP)
3. Usar todo el disco (instalación guiada)
5. Creas el usuario con un usuario y contraseña
6. Activas **Install OpenSSH server** y permites la contraseña
7. No seleccionas ningun snaps

Por ultimo, reinicias cuando lo pida



### NOTA 

Cuando aparezca:  “Remove installation medium”

En VirtualBox le das a dispositivos, unidades ópticas, quitas ISO y luego Enter

## 6. INICIAR SESIÓN Y ACTUALIZAR EL SISTEMA

Entramos con el usuario y contraseña elegida anteriormente y actualizamos el sistema:

```bash
sudo apt update && sudo apt upgrade -y
```

## 7. COMPROBAR SSH

```bash
sudo systemctl status ssh
```

debe aparecer:

```bash
active (running)
```

## 8. COMPROBAR IP

Comprobamos la ip con:
```bash
hostname -I
```

## 9. CONFIGURAR PORT FORWARDING (VirtualBox)

Apagamos la maquina virtual:

```bash
sudo poweroff
```

Y en VirtualBox le damos a configuración, red, NAT y en la opción avanzado le damos a reenvío de puertos. Añadimos la regla:
```bash
* Nombre: ssh
* Protocolo: TCP
* Puerto anfitrión: 2222
* Puerto invitado: 22
```

## 10. CONEXIÓN POR SSH

Desde el PC:

```bash
ssh usuario@localhost -p 2222
```



## 11. SIGUIENTE PASO
* frontend1
* frontend2
* backend1
* backend2
* balanceador
* jumpstart


