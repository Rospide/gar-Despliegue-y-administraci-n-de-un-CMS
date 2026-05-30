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


## 6. Adaptador solo anfitrión para backend1


Desde el PC anfitrión:
```bash
VBoxManage controlvm backend1 poweroff 2>/dev/null || true
VBoxManage modifyvm backend1 --nic2 hostonly
VBoxManage modifyvm backend1 --hostonlyadapter2 vboxnet0
VBoxManage startvm backend1 --type gui
``` 
Luego, cuando ejecutes zabbix_server_backend1.yml, él mismo configurará dentro de backend1:

enp0s8 -> 192.168.56.20/24

Para comprobar desde el PC:

ping -c 3 192.168.56.20

Y Zabbix quedará accesible en:

http://192.168.56.20/zabbix

## 7. Adaptador solo anfitrión para Zabbix

Backend1 tiene un segundo adaptador:

Adaptador 2: Solo anfitrión vboxnet0
IP futura: 192.168.56.20/24

Esta IP no se configura ahora manualmente.

Se configurará automáticamente más adelante desde jumpstart con:

zabbix_server_backend1.yml

Ese playbook creará:

/etc/netplan/02-hostonly.yaml

con la IP:

192.168.56.20/24
## 8. Comprobación después de instalar Zabbix

Cuando se ejecute el playbook de Zabbix, comprobar en backend1:

ip -br a
ip route

Debe aparecer:

enp0s3 -> 10.10.10.20/24
enp0s8 -> 192.168.56.20/24

Y en ip route no debe aparecer una ruta default por 192.168.56.X.

Desde el PC anfitrión:

ping -c 3 192.168.56.20

Si responde, la web de Zabbix será accesible desde:

http://192.168.56.20/zabbix
