En esta fase no se instala NGINX todavía. Esa parte se hará después desde jumpstart, porque los backends no deben depender de NAT ni tener salida directa a Internet.

## 1 Archivos necesarios

crear_backend2.sh
configurar_backend_red.sh

## 2 Ejecutar la creacion de la vm

Ejecutar desde el PC anfitrión:
```bash
chmod +x crear_backend2.sh
./crear_backend2.sh
```
## 3 Configuración de red
Pasar el script a backend2

Como backend2 no tiene NAT, se pasa con carpeta compartida de VirtualBox.

En la ventana de backend2:

Dispositivos → Carpetas compartidas → Configuración de carpetas compartidas

Añadir:

Nombre: CompartidaVM
Ruta: carpeta del PC donde está configurar_backend_red.sh
Acceso: Completo
Permanente: sí

(os paso un video)

Dentro de backend2:
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

Dentro de backend2:
```bash
sudo ./configurar_backend_red.sh backend2 10.10.10.21
```

## 5 Comprobar
Ejecutar

```bash
ip a
ip route
hostname
cat /etc/netplan/00-installer-config.yaml
```
Debe de aparecer

network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 10.10.10.21/24
      routes:
        - to: 10.0.0.0/24
          via: 10.10.10.100
          on-link: true


