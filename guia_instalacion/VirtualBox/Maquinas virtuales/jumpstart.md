jumpstart será la máquina encargada de aprovisionar el resto de nodos mediante SSH y Ansible.


## 1 Script necesarios

crear_jumpstart.sh
configurar_jumpstart.sh
preparar_ansible.sh
preparar_jumpstart.yml
backend.yml
desplegar_galera.sh

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
Script completo preparar_ansible.sh

```bash
#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./preparar_ansible.sh <usuario_vm>"
  echo "Ejemplo: ./preparar_ansible.sh alumno"
  exit 1
fi

ANSIBLE_USER="$1"
SSH_KEY="$HOME/.ssh/id_ed25519"
INVENTORY="hosts.ini"

FRONTEND1_IP="10.0.0.10"
FRONTEND2_IP="10.0.0.11"
BACKEND1_IP="10.10.10.20"
BACKEND2_IP="10.10.10.21"

ALL_NODES=(
  "${FRONTEND1_IP}"
  "${FRONTEND2_IP}"
  "${BACKEND1_IP}"
  "${BACKEND2_IP}"
)

echo "[1/5] Comprobando clave SSH..."

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ ! -f "$SSH_KEY" ]]; then
  echo "No existe clave SSH. Generando clave nueva..."
  ssh-keygen -t ed25519 -f "$SSH_KEY" -N ""
else
  echo "La clave SSH ya existe: $SSH_KEY"
fi

echo
echo "[2/5] Creando inventario Ansible: $INVENTORY"

cat > "$INVENTORY" <<EOF
[frontends]
frontend1 ansible_host=${FRONTEND1_IP}
frontend2 ansible_host=${FRONTEND2_IP}

[backends]
backend1 ansible_host=${BACKEND1_IP}
backend2 ansible_host=${BACKEND2_IP}

[all:vars]
ansible_user=${ANSIBLE_USER}
ansible_ssh_private_key_file=/home/${ANSIBLE_USER}/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
EOF

echo "Inventario creado:"
cat "$INVENTORY"

echo
echo "[3/5] Copiando clave SSH a los nodos..."

for NODE in "${ALL_NODES[@]}"; do
  echo
  echo "Copiando clave a ${ANSIBLE_USER}@${NODE}..."

  ssh-keygen -R "$NODE" >/dev/null 2>&1 || true

  ssh-copy-id \
    -i "${SSH_KEY}.pub" \
    -o StrictHostKeyChecking=accept-new \
    "${ANSIBLE_USER}@${NODE}"
done

echo
echo "[4/5] Probando SSH sin contraseña..."

for NODE in "${ALL_NODES[@]}"; do
  echo "Probando SSH con ${NODE}..."
  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    "${ANSIBLE_USER}@${NODE}" \
    "hostname"
done

echo
echo "[5/5] Probando Ansible..."

ansible all -i "$INVENTORY" -m ping

echo
echo "Preparación de Ansible completada correctamente."
```  



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
frontend1 ansible_host=10.0.0.10
frontend2 ansible_host=10.0.0.11

[backends]
backend1 ansible_host=10.10.10.20
backend2 ansible_host=10.10.10.21

[all:vars]
ansible_user=<USUARIO_VM>
ansible_ssh_private_key_file=/home/<USUARIO_VM>/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3

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

## 15. Playbook preparar_jumpstart.yml

Hace lo siguiente:
instala herramientas necesarias
crea /home/<usuario>/mariadb_offline
descarga paquetes .deb de MariaDB/Galera y dependencias
genera Packages.gz
crea la plantilla de configuración Galera


