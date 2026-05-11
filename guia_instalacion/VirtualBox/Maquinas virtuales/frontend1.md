
GUIA DE INSTALACION DE FRONTEND1

Lo primero que debeis de hacer es cada uno en su PC tener creado una carpeta donde guardar los script en mi caso ~/Documents/GAR

## 1. Archivos necesacios

crear_frontend1.sh -> que se encuentra para descargar en automatizacion/VirtualBpx/creacion_vm

configurar_frontend.sh -> que se encuentra en automatizacion/VirtualBox/scripts

## 2. Proceso de arranque

Desde la terminal de ubuntu donde hallaus guardado los archivos 
Ejecutais:
```bash
chmod +x crear_frontend1.sh
./crear_frontend1.sh alumno
```
## 3. Transferir los paquetes

Entra por SSH y ejecuta el script:
```bash
ssh -p 2210 <alumno>@127.0.0.1
```
En mi caso ssh -p 2210 alejandroro@127.0.0.1

```bash
# Dentro de la VM:
chmod +x configurar_frontend.sh
sudo ./configurar_frontend.sh frontend1 10.0.0.10
exit
```
## 4. Verificación Final

Vuelve a entrar por SSH para refrescar el prompt y verifica:

    IPs: ip a (Debe aparecer 10.0.0.10 en la interfaz secundaria).

    Rutas: ip route (Debe haber una ruta a 10.10.10.0/24 vía 10.0.0.100).

    Hostname: El prompt debe mostrar alumno@frontend1.
