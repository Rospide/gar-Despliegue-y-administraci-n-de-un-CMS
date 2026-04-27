# Instalación y configuración del jumpstart

## 1. CLONAR MÁQUINA BASE 

Desde VirtualBox:

- Click derecho en `base-ubuntu` → Clonar
- Nombre: `jumpstart`
- Tipo: **Clon completo**
- Reinitializar MAC address

## 2. CONFIGURACIÓN DE RED (VIRTUALBOX)

Ir a configuración y luego a red


### Adaptador 1

- Conectado a: **NAT**

### Adaptador 2

- Tipo: **Red interna**
- Nombre: **main**

### Adaptador 3

- Tipo: **Red interna**
- Nombre: **internal**


## 3. COMPROBAR LAS INTERFACES DE RED

Una vez arrancada la máquina, ejecutar:

```bash
ip a
```

debe aparecer:

- enp0s3: NAT
- enp0s8: main
- enp0s9: internal

## 4. CONFIGURAR RED 

Editar el fichero de configuración:

```bash
sudo nano /etc/netplan/00-installer-config.yaml
```


Configuración:

```yaml
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
```

## 5. GUARDAR CONFIGURACIÓN
```bash
sudo netplan apply
```

Comprobamos:
```bash
ip a
ip route
```

Debe aparecer:

- una IP 10.0.2.X en la interfaz NAT
- 10.0.0.20 en main
- 10.10.10.10 en internal

## 6. COMPROBAR CONECTIVIDAD
Probamos Internet:
```bash
ping -c 4 8.8.8.8
```

Probar máquinas de la red main:
```bash
ping -c 4 10.0.0.10
```

```bash
ping -c 4 10.0.0.11
```

Probar máquinas de la red internal:
```bash
ping -c 4 10.10.10.20
```

```bash
ping -c 4 10.10.10.21
```

```bash
ping -c 4 10.10.10.30
```

Si alguna no responde, hay que revisar la configuración de red en VirtualBox y su netplan.

## 7. GENERAR CLAVE SSH 

Generaramos la clave SSH con:
```bash
ssh-keygen -t ed25519
```

Cuando pregunte: "Enter file in which to save the key" hay que pulsar Enter.
Cuando pregunte por passphrase, pulsar Enter dos veces para dejarla vacía.
Esto creará:
```bash
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```
## 8. COPIAR LA CLAVE SSH AL RESTO DE MÁQUINAS

Desde jumpstart, ejecutar:
```bash
ssh-copy-id usuario@10.0.0.10
ssh-copy-id usuario@10.0.0.11
ssh-copy-id usuario@10.10.10.20
ssh-copy-id usuario@10.10.10.21
ssh-copy-id usuario@10.10.10.30
```

La primera vez aparecerá: "Are you sure you want to continue connecting (yes/no/[fingerprint])?" hay que contestar "yes" y poner la contraseña de la máquina

Si todo va bien, aparecerá:
```bash
Number of key(s) added: 1
```

## 9. PROBAR SSH SIN CONTRASEÑA

Desde jumpstart, comprobar que ya entra sin pedir contraseña:
```bash
ssh usuario@10.0.0.10
ssh usuario@10.0.0.11
ssh usuario@10.10.10.20
ssh usuario@10.10.10.21
ssh usuario@10.10.10.30
```

Para salir de cada sesión:
```bash
exit
```

## 10. INSTAÑAR ANSIBLE 
```bash
sudo apt update
sudo apt install ansible -y
```

Comprobar versión:
```bash
ansible --version
```
## 11. CREAR INVENTARIO hosts.ini 

Creamos el fichero:
```bash
nano hosts.ini
```

Contenido:
```bash
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
```

lo ejecutamos con el comando:

```bash
ansible all -i hosts.ini -m ping
```

El resultado que se espera en todos los nodos:

```bash
SUCCESS
"ping": "pong"
```

Si aparece eso, significa que Ansible funciona correctamente en toda la infraestructa



## 12. PLAYBOOK BÁSICO DE PRUEBA

Creamos un playbook para instalar Apache en los frontends:

```bash
nano apache.yml
```

Contenido:

```bash
- hosts: frontends
  become: yes
  tasks:
    - name: Instalar Apache
      apt:
        name: apache2
        state: present
        update_cache: yes
```

Ejecutamos con:

```bash
ansible-playbook -i hosts.ini apache.yml --ask-become-pass
```


## 13. ACTIVAR FORWARDING (PUENTE ENTRE FRONTEND Y BACKEND)
Entramos en:  
```bash
sudo nano /etc/sysctl.conf
```

y descomentamos la linea:
```bash
net.ipv4.ip_forward=1
```

Luego, aplicamos los cambios con: 
```bash
sudo netplan apply
```