Contenido de preparar_jumpstart.yml:
```bash
---
- name: Preparar jumpstart para instalacion offline
  hosts: localhost
  become: yes
  vars:
    usuario: "{{ ansible_env.SUDO_USER | default(ansible_user_id) }}"

  tasks:

    - name: Instalar sshpass para permitir el uso de las contraseñas
      apt:
        name:
          - sshpass
          - apt-rdepends
          - dpkg-dev
        state: present
        update_cache: yes

    - name: Crear carpeta para paquetes MariaDB
      file:
        path: "/home/{{ usuario }}/mariadb_offline"
        state: directory
        owner: "{{ usuario }}"
        group: "{{ usuario }}"
        mode: '0755'

    - name: Descargar paquetes de MariaDB y dependencias
      shell: |
        set -e
        DEST="/home/{{ usuario }}/mariadb_offline"

        rm -rf "$DEST"
        mkdir -p "$DEST"
        cd "$DEST"

        apt-get update

        apt-rdepends \
          mariadb-server \
          mariadb-client \
          galera-3 \
          socat \
          tinyca \
          liburi-perl \
          libhttp-message-perl \
          liblwp-mediatypes-perl \
          libio-html-perl \
          libhttp-date-perl \
          libencode-locale-perl \
          libhtml-parser-perl \
          libcgi-pm-perl \
          libhtml-template-perl \
          libcgi-fast-perl \
          | grep -v "^ " \
          | grep -v "^PreDepends:" \
          | grep -v "^Depends:" \
          | grep -v "^Recommends" \
          | sort -u > paquetes.txt

        while read -r pkg; do
          apt-cache show "$pkg" >/dev/null 2>&1 && apt-get download "$pkg" || true
        done < paquetes.txt

        dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz

        ls "$DEST"/liburi-perl*.deb >/dev/null 2>&1
        ls "$DEST"/libhtml-parser-perl*.deb >/dev/null 2>&1
        ls "$DEST"/libcgi-pm-perl*.deb >/dev/null 2>&1
        ls "$DEST"/libhtml-template-perl*.deb >/dev/null 2>&1
        ls "$DEST"/libcgi-fast-perl*.deb >/dev/null 2>&1

        chown -R {{ usuario }}:{{ usuario }} "$DEST"

    - name: Asegurar que las plantillas existen
      file:
        path: "/home/{{ usuario }}/template"
        state: directory
        owner: "{{ usuario }}"
        group: "{{ usuario }}"
        mode: '0755'

    - name: Crear la plantilla Jinja2 de Galera
      copy:
        dest: "/home/{{ usuario }}/template/60-galera.cnf.j2"
        owner: "{{ usuario }}"
        group: "{{ usuario }}"
        mode: '0644'
        content: |
          [mysqld]
           wsrep_on                           = ON
           wsrep_cluster_name                 = "galera_cluster_proyecto"
           wsrep_provider                     = /usr/lib/galera/libgalera_smm.so
           wsrep_cluster_address              = "gcomm://10.10.10.20,10.10.10.21"
           binlog_format                      = ROW
           default_storage_engine             = InnoDB
           innodb_autoinc_lock_mode           = 2
           wsrep_node_address                 = "{% raw %}{{ ansible_host }}{% endraw %}"
           wsrep_node_name                    = "{% raw %}{{ inventory_hostname }}{% endraw %}"

```

## 16. Playbook backend.yml

Hace lo siguiente

copia el repositorio offline a los backends
desactiva repositorios externos
instala MariaDB/Galera offline
configura Galera
inicia el cluster en backend1
une backend2 al cluster
crea wordpress_db
crea wordpress_user
comprueba el estado final


Contenido de backend.yml:

