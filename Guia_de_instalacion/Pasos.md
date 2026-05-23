

## 1. Archivos necesarios

crear_todas_las_vm.sh
fase2_configurar_redes_remotas.sh
fase3_preparar_jumpstart.sh
fase4_desplegar_roles.sh

crear_jumpstart.sh
crear_balanceador.sh
crear_frontend1.sh
crear_frontend2.sh
crear_backend1.sh
crear_backend2.sh
crear_router_linux.sh

configurar_jumpstart.sh
configurar_balanceador.sh
configurar_frontend.sh
configurar_backend_red.sh
configurar_router_linux.sh

configurar_backend1_local.sh
configurar_backend2_local.sh

backend.yml
frontend_wordpress.yml
zabbix_server_backend1.yml
zabbix_agents.yml
preparar_jumpstart.yml
configurar_apt_proxy_backends.yml
limpiar_bloqueos_apt.yml
hosts.ini

preparar_ansible.sh
desplegar_galera.sh
probar_balanceador.sh
comprobar_despliegue_final.sh
reset_fase4.sh


En la carpeta que los tengais darle los permisos

sudo chown -R "$USER:$USER" .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod +x *.sh


## 2. Creacion de las VM

```bash
./crear_todas_las_vm.sh <USUARIO_VM>
```

Lo que hace este script:
Este script crea:

jumpstart
balanceador
frontend1
frontend2
backend1
backend2
Router-Linux

Memoria RAM configurada:

jumpstart      2048 MB
balanceador    1024 MB
frontend1      1024 MB
frontend2      1024 MB
backend1       1024 MB
backend2       1024 MB
Router-Linux   1024 MB

Importante: hay que dejar que el script termine completamente antes de continuar.


## 3. Configuracion de las VM

Cuando las máquinas ya estén creadas y arrancadas, ejecutar desde el PC anfitrión:
```bash
./fase2_configurar_redes_remotas.sh <USUARIO_VM>
```

## 4. Configurar backend1 y backend2

Los backends no tienen NAT, por lo que se configuran desde la consola gráfica de VirtualBox.

Primero, en VirtualBox, añadir una carpeta compartida a backend1 y backend2:

Nombre: CompartidaVM
Ruta: ~/Escritorio/TRABAJO_GAR
Acceso completo
Permanente

Backend1

Dentro de la terminal de backend1:(es decir entrando a virtualbox de backend1)
```bash
sudo mkdir -p /mnt/compartida
sudo mount -t vboxsf CompartidaVM /mnt/compartida
bash /mnt/compartida/configurar_backend1_local.sh
``

Dentro de la terminal de backend2:(es decir entrando a virtualbox de backend2)
```bash
sudo mkdir -p /mnt/compartida
sudo mount -t vboxsf CompartidaVM /mnt/compartida
bash /mnt/compartida/configurar_backend2_local.sh
``` 

## 5. Preparar jumpstart

Desde el PC anfitrión:
```bash
./fase3_preparar_jumpstart.sh <USUARIO_VM>
```

Este script:

- Copia scripts y playbooks a jumpstart
- Configura jumpstart
- Activa ip_forward
- Instala Ansible
- Configura Keepalived MASTER
- Genera claves SSH
- Copia claves SSH a las VMs
- Prepara hosts.ini

## 6. Desplegar Galera, WordPress y Zabbix

Desde el PC anfitrión:
```bash
ssh -p 2225 <USUARIO_VM>@127.0.0.1
``` 
Dentro de jumpstart:
```bash
./fase4_desplegar_roles.sh <USUARIO_VM>
```

## 7. Comprobación automática final

Dentro de jumpstart:
```bash
./comprobar_despliegue_final.sh <USUARIO_VM>
```  
