
La máquina Router-Linux sirve como router redundante entre las redes main e internal.

Su función es que, si jumpstart se cae, la comunicación entre ambas redes siga funcionando mediante keepalived.

La arquitectura queda así:

Jumpstart:
- IP main: 10.0.0.20
- IP internal: 10.10.10.10
- VIP main: 10.0.0.100
- VIP internal: 10.10.10.100
- Rol keepalived: MASTER
- Prioridad: 100

Router-Linux:
- IP main: 10.0.0.254
- IP internal: 10.10.10.254
- VIP main: 10.0.0.100
- VIP internal: 10.10.10.100
- Rol keepalived: BACKUP
- Prioridad: 50

Si jumpstart está activo, las VIPs están en jumpstart.

Si jumpstart se apaga, Router-Linux toma automáticamente las VIPs.


## 1. Archivos necesarios

crear_router_linux.sh
configurar_router_linux.sh


## 2. Ejecutar el script de creación

Desde el host:
```bash
chmod +x crear_router_linux.sh
./crear_router_linux.sh usuario_vm
``` 
Ejemplo:

./crear_router_linux.sh alejandroro

El script hará lo siguiente:

1. Comprueba si existe Router-Linux.
2. Si no existe, clona base-ubuntu.
3. Configura NAT, main e internal.
4. Regenera las MACs.
5. Crea una redirección SSH temporal.
6. Arranca la VM.
5. Script de configuración interna

## 3. Copiar el script a Router-Linux

Desde el host, primero comprobamos que se puede entrar:
```bash
ssh -p 2227 usuario_vm@127.0.0.1
``` 
Ejemplo:

ssh -p 2227 alejandroro@127.0.0.1

Salimos:
```bash
exit
```
Ahora copiamos el script desde el host:
```bash
scp -P 2227 configurar_router_linux.sh usuario_vm@127.0.0.1:~/
``` 
Ejemplo:

scp -P 2227 configurar_router_linux.sh alejandroro@127.0.0.1:~/

Importante: el scp se ejecuta desde el host, no desde dentro de la VM.

## 4. Ejecutar configuración dentro de Router-Linux

Entramos otra vez:
```bash
ssh -p 2227 usuario_vm@127.0.0.1
``` 
Ejemplo:

ssh -p 2227 alejandroro@127.0.0.1

Damos permisos:
```bash
chmod +x configurar_router_linux.sh
``` 
Ejecutamos:
```bash
sudo ./configurar_router_linux.sh router-linux
``` 
No hace falta pasarle las IPs al comando porque ya están dentro del script:

MAIN_IP="10.0.0.254"
INTERNAL_IP="10.10.10.254"
VIP_MAIN="10.0.0.100"
VIP_INTERNAL="10.10.10.100"

El parámetro router-linux solo cambia el hostname.

## 5. Comprobaciones básicas

Dentro de Router-Linux:
```bash
hostname
```
Debe devolver:

router-linux

Comprobar interfaces:
```bash
ip a
``` 
Debe aparecer:

enp0s3 → IP por NAT, normalmente 10.0.2.15
enp0s8 → 10.0.0.254/24
enp0s9 → 10.10.10.254/24

Comprobar rutas:
```bash
ip route
``` 
Debe aparecer algo parecido a:

default via 10.0.2.2 dev enp0s3
10.0.0.0/24 dev enp0s8
10.10.10.0/24 dev enp0s9

Comprobar forwarding:
```bash
cat /proc/sys/net/ipv4/ip_forward
``` 
Debe devolver:

1

Comprobar keepalived:
```bash
sudo systemctl status keepalived
``` 
Debe aparecer:

Active: active (running)

Y también algo como:

Entering BACKUP STATE

Eso significa que Router-Linux está esperando como backup.

## 6. Comprobar las VIPs

Con jumpstart encendido, las VIPs deben estar en jumpstart, no en Router-Linux.

En Jumpstart:
```bash
ip a | grep 10.0.0.100
ip a | grep 10.10.10.100
``` 
Debe salir:

10.0.0.100
10.10.10.100

En Router-Linux:
```bash
ip a | grep 10.0.0.100
ip a | grep 10.10.10.100
``` 
Normalmente no debe salir nada.

Eso significa:

Jumpstart = MASTER
Router-Linux = BACKUP


## 7. Prueba de redundancia

Para probar que Router-Linux toma el relevo, apagamos Jumpstart.

Desde Jumpstart:
```bash
sudo poweroff
``` 
O desde VirtualBox, apagar la máquina jumpstart.

Esperamos unos segundos y en Router-Linux ejecutamos:
```bash
ip a | grep 10.0.0.100
ip a | grep 10.10.10.100
``` 
Ahora deben aparecer:

inet 10.0.0.100/32 scope global enp0s8
inet 10.10.10.100/32 scope global enp0s9

Eso significa que Router-Linux ha pasado a MASTER y ha asumido las IPs virtuales.

También se puede comprobar con:

sudo systemctl status keepalived

O con logs:

sudo journalctl -u keepalived -n 30 --no-pager


## 8. Comprobar que la red sigue funcionando

Con Jumpstart apagado y Router-Linux usando las VIPs, desde el balanceador podemos probar:
```bash
ping 10.10.10.20
ping 10.10.10.21
``` 
También:
```bash
curl http://localhost
curl http://localhost
``` 
Debe seguir alternando entre:

SOY BACKEND1
SOY BACKEND2

Desde el host también se puede probar la web:
```bash
curl http://127.0.0.1:8080
```


## 9. Volver a la situación normal

Encendemos otra vez Jumpstart desde VirtualBox.

Cuando arranque, comprobamos en Jumpstart:
```bash
ip a | grep 10.0.0.100
ip a | grep 10.10.10.100
``` 
Las VIPs deberían volver a Jumpstart, porque tiene prioridad más alta.

En Router-Linux:
```bash
ip a | grep 10.0.0.100
ip a | grep 10.10.10.100
``` 
Ya no deberían aparecer.

La explicación es:

Jumpstart tiene prioridad 100.
Router-Linux tiene prioridad 50.
Por eso, cuando Jumpstart vuelve, recupera el rol de MASTER.

## 10. Acceso posterior a Router-Linux

Durante la instalación usamos SSH temporal por NAT:
```bash
ssh -p 2227 usuario_vm@127.0.0.1
``` 
Pero una vez configurada la infraestructura, lo recomendable es administrar Router-Linux desde Jumpstart:
```bash
ssh usuario_vm@10.0.0.254
``` 
Ejemplo:

ssh alejandroro@10.0.0.254

Si queremos quitar la redirección SSH temporal desde el host:

VBoxManage modifyvm "Router-Linux" --natpf1 delete "ssh-router-linux"

Después de quitar esa regla, ya no se entrará desde el host por 2227; se entrará desde Jumpstart.