```bash

---
- name: Instalacion de MariaDB Galera Offline
  hosts: backends
  become: yes
  any_errors_fatal: true

  vars:
    local_user: "{{ lookup('env', 'USER') }}"
    local_repo_path: "/home/{{ local_user }}/mariadb_offline"
    local_template_path: "/home/{{ local_user }}/template/60-galera.cnf.j2"

    db_name: wordpress_db
    db_user: wordpress_user
    db_pass: wordpress_pass

  pre_tasks:

    - name: Comprobar que existe la carpeta mariadb_offline en jumpstart
      stat:
        path: "{{ local_repo_path }}"
      register: repo_check
      delegate_to: localhost
      become: no
      run_once: true

    - name: Fallar si no existe mariadb_offline
      fail:
        msg: "No existe {{ local_repo_path }}. Ejecuta primero preparar_jumpstart.yml"
      when: not repo_check.stat.exists
      delegate_to: localhost
      become: no
      run_once: true

    - name: Comprobar que existe Packages.gz en jumpstart
      stat:
        path: "{{ local_repo_path }}/Packages.gz"
      register: packages_check
      delegate_to: localhost
      become: no
      run_once: true

    - name: Fallar si no existe Packages.gz
      fail:
        msg: "No existe {{ local_repo_path }}/Packages.gz. Ejecuta primero preparar_jumpstart.yml"
      when: not packages_check.stat.exists
      delegate_to: localhost
      become: no
      run_once: true

    - name: Comprobar que existe la plantilla Galera en jumpstart
      stat:
        path: "{{ local_template_path }}"
      register: template_check
      delegate_to: localhost
      become: no
      run_once: true

    - name: Fallar si no existe la plantilla Galera
      fail:
        msg: "No existe {{ local_template_path }}. Ejecuta primero preparar_jumpstart.yml"
      when: not template_check.stat.exists
      delegate_to: localhost
      become: no
      run_once: true

  tasks:

    - name: 1. Crear repositorio temporal en backends
      shell: |
        rm -rf /tmp/mariadb_repo
        mkdir -p /tmp/mariadb_repo
        mkdir -p /etc/mysql/mariadb.conf.d

    - name: 2. Copiar paquetes .deb desde jumpstart a los backends
      copy:
        src: "{{ local_repo_path }}/"
        dest: "/tmp/mariadb_repo/"
        owner: root
        group: root
        mode: preserve

    - name: 3. Desactivar repositorios externos
      shell: |
        cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
        sed -i 's/^deb /#deb /g' /etc/apt/sources.list 2>/dev/null || true
        sed -i 's/^deb-src /#deb-src /g' /etc/apt/sources.list 2>/dev/null || true

        for f in /etc/apt/sources.list.d/*.list; do
          [ -f "$f" ] && mv "$f" "$f.bak" || true
        done

    - name: 4. Configurar repositorio local MariaDB offline
      copy:
        dest: /etc/apt/sources.list.d/mariadb-local.list
        content: |
          deb [trusted=yes] file:/tmp/mariadb_repo ./

    - name: 4.1 Crear estructura base de configuracion MariaDB
      shell: |
        mkdir -p /etc/mysql/conf.d
        mkdir -p /etc/mysql/mariadb.conf.d

    - name: 4.2 Crear archivo base mariadb.conf si no existe
      copy:
        dest: /etc/mysql/mariadb.cnf
        force: no
        owner: root
        group: root
        mode: '0644'
        content: |
          [client-server]
          !includedir /etc/mysql/conf.d/
          !includedir /etc/mysql/mariadb.conf.d/

    - name: 4.9 Limpiar bloqueos antiguos de apt/dpkg
      shell: |
        systemctl stop apt-daily.service apt-daily-upgrade.service 2>/dev/null || true
        systemctl kill --kill-who=all apt-daily.service apt-daily-upgrade.service 2>/dev/null || true

        killall -9 apt apt-get dpkg unattended-upgrade 2>/dev/null || true

        rm -f /var/lib/dpkg/lock-frontend
        rm -f /var/lib/dpkg/lock
        rm -f /var/cache/apt/archives/lock
        rm -f /var/lib/apt/lists/lock

        DEBIAN_FRONTEND=noninteractive dpkg --force-confdef --force-confold --configure -a || true
      ignore_errors: yes

    - name: 5. Actualizar cache APT usando repositorio local
      shell: |
        apt-get update

    - name: 6. Reparar paquetes pendientes usando repositorio local
      shell: |
        mkdir -p /etc/mysql/mariadb.conf.d

        DEBIAN_FRONTEND=noninteractive apt-get install -y \
          -o Dpkg::Options::="--force-confdef" \
          -o Dpkg::Options::="--force-confold" \
          mariadb-common || true

        DEBIAN_FRONTEND=noninteractive apt-get install -y -f \
          -o Dpkg::Options::="--force-confdef" \
          -o Dpkg::Options::="--force-confold" || true

        DEBIAN_FRONTEND=noninteractive dpkg \
          --force-confdef \
          --force-confold \
          --configure -a || true
      ignore_errors: yes

    - name: 6.0 Instalar primero liburi-perl
      shell: |
        dpkg -i /tmp/mariadb_repo/liburi-perl*.deb || true
        dpkg --force-confdef --force-confold --configure liburi-perl || true

    - name: 6.1 Instalar dependencias Perl necesarias para MariaDB
      shell: |
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
          -o Dpkg::Options::="--force-confdef" \
          -o Dpkg::Options::="--force-confold" \
          perl \
          libhtml-parser-perl \
          libhttp-message-perl \
          libcgi-pm-perl \
          libhtml-template-perl \
          libcgi-fast-perl \
          libio-html-perl \
          liblwp-mediatypes-perl \
          libencode-locale-perl \
          libhttp-date-perl

    - name: 6.2 Configurar paquetes pendientes despues de Perl
      shell: |
        DEBIAN_FRONTEND=noninteractive dpkg \
          --force-confdef \
          --force-confold \
          --configure -a

    - name: 7. Instalar MariaDB Galera offline
      shell: |
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
          -o Dpkg::Options::="--force-confdef" \
          -o Dpkg::Options::="--force-confold" \
          mariadb-server mariadb-client galera-3 socat tinyca

    - name: 8. Abrir puertos de Galera en UFW
      shell: |
        ufw allow 3306/tcp || true
        ufw allow 4567/tcp || true
        ufw allow 4568/tcp || true
        ufw allow 4444/tcp || true
      ignore_errors: yes

    - name: 9. Aplicar configuración de Galera
      template:
        src: "{{ local_template_path }}"
        dest: "/etc/mysql/mariadb.conf.d/60-galera.cnf"
        owner: root
        group: root
        mode: '0644'

    - name: 9.1 Limpiar bind-address
      shell: |
        sed -i "s/^\^bind-address/bind-address/g" /etc/mysql/mariadb.conf.d/*.cnf 2>/dev/null || true

    - name: 10. Configurar acceso externo 0.0.0.0
      copy:
        dest: /etc/mysql/mariadb.conf.d/99-bind-address.cnf
        owner: root
        group: root
        mode: '0644'
        content: |
          [mysqld]
          bind-address = 0.0.0.0

    - name: 11. Parar MariaDB antes de iniciar el cluster
      shell: |
        systemctl stop mariadb || true
        killall -9 mysqld || true
        killall -9 mariadbd || true
      ignore_errors: yes

    - name: 12. Marcar backend1 como nodo seguro para bootstrap
      shell: |
        if [ -f /var/lib/mysql/grastate.dat ]; then
          sed -i 's/safe_to_bootstrap: 0/safe_to_bootstrap: 1/' /var/lib/mysql/grastate.dat
        fi
      when: inventory_hostname == "backend1"

    - name: 12.5 Preparar bootstrap Galera solo en backend1
      shell: |
        sed -i 's#wsrep_cluster_address.*#wsrep_cluster_address = "gcomm://"#' /etc/mysql/mariadb.conf.d/60-galera.cnf
      when: inventory_hostname == "backend1"

    - name: 13. Arrancar cluster Galera en backend1
      command: galera_new_cluster
      when: inventory_hostname == "backend1"

    - name: 14. Esperar a que MariaDB responda en backend1
      shell: |
        mysqladmin ping
      register: mysql_ping_backend1
      retries: 10
      delay: 3
      until: mysql_ping_backend1.rc == 0
      when: inventory_hostname == "backend1"

    - name: 14.5 Restaurar direccion completa del cluster en backend1
      shell: |
        sed -i 's#wsrep_cluster_address.*#wsrep_cluster_address = "gcomm://10.10.10.20,10.10.10.21"#' /etc/mysql/mariadb.conf.d/60-galera.cnf
      when: inventory_hostname == "backend1"

    - name: 15. Unir backend2 al cluster
      service:
        name: mariadb
        state: started
      when: inventory_hostname == "backend2"

    - name: 16. Esperar a que MariaDB responda en backend2
      shell: |
        mysqladmin ping
      register: mysql_ping_backend2
      retries: 10
      delay: 3
      until: mysql_ping_backend2.rc == 0
      when: inventory_hostname == "backend2"

    - name: 17. Esperar estabilizacion del cluster
      pause:
        seconds: 10

    - name: 18. Crear base de datos, usuario, password y permisos en backend1
      shell: |
        mysql -e "CREATE DATABASE IF NOT EXISTS {{ db_name }};"
        mysql -e "CREATE USER IF NOT EXISTS '{{ db_user }}'@'%' IDENTIFIED BY '{{ db_pass }}';"
        mysql -e "GRANT ALL PRIVILEGES ON {{ db_name }}.* TO '{{ db_user }}'@'%';"
        mysql -e "FLUSH PRIVILEGES;"
      when: inventory_hostname == "backend1"

    - name: 19. Comprobar cluster y base de datos en backend1
      shell: |
        mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
        mysql -e "SHOW STATUS LIKE 'wsrep_cluster_status';"
        mysql -e "SHOW STATUS LIKE 'wsrep_ready';"
        mysql -e "SHOW DATABASES LIKE '{{ db_name }}';"
        mysql -e "SELECT user, host FROM mysql.user WHERE user='{{ db_user }}';"
      register: cluster_check
      when: inventory_hostname == "backend1"

    - name: 20. Mostrar comprobación final
      debug:
        var: cluster_check.stdout_lines
      when: inventory_hostname == "backend1"

```



