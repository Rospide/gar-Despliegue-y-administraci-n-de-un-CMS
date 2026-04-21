Guía de instalación y configuración del nodo jumpstart con SSH y Ansible
1. Objetivo

Esta guía explica cómo crear y configurar el nodo jumpstart, que será la máquina de control desde la que se administrarán el resto de nodos mediante SSH sin contraseña y Ansible.

El nodo jumpstart debe poder conectarse a:

la red main
la red internal
Internet mediante NAT
2. Máquinas del sistema
Nodos de la práctica
frontend1 → 10.0.0.10
frontend2 → 10.0.0.11
backend1 → 10.10.10.20
backend2 → 10.10.10.21
balanceador → 10.10.10.30
Nodo de control
jumpstart
red main → 10.0.0.20
red internal → 10.10.10.10
NAT → IP automática por DHCP
Usuario utilizado en todas las VMs
alejandroro
3. Crear la máquina virtual jumpstart
En VirtualBox

Crear una nueva máquina Ubuntu Server.

Adaptadores de red

Configurar 3 adaptadores:

Adaptador 1
Tipo: NAT
Adaptador 2
Tipo: Red interna
Nombre: main
Adaptador 3
Tipo: Red interna
Nombre: internal

Es importante que la máquina esté conectada a las dos redes del proyecto y además tenga salida a Internet para instalar paquetes.

4. Comprobar las interfaces de red

Una vez arrancada la máquina, ejecutar:

ip a

Normalmente aparecerán interfaces como:

enp0s3
enp0s8
enp0s9


En nuestro caso:

enp0s3 → NAT
enp0s8 → main
enp0s9 → internal
5. Configurar red en jumpstart

Editar el fichero de netplan:

sudo nano /etc/netplan/00-installer-config.yaml

Poner esta configuración:

network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: yes

    enp0s8:
      dhcp4: no
      addresses:
        - 10.0.0.20/24

    enp0s9:
      dhcp4: no
      addresses:
        - 10.10.10.10/24

Guardar y aplicar:

sudo netplan apply

Comprobar:

ip a
ip route

Debe aparecer:

una IP 10.0.2.X en la interfaz NAT
10.0.0.20 en main
10.10.10.10 en internal
6. Comprobar conectividad
Probar Internet
ping -c 4 8.8.8.8
Probar máquinas de la red main
ping -c 4 10.0.0.10
ping -c 4 10.0.0.11
Probar máquinas de la red internal
ping -c 4 10.10.10.20
ping -c 4 10.10.10.21
ping -c 4 10.10.10.30

Si alguna no responde, revisar su configuración de red en VirtualBox y su netplan.

8. Generar clave SSH en jumpstart

Desde jumpstart, generar clave SSH:

ssh-keygen -t ed25519

Cuando pregunte:

Enter file in which to save the key

pulsar Enter.

Cuando pregunte por passphrase, pulsar Enter dos veces para dejarla vacía.

Esto creará:

~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
9. Copiar la clave SSH al resto de máquinas

Desde jumpstart, ejecutar:

ssh-copy-id alejandroro@10.0.0.10
ssh-copy-id alejandroro@10.0.0.11
ssh-copy-id alejandroro@10.10.10.20
ssh-copy-id alejandroro@10.10.10.21
ssh-copy-id alejandroro@10.10.10.30

La primera vez aparecerá:

Are you sure you want to continue connecting (yes/no/[fingerprint])?

Escribir:

yes

Después introducir la contraseña del usuario de esa máquina.

Si todo va bien, aparecerá:

Number of key(s) added: 1
10. Probar SSH sin contraseña

Desde jumpstart, comprobar que ya entra sin pedir contraseña:

ssh alejandroro@10.0.0.10
ssh alejandroro@10.0.0.11
ssh alejandroro@10.10.10.20
ssh alejandroro@10.10.10.21
ssh alejandroro@10.10.10.30

Para salir de cada sesión:

exit

Toda la administración debe hacerse siempre desde jumpstart.

11. Instalar Ansible

En jumpstart, instalar Ansible:

sudo apt update
sudo apt install ansible -y

Comprobar versión:

ansible --version
12. Crear inventario hosts.ini

Crear el fichero:

nano hosts.ini

Contenido:

[frontends]
10.0.0.10
10.0.0.11

[backends]
10.10.10.20
10.10.10.21

[balanceador]
10.10.10.30

[all:vars]
ansible_user=alejandroro
ansible_ssh_private_key_file=~/.ssh/id_ed25519

Guardar con:

Ctrl + O
Enter
Ctrl + X
13. Probar Ansible

Ejecutar:

ansible all -i hosts.ini -m ping

Resultado esperado en todos los nodos:

SUCCESS
"ping": "pong"

Si aparece eso, significa que Ansible funciona correctamente en toda la infraestruct



14. Playbook básico de prueba

Crear un playbook para instalar Apache en los frontends:

nano apache.yml

Contenido:

- hosts: frontends
  become: yes
  tasks:
    - name: Instalar Apache
      apt:
        name: apache2
        state: present
        update_cache: yes

Ejecutar:

ansible-playbook -i hosts.ini apache.yml --ask-become-pass

