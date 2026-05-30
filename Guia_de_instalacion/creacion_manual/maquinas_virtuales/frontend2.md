## 1 Tener los archivos
Igual en la carpeta donde esteis guardando todo teneis que descargaros los archivis
   1) crear_frontend2.sh
   2) configurar_frontend.sh

## 2 Crear frontend

Tenemos que hacer estos pasos
Darle permisos:
```bash
chmod +x crear_frontend2.sh
```

Ejecuta con el usuario de la VM base:
```bash
./crear_frontend2.sh <USUARIO_VM>
```
En tu caso sería:

./crear_frontend2.sh alejandroro

## 3 Configurar las redes

Desde el PC anfitrión:
```bash
scp -P 2211 configurar_frontend.sh <USUARIO_VM>@127.0.0.1:~/
``` 
En tu caso:

scp -P 2211 configurar_frontend.sh alejandroro@127.0.0.1:~/

## 4 Entrar

Desde el PC anfitrión:
```bash
ssh -p 2211 <USUARIO_VM>@127.0.0.1
``` 
En tu caso:

ssh -p 2211 alejandroro@127.0.0.1

## 5 Ejecutar la configuracion de frontend2

Dentro de la VM:
```bash
chmod +x configurar_frontend.sh
``` 
Comprueba que el gateway es el correcto:
```bash
grep GATEWAY configurar_frontend.sh
``` 
Debe salir:

GATEWAY="${3:-10.0.0.100}"

Ahora ejecuta:
```bash
sudo ./configurar_frontend.sh frontend2 10.0.0.11
```

## 6 Comprobar resultado

Dentro de frontend2:
```bash
ip a
ip route
hostname
cat /etc/netplan/00-installer-config.yaml
``` 
Debe aparecer:

enp0s3 -> NAT, IP 10.0.2.X
enp0s8 -> 10.0.0.11/24

En rutas:

10.10.10.0/24 via 10.0.0.100 dev enp0s8

Hostname:

frontend2

Y el netplan debe quedar así:
```bash
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: true

    enp0s8:
      dhcp4: false
      addresses:
        - 10.0.0.11/24
      routes:
        - to: 10.10.10.0/24
          via: 10.0.0.100
          on-link: true
```
## 7 Quitar puerto SSH temporal al final

Cuando frontend2 ya esté configurado, desde el PC anfitrión puedes quitar la regla temporal:

VBoxManage modifyvm frontend2 --natpf1 delete "ssh-frontend2"

Comprobar:

VBoxManage showvminfo frontend2 | grep -i "ssh-frontend2"

Si no sale nada, está quitado.