## 17. Script desplegar_galera.sh

Hace lo siguiente:
comprueba que estamos en jumpstart
instala herramientas necesarias
comprueba ping con backend1 y backend2
crea hosts.ini correcto para Galera
comprueba Ansible
ejecuta preparar_jumpstart.yml
comprueba el repo offline
comprueba sintaxis de backend.yml
ejecuta backend.yml
muestra comandos finales de verificación


Contenido de desplegar_galera.sh:

```bash
#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./desplegar_galera.sh <usuario_vm>"
  echo "Ejemplo: ./desplegar_galera.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"

BACKEND1_IP="10.10.10.20"
BACKEND2_IP="10.10.10.21"

INVENTORY="hosts.ini"
PREP_PLAYBOOK="preparar_jumpstart.yml"
BACKEND_PLAYBOOK="backend.yml"

echo "=========================================="
echo " Despliegue automático de MariaDB Galera"
echo "=========================================="
echo
echo "Usuario VM: ${USUARIO_VM}"
echo "Backend1: ${BACKEND1_IP}"
echo "Backend2: ${BACKEND2_IP}"
echo

echo "[1/9] Comprobando que estamos en jumpstart..."
hostname

echo
echo "[2/9] Instalando herramientas necesarias en jumpstart..."
sudo apt update
sudo apt install ansible sshpass apt-rdepends dpkg-dev -y

echo
echo "[3/9] Comprobando conectividad con backend1 y backend2..."
ping -c 3 "${BACKEND1_IP}"
ping -c 3 "${BACKEND2_IP}"

echo
echo "[4/9] Creando hosts.ini correcto para Galera..."

cat > "${INVENTORY}" <<EOF
[backends]
backend1 ansible_host=${BACKEND1_IP}
backend2 ansible_host=${BACKEND2_IP}

[backends:vars]
ansible_user=${USUARIO_VM}
ansible_ssh_private_key_file=/home/${USUARIO_VM}/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
EOF

cat "${INVENTORY}"

echo
echo "[5/9] Comprobando que existen los playbooks..."

if [[ ! -f "${PREP_PLAYBOOK}" ]]; then
  echo "ERROR: No existe ${PREP_PLAYBOOK}"
  exit 1
fi

if [[ ! -f "${BACKEND_PLAYBOOK}" ]]; then
  echo "ERROR: No existe ${BACKEND_PLAYBOOK}"
  exit 1
fi

ls -l "${PREP_PLAYBOOK}" "${BACKEND_PLAYBOOK}"

echo
echo "[6/9] Probando Ansible con clave SSH..."

ASK_PASS=""

if ansible -i "${INVENTORY}" backends -m ping; then
  echo "Ansible funciona con clave SSH."
else
  echo
  echo "No ha funcionado con clave SSH."
  echo "Se usará contraseña SSH con -k."
  ASK_PASS="-k"
  ansible -i "${INVENTORY}" backends -m ping ${ASK_PASS}
fi

echo
echo "[7/9] Preparando repositorio offline en jumpstart..."
ansible-playbook -i localhost, -c local "${PREP_PLAYBOOK}" -K

echo
echo "Comprobando repositorio offline..."

REPO_DIR="/home/${USUARIO_VM}/mariadb_offline"
TEMPLATE_FILE="/home/${USUARIO_VM}/template/60-galera.cnf.j2"

ls -lh "${REPO_DIR}/Packages.gz"
ls -lh "${TEMPLATE_FILE}"

ls -lh "${REPO_DIR}"/libhtml-parser-perl*.deb
ls -lh "${REPO_DIR}"/libcgi-pm-perl*.deb
ls -lh "${REPO_DIR}"/libhtml-template-perl*.deb
ls -lh "${REPO_DIR}"/libcgi-fast-perl*.deb

echo
echo "[8/9] Comprobando sintaxis de backend.yml..."
ansible-playbook -i "${INVENTORY}" "${BACKEND_PLAYBOOK}" --syntax-check

echo
echo "[9/9] Desplegando MariaDB Galera en los backends..."
ansible-playbook -i "${INVENTORY}" "${BACKEND_PLAYBOOK}" ${ASK_PASS} -K

echo
echo "=========================================="
echo " Despliegue terminado"
echo "=========================================="
echo
echo "Comprobaciones:"
echo
echo "ssh ${USUARIO_VM}@${BACKEND1_IP}"
echo "sudo mysql -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\""
echo "sudo mysql -e \"SHOW STATUS LIKE 'wsrep_cluster_status';\""
echo "sudo mysql -e \"SHOW STATUS LIKE 'wsrep_ready';\""
echo
echo "Resultado esperado:"
echo "wsrep_cluster_size = 2"
echo "wsrep_cluster_status = Primary"
echo "wsrep_ready = ON"
```


