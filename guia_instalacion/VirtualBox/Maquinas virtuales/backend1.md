En esta fase no se instala NGINX todavía. Esa parte se hará después desde jumpstart, porque los backends no deben depender de NAT ni tener salida directa a Internet. Esto encaja mejor con el diseño del enunciado, donde jumpstart se usa como nodo de aprovisionamiento conectado a ambos segmentos de red.



## 1 Script necesarios

crear_backend1.sh
configurar_backend_red.sh

## 2 Crear la vm

Ejecutar desde el PC anfitrión:
```bash
chmod +x crear_backend1.sh
./crear_backend1.sh
```
## 3 Pasar el scrpit


Como backend1 no tiene NAT, se puede pasar usando carpeta compartida de VirtualBox.

En VirtualBox, para backend1:

Dispositivos → Carpetas compartidas → Configuración de carpetas compartidas

Añadir:

Nombre: CompartidaVM
Ruta: carpeta del PC donde está configurar_backend_red.sh
Acceso: Completo
Permanente: sí

Dentro de backend1:
```bash
sudo mkdir -p /mnt/compartida
sudo mount -t vboxsf CompartidaVM /mnt/compartida
```
Comprobar:
```bash
ls -l /mnt/compartida
``` 
Debe aparecer:

configurar_backend_red.sh

Copiarlo a la home:
```bash
cp /mnt/compartida/configurar_backend_red.sh ~/
chmod +x configurar_backend_red.sh
```

## 4 Ejecutar la configuración de red

Dentro de backend1:
```bash
sudo ./configurar_backend_red.sh backend1 10.10.10.20
```

## 5 omprobar resultado

Dentro de backend1:
```bash
ip a
ip route
hostname
cat /etc/netplan/00-installer-config.yaml
``` 
Debe aparecer:

IP: 10.10.10.20/24
Ruta: 10.0.0.0/24 via 10.10.10.100
Hostname: backend1

El fichero final debe quedar así:

network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 10.10.10.20/24
      routes:
        - to: 10.0.0.0/24
          via: 10.10.10.100
          on-link: true
Estado actual de backend1

Según tu captura, backend1 ya está correctamente configurado:

backend1
10.10.10.20/24
10.0.0.0/24 via 10.10.10.100

Ahora seguimos con backend2, que será igual pero cambiando:

backend1 → backend2
10.10.10.20 → 10.10.10.21

El mismo script configurar_backend_red.sh sirve para los dos.
