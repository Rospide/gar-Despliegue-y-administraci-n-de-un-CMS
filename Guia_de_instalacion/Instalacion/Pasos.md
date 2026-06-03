# Guía de despliegue GAR - WordPress, Galera, Balanceador y Zabbix

Esta guía explica cómo desplegar automáticamente la infraestructura del proyecto GAR usando VirtualBox, Ubuntu, Ansible, MariaDB Galera, WordPress, Nginx y Zabbix.

---

## 1. Estructura del proyecto

La carpeta final de scripts debe contener estos archivos:

```bash
01_crear_y_configurar_vms.sh
02_preparar_jumpstart.sh
03_desplegar_todo.sh
04_comprobar_despliegue.sh
reset_fase4.sh
``` 
Estos scripts automatizan:

01_crear_y_configurar_vms.sh
- Crea las máquinas virtuales desde una VM base.
- Configura RAM.
- Configura redes de balanceador, frontend1, frontend2 y router-linux.
- Permite configurar backend1 y backend2 desde VirtualBox.

02_preparar_jumpstart.sh
- Configura jumpstart.
- Crea hosts.ini.
- Prepara claves SSH.
- Instala herramientas necesarias.

03_desplegar_todo.sh
- Despliega MariaDB Galera.
- Despliega WordPress.
- Despliega Zabbix Server.
- Despliega agentes Zabbix.

04_comprobar_despliegue.sh
- Comprueba Galera.
- Comprueba WordPress.
- Comprueba balanceador.
- Comprueba balanceo entre frontend1 y frontend2.

reset_fase4.sh
- Limpia errores parciales de la fase de despliegue.


## 2. Preparar permisos de los scripts

Desde el PC anfitrión, entrar en la carpeta donde están los scripts:

Dar permisos:

```bash
chmod +x *.sh
``` 

## 3. Crear y configurar las máquinas virtuales

Ejecutar desde el PC anfitrión:
```bash
./01_crear_y_configurar_vms.sh <usuario_vm> <nombre_vm_base>
``` 

Este script crea y configura estas VMs:

jumpstart
balanceador
frontend1
frontend2
backend1
backend2
Router-Linux


## 4. Configurar backend1 y backend2 desde VirtualBox

Los backends se configuran desde la consola gráfica de VirtualBox.

Primero hay que añadir una carpeta compartida a backend1 y backend2.

En VirtualBox:


**Configuración → Carpetas compartidas → Añadir carpeta**

Configurar así:

- **Nombre de carpeta:** `CompartidaVM`
- **Ruta de carpeta:** carpeta donde están los scripts
- **Sólo lectura:** desactivado
- **Automontar:** activado



#### Backend1

Entrar en la consola de backend1 y ejecutar:
```bash
sudo mkdir -p /mnt/compartida
sudo mount -t vboxsf CompartidaVM /mnt/compartida
ls /mnt/compartida
bash /mnt/compartida/01_crear_y_configurar_vms.sh --backend1-local
``` 

##### Backend2

Entrar en la consola de backend2 y ejecutar:
```bash
sudo mkdir -p /mnt/compartida
sudo mount -t vboxsf CompartidaVM /mnt/compartida
ls /mnt/compartida
bash /mnt/compartida/01_crear_y_configurar_vms.sh --backend2-local
```


## 5. Preparar jumpstart

Volver al PC anfitrión y ejecutar:

```bash
./02_preparar_jumpstart.sh <usuario_vm>
```

## 6. Desplegar Galera, WordPress y Zabbix
Entra en jumpstart:
```bash
ssh -p 2225 <usuario_vm>@127.0.0.1
``` 
Dentro de jumpstart, ejecutar:
```bash
./03_desplegar_todo.sh <usuario_vm>
```
## 7. Comprobar
Cuando termine el despliegue, ejecutar desde jumpstart:
```bash
./04_comprobar_despliegue.sh <usuario_vm>
```

## 8 Entrar en Zabbix

Desde el navegador del PC anfitrión, acceder a:

`http://192.168.56.20/zabbix`

Credenciales:

**Usuario:** Admin

**Contraseña:** zabbix

## 9 Probar el TrafficMix

Desde el PC anfintrión:

```bash
./generar_trafico_externo.sh