## 18. Copiar scripts de Galera a Jumpstart

Desde el PC anfitrión, estando en la carpeta donde están los archivos:

```bash
scp -P 2225 preparar_jumpstart.yml backend.yml desplegar_galera.sh <USUARIO_VM>@127.0.0.1:~/
```

Ejemplo:

scp -P 2225 preparar_jumpstart.yml backend.yml desplegar_galera.sh alejandroro@127.0.0.1:~/


## 19. Ejecutar despliegue automático de Galera

Entrar en jumpstart:
```bash
ssh -p 2225 <USUARIO_VM>@127.0.0.1
```

Ejemplo:

ssh -p 2225 alejandroro@127.0.0.1

Dentro de jumpstart:

```bash
chmod +x desplegar_galera.sh
./desplegar_galera.sh <USUARIO_VM>
```

Ejemplo:

chmod +x desplegar_galera.sh
./desplegar_galera.sh alejandroro

El script pedirá varias veces contraseña:

[sudo] password
BECOME password


En ambos casos se introduce la contraseña del usuario de las VMs.


## 20. Resultado esperado del despliegue

Al final debe aparecer:

backend1 : failed=0
backend2 : failed=0

Y en la comprobación final:

wsrep_cluster_size    2
wsrep_cluster_status  Primary
wsrep_ready           ON
wordpress_db
wordpress_user        %



