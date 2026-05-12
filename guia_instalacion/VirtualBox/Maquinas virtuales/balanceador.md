## 1. Archivos necesarios

crear_balanceador.sh
configurar_balanceador.sh

## 2. Creación vm

Desde el host:
```bash
chmod +x crear_balanceador.sh
./crear_balanceador.sh usuario_vm
```  
Ejemplo:

./crear_balanceador.sh alejandroro

El script clonará base-ubuntu como balanceador, configurará las redes y arrancará la VM.

## 3. Configuración de las redes

Primero, desde el host, entrar por SSH temporal:
```bash
ssh -p 2226 usuario_vm@127.0.0.1
``` 
Si entra correctamente, salimos:
```bash
exit
``` 
Después copiamos el script desde el host hacia la VM:
```bash
scp -P 2226 configurar_balanceador.sh usuario_vm@127.0.0.1:~/
``` 
Ejemplo:

scp -P 2226 configurar_balanceador.sh alejandroro@127.0.0.1:~/

Importante: este scp se ejecuta desde el host, no desde dentro de la VM.


## 4. Ejecutar la configuración dentro del balanceador

Entramos al balanceador:
```bash  
ssh -p 2226 usuario_vm@127.0.0.1
```  
Damos permisos al script:
```bash
chmod +x configurar_balanceador.sh
``` 
Ejecutamos:
```bash
sudo ./configurar_balanceador.sh balanceador
``` 
No hay que pasarle la IP del balanceador porque la IP ya está definida dentro del script:

MAIN_IP="10.0.0.1"

El parámetro balanceador solo sirve para cambiar el hostname de la máquina.


## 5. Comprobaciones dentro del balanceador

Dentro de la VM:
```bash
hostname
```
Debe devolver:

balanceador

Comprobar interfaces:
```bash
ip a
``` 
Debe aparecer:

enp0s3 → 10.0.2.15 aproximadamente, por NAT
enp0s8 → 10.0.0.1/24

Comprobar rutas:
```bash
ip route
``` 
Debe aparecer una ruta como esta:

10.10.10.0/24 via 10.0.0.100 dev enp0s8

Comprobar Nginx:
```bash
sudo systemctl status nginx
``` 
Comprobar firewall:
```bash
sudo ufw status verbose
``` 
Debe aparecer algo parecido a:

Status: active

Default: deny (incoming), allow (outgoing)

80/tcp     ALLOW IN    Anywhere
22/tcp     ALLOW IN    10.0.0.20

Comprobar balanceo:
```bash
curl http://localhost
curl http://localhost
curl http://localhost
``` 
Debe alternar entre:

SOY BACKEND1

y:

SOY BACKEND2


## 6. Comprobación desde el host

Desde el equipo anfitrión:

curl http://127.0.0.1:8080

También puedes abrir en el navegador:

http://127.0.0.1:8080

Debería mostrar el contenido de los backends.
