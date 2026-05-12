# Cluster de Base de Datos en UTM

Esta guía es la versión UTM de `guia_instalacion/VirtualBox/instalacion_baseDatos.md`. El despliegue de MariaDB Galera se hace desde `jumpstart` usando Ansible contra `backend1` y `backend2`.

## 1. Requisitos previos

Antes de empezar deben estar creadas y configuradas estas máquinas:

- `jumpstart`
- `backend1`
- `backend2`

Plan de IPs en UTM:

```text
jumpstart main     -> 192.168.50.10
jumpstart internal -> 10.10.10.1
backend1           -> 10.10.10.10
backend2           -> 10.10.10.11
```

`jumpstart` debe tener Internet por la interfaz de red compartida de UTM. Los backends deben responder desde `jumpstart` por la red `internal`.

## 2. Entrar en jumpstart

Trabajar desde la máquina `jumpstart`, no desde `base-ubuntu`.

Comprobar:

```bash
hostname
ip a
ip route
```

Debe aparecer:

- `192.168.50.10/24` en la interfaz `main`
- `10.10.10.1/24` en la interfaz `internal`
- una ruta `default` por la interfaz de red compartida

## 3. Comprobar conectividad

Desde `jumpstart`:

```bash
ping -c 4 8.8.8.8
ping -c 4 google.com
ping -c 4 10.10.10.10
ping -c 4 10.10.10.11
```

También comprobar SSH:

```bash
ssh carlotamo@10.10.10.10
exit
ssh carlotamo@10.10.10.11
exit
```

Cambia `carlotamo` por tu usuario real si es distinto.

## 4. Copiar los playbooks si vienen del servidor

Si los ficheros están en `tbworkers4`, copiarlos desde `jumpstart`.

El comando debe llevar un destino al final. El punto final significa "copiar aquí":

```bash
scp -r 'carlotamo@tbworkers4.esi.uclm.es:~/*' .
```

Si solo quieres copiar los ficheros necesarios:

```bash
scp carlotamo@tbworkers4.esi.uclm.es:~/preparar_jumpstart.yml .
scp carlotamo@tbworkers4.esi.uclm.es:~/backend.yml .
scp carlotamo@tbworkers4.esi.uclm.es:~/hosts.ini .
```

Comprobar:

```bash
ls
```

Debes tener, como mínimo:

```text
preparar_jumpstart.yml
backend.yml
hosts.ini
```

Si estás usando el repositorio local de PcCarlota, los ficheros están en:

```text
automatizacion/PcCarlota/hosts.ini
automatizacion/PcCarlota/playbooks/preparar_jumpstart.yml
automatizacion/PcCarlota/playbooks/backend.yml
```

## 5. Instalar Ansible en jumpstart

En `jumpstart`:

```bash
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible sshpass apt-rdepends dpkg-dev -y
```

Comprobar:

```bash
ansible --version
```

Si ya aparece una versión de Ansible, puedes seguir con el siguiente paso.

## 6. Preparar inventario

Si usas los ficheros copiados en el home de `jumpstart`, editar:

```bash
nano hosts.ini
```

Contenido recomendado:

```ini
[backends]
backend1 ansible_host=10.10.10.10
backend2 ansible_host=10.10.10.11

[backend]
backend1 ansible_host=10.10.10.10
backend2 ansible_host=10.10.10.11

[all:vars]
ansible_user=carlotamo
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
```

Cambia `ansible_user` por tu usuario real.

Si usas el repositorio:

```bash
nano automatizacion/PcCarlota/hosts.ini
```

## 7. Probar Ansible contra los backends

Con claves SSH:

```bash
ansible -i hosts.ini backends -m ping
```

Si estás usando el repositorio:

```bash
ansible -i automatizacion/PcCarlota/hosts.ini backends -m ping
```

Si no tienes claves SSH todavía, usa `-k` para que pida contraseña:

```bash
ansible -i hosts.ini backends -m ping -k
```

Resultado esperado:

```text
backend1 | SUCCESS
backend2 | SUCCESS
```

## 8. Opcional: configurar claves SSH

Desde `jumpstart`:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
ssh-copy-id carlotamo@10.10.10.10
ssh-copy-id carlotamo@10.10.10.11
```

Vuelve a probar:

```bash
ansible -i hosts.ini backends -m ping
```

## 9. Preparar paquetes offline

Si tienes los playbooks en el home de `jumpstart`:

```bash
ansible-playbook preparar_jumpstart.yml -K
```

Si usas el repositorio:

```bash
ansible-playbook automatizacion/PcCarlota/playbooks/preparar_jumpstart.yml -K
```

La opción `-K` pide la contraseña de sudo.

## 10. Instalar y configurar Galera

Si tienes los playbooks en el home de `jumpstart`:

```bash
ansible-playbook -i hosts.ini backend.yml -K
```

Si no tienes claves SSH:

```bash
ansible-playbook -i hosts.ini backend.yml -k -K
```

Si usas el repositorio:

```bash
ansible-playbook -i automatizacion/PcCarlota/hosts.ini automatizacion/PcCarlota/playbooks/backend.yml -K
```

Con contraseña SSH:

```bash
ansible-playbook -i automatizacion/PcCarlota/hosts.ini automatizacion/PcCarlota/playbooks/backend.yml -k -K
```

## 11. Verificar el cluster

Entrar en `backend1` o `backend2`:

```bash
ssh carlotamo@10.10.10.10
```

Ejecutar:

```bash
sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
```

Resultado esperado:

```text
wsrep_cluster_size    2
```

Salir:

```bash
exit
```

## 12. Errores frecuentes

Si `scp` muestra `usage`, falta el destino final. Usa:

```bash
scp -r 'carlotamo@tbworkers4.esi.uclm.es:~/*' .
```

Si `add-apt-repository` no existe, instala primero:

```bash
sudo apt install software-properties-common -y
```

Si sale `add-apt-respository: command not found`, el comando está mal escrito. Es `repository`, no `respository`.

Si Ansible no conecta con los backends:

```bash
ping -c 4 10.10.10.10
ping -c 4 10.10.10.11
ssh carlotamo@10.10.10.10
ssh carlotamo@10.10.10.11
```

Primero debe funcionar red y SSH; después Ansible.