## 21. Verificar cluster en backend1

Desde jumpstart:
```bash
ssh <USUARIO_VM>@10.10.10.20
``` 
Ejemplo:

ssh alejandroro@10.10.10.20

Dentro de backend1:
```bash
sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_status';"
sudo mysql -e "SHOW STATUS LIKE 'wsrep_ready';"
sudo mysql -e "SHOW DATABASES LIKE 'wordpress_db';"
sudo mysql -e "SELECT user, host FROM mysql.user WHERE user='wordpress_user';"
``` 
Resultado esperado:

wsrep_cluster_size     2
wsrep_cluster_status   Primary
wsrep_ready            ON
wordpress_db
wordpress_user         %

Salir:

exit

## 22. Probar replicación entre backend1 y backend2

Crear una tabla de prueba en backend1:
```bash
ssh <USUARIO_VM>@10.10.10.20
```  
Dentro de backend1:
```bash
sudo mysql -e "USE wordpress_db; CREATE TABLE IF NOT EXISTS prueba_galera (id INT PRIMARY KEY, mensaje VARCHAR(100)); INSERT INTO prueba_galera VALUES (1, 'replicacion correcta') ON DUPLICATE KEY UPDATE mensaje='replicacion correcta';"
``` 
Salir:
```bash
exit
``` 
Leer la tabla desde backend2:
```bash
ssh <USUARIO_VM>@10.10.10.21
``` 
Dentro de backend2:
```bash
sudo mysql -e "SELECT * FROM wordpress_db.prueba_galera;"
``` 
Resultado esperado:

+----+----------------------+
| id | mensaje              |
+----+----------------------+
|  1 | replicacion correcta |
+----+----------------------+

Esto confirma que la replicación funciona correctamente.
