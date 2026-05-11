jumpstart será la máquina encargada de aprovisionar el resto de nodos mediante SSH y Ansible.


## 1 Script necesarios

crear_jumpstart.sh
configurar_jumpstart.sh
preparar_ansible.sh

## 2 Crear vm

Ejecutar desde el PC anfitrión:
```bash
chmod +x crear_jumpstart.sh
./crear_jumpstart.sh <USUARIO_VM>
```
## 3. Copiar el script de configuración a jumpstart

Desde el PC anfitrión:
```bash
scp -P 2225 configurar_jumpstart.sh <USUARIO_VM>@127.0.0.1:~/
``` 
Ejemplo:

scp -P 2225 configurar_jumpstart.sh alumno@127.0.0.1:~/

4. Entrar en jumpstart

Desde el PC anfitrión:
```bash
ssh -p 2225 <USUARIO_VM>@127.0.0.1
```  
Ejemplo:

ssh -p 2225 alumno@127.0.0.1


5. Ejecutar la configuración dentro de jumpstart

Dentro de la VM:
```bash
chmod +x configurar_jumpstart.sh
sudo ./configurar_jumpstart.sh jumpstart
``` 
Cuando pida contraseña, usar la contraseña del usuario de la VM.



## 6. Comprobar configuración de jumpstart

Dentro de jumpstart:
```bash
ip a
ip route
hostname
cat /proc/sys/net/ipv4/ip_forward
systemctl status keepalived
ansible --version
``` 
Debe aparecer:

enp0s3 -> NAT con IP 10.0.2.X
enp0s8 -> 10.0.0.20/24
enp0s8 -> 10.0.0.100/24
enp0s9 -> 10.10.10.10/24
enp0s9 -> 10.10.10.100/24
hostname -> jumpstart
ip_forward -> 1
keepalived -> active running
ansible -> instalado

En systemctl status keepalived puede aparecer primero:

Entering BACKUP STATE

y después:

Entering MASTER STATE

Eso está bien. Lo importante es que el servicio esté:

active (running)

y que las IPs virtuales aparezcan en ip a.



### 7. Probar conectividad desde jumpstart

Con las demás máquinas encendidas:
```bash
ping -c 4 10.0.0.10
ping -c 4 10.0.0.11
ping -c 4 10.10.10.20
ping -c 4 10.10.10.21
``` 
Resultados esperados:

frontend1 -> responde en 10.0.0.10
frontend2 -> responde en 10.0.0.11
backend1 -> responde en 10.10.10.20


## 8 Preparar ansible 

Este script se guarda en el PC anfitrión y después se copia a jumpstart.

Sirve para automatizar:

crear clave SSH si no existe
crear hosts.ini
copiar la clave SSH a los nodos
probar SSH sin contraseña
probar Ansible

Archivo:




## 9. Copiar preparar_ansible.sh a jumpstart

Desde el PC anfitrión:
```bash
scp -P 2225 preparar_ansible.sh <USUARIO_VM>@127.0.0.1:~/
``` 
Ejemplo:

scp -P 2225 preparar_ansible.sh alumno@127.0.0.1:~/



## 10. Ejecutar preparar_ansible.sh dentro de jumpstart

Entrar en jumpstart:
```bash 
ssh -p 2225 <USUARIO_VM>@127.0.0.1
``` 
Dentro de jumpstart:
```bash
chmod +x preparar_ansible.sh
./preparar_ansible.sh <USUARIO_VM>
``` 
Ejemplo:

./preparar_ansible.sh alumno

Durante el proceso, ssh-copy-id pedirá la contraseña del usuario de cada VM.

Si las claves ya estaban copiadas, puede aparecer:

WARNING: All keys were skipped because they already exist on the remote system.

Eso no es un error. Significa que la clave ya estaba instalad


## 11. Resultado esperado de preparar_ansible.sh

Primero debe crear el inventario:

[frontends]
10.0.0.10
10.0.0.11

[backends]
10.10.10.20
10.10.10.21

[all:vars]
ansible_user=<USUARIO_VM>
ansible_ssh_private_key_file=/home/<USUARIO_VM>/.ssh/id_ed25519

Después debe probar SSH y mostrar los hostnames:

frontend1
frontend2
backend1
backend2

Y finalmente debe probar Ansible:

10.0.0.10 | SUCCESS => {
    "ping": "pong"
}

10.0.0.11 | SUCCESS => {
    "ping": "pong"
}

10.10.10.20 | SUCCESS => {
    "ping": "pong"
}

10.10.10.21 | SUCCESS => {
    "ping": "pong"
}

Si aparece SUCCESS en los cuatro nodos, jumpstart ya puede aprovisionar las máquinas con Ansible.


## 12. Salir y volver a entrar para actualizar el prompt

Si después del script sigue saliendo:

usuario@base

hacer:

exit
ssh -p 2225 <USUARIO_VM>@127.0.0.1

Después debería aparecer:

usuario@jumpstart


## 13. Nota sobre la redirección SSH temporal

La redirección:

2225 -> 22

solo se usa para configurar jumpstart desde el PC anfitrión.

Se puede dejar mientras se desarrolla, pero en la infraestructura final se puede eliminar desde el host:

VBoxManage modifyvm jumpstart --natpf1 delete "ssh-jumpstart"

Comprobar que se eliminó:

VBoxManage showvminfo jumpstart | grep -i "ssh-jumpstart"

Si no devuelve nada, ya no existe.

## 14. Estado actual conseguido

Con esta guía, jumpstart queda así:

Hostname: jumpstart
NAT: enp0s3 -> 10.0.2.X
main: enp0s8 -> 10.0.0.20/24
VIP main: enp0s8 -> 10.0.0.100/24
internal: enp0s9 -> 10.10.10.10/24
VIP internal: enp0s9 -> 10.10.10.100/24
forwarding: 1
keepalived: active running
ansible: instalado
hosts.ini: creado
SSH sin contraseña: funcionando
Ansible ping: SUCCESS en frontends y backends

Esto cumple con la idea de que jumpstart sea el nodo de aprovisionamiento de la infraestructura.
