Guía completa: despliegue de MariaDB Galera en backend1 y backend2 desde Jumpstart
Objetivo

Desplegar un cluster MariaDB Galera en:

backend1 -> 10.10.10.20
backend2 -> 10.10.10.21

La instalación se hace desde jumpstart mediante Ansible.

Los backends no necesitan NAT ni Internet directo. Jumpstart prepara un repositorio offline con todos los paquetes .deb, lo copia a los backends y desde ahí instala MariaDB/Galera.

## 1. Requisitos previos

Antes de empezar deben existir estas máquinas:
```text
jumpstart
backend1
backend2
```

Con estas IPs:


```bash
jumpstart internal -> 10.10.10.10
backend1           -> 10.10.10.20
backend2           -> 10.10.10.21
``` 

Jumpstart debe tener acceso a Internet por NAT, porque será quien descargue los paquetes.

Los backends pueden estar solo en la red internal, sin NAT.

## 2. Entrar en Jumpstart

Desde el PC anfitrión:
```bash
ssh -p 2225 <USUARIO_VM>@127.0.0.1
```
Ejemplo:
```bash
ssh -p 2225 alejandroro@127.0.0.1
```
(esto ns si aun lo podeis hacer porque esto lo he hecho yo porque como ya tengo automatizado las vm he creado script q tienen puertos temporales por eso me deja, si no podeis os meteis desde ls vm)

Una vez dentro, el prompt debería ser parecido a:

alejandroro@jumpstart:~$

Comprobar que estamos en Jumpstart:
```bash
hostname
``
Debe devolver:

jumpstart
3. Comprobar red de Jumpstart

Dentro de Jumpstart:

ip a | grep -E "10.10.10.10|10.10.10.100|10.0.0.20|10.0.0.100"
cat /proc/sys/net/ipv4/ip_forward

Resultado esperado:

10.0.0.20
10.0.0.100
10.10.10.10
10.10.10.100

Y:

1
4. Comprobar conectividad con backend1 y backend2

Desde Jumpstart:

ping -c 3 10.10.10.20
ping -c 3 10.10.10.21

Ambos deben responder.

También comprobar SSH manualmente:

ssh <USUARIO_VM>@10.10.10.20

Ejemplo:

ssh alejandroro@10.10.10.20

Salir:

exit

Probar backend2:

ssh <USUARIO_VM>@10.10.10.21

Salir:

exit
5. Instalar Ansible y herramientas necesarias en Jumpstart

Dentro de Jumpstart:

sudo apt update
sudo apt install ansible sshpass apt-rdepends dpkg-dev -y

Comprobar:

ansible --version
6. Crear inventario hosts.ini

Dentro de Jumpstart:

nano hosts.ini

Contenido:

[backends]
backend1 ansible_host=10.10.10.20
backend2 ansible_host=10.10.10.21

[backends:vars]
ansible_user=<USUARIO_VM>
ansible_python_interpreter=/usr/bin/python3

Ejemplo:

[backends]
backend1 ansible_host=10.10.10.20
backend2 ansible_host=10.10.10.21

[backends:vars]
ansible_user=alejandroro
ansible_python_interpreter=/usr/bin/python3

Guardar:

CTRL + O
ENTER
CTRL + X
7. Probar Ansible contra los backends
Caso A: ya tienen claves SSH configuradas

Probar:

ansible -i hosts.ini backends -m ping

Resultado esperado:

backend1 | SUCCESS
backend2 | SUCCESS
Caso B: no tienen claves SSH configuradas

Usar -k para que Ansible pida contraseña SSH:

ansible -i hosts.ini backends -m ping -k

Pedirá:

SSH password:

Poner la contraseña del usuario de las máquinas.

Resultado esperado:

backend1 | SUCCESS
backend2 | SUCCESS
8. Opcional: configurar claves SSH para no usar -k

Este paso no es obligatorio, pero facilita el despliegue.

Dentro de Jumpstart:

ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

Copiar la clave a backend1:

ssh-copy-id <USUARIO_VM>@10.10.10.20

Copiar la clave a backend2:

ssh-copy-id <USUARIO_VM>@10.10.10.21

Ejemplo:

ssh-copy-id alejandroro@10.10.10.20
ssh-copy-id alejandroro@10.10.10.21

Probar:

ansible -i hosts.ini backends -m ping

Si sale SUCCESS, ya no hace falta usar -k.

9. Crear preparar_jumpstart.yml

Este playbook descarga en Jumpstart todos los paquetes necesarios para instalar MariaDB/Galera offline en los backends.

Dentro de Jumpstart:

nano preparar_jumpstart.yml

Contenido corregido:

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

Guardar:

CTRL + O
ENTER
CTRL + X
10. Ejecutar preparación offline en Jumpstart

Dentro de Jumpstart:

ansible-playbook -i localhost, -c local preparar_jumpstart.yml -K

Pedirá:

BECOME password:

Poner la contraseña sudo.

Resultado esperado:

failed=0

Este playbook crea:

/home/<USUARIO_VM>/mariadb_offline
/home/<USUARIO_VM>/template/60-galera.cnf.j2
11. Comprobar que el repositorio offline se ha creado bien

Cambiar <USUARIO_VM> por el usuario real.

Ejemplo con alejandroro:

ls -lh /home/alejandroro/mariadb_offline | head
ls -lh /home/alejandroro/mariadb_offline/Packages.gz
ls -lh /home/alejandroro/template/60-galera.cnf.j2
ls /home/alejandroro/mariadb_offline/*.deb | wc -l

También comprobar que existen los paquetes que antes daban error:

ls -lh /home/alejandroro/mariadb_offline/libhtml-parser-perl*.deb
ls -lh /home/alejandroro/mariadb_offline/libcgi-pm-perl*.deb
ls -lh /home/alejandroro/mariadb_offline/libhtml-template-perl*.deb
ls -lh /home/alejandroro/mariadb_offline/libcgi-fast-perl*.deb

Deben existir todos.

12. Crear backend.yml

Dentro de Jumpstart:

nano backend.yml

Contenido:

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
        killall -9 apt apt-get dpkg 2>/dev/null || true
        rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
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

Guardar:

CTRL + O
ENTER
CTRL + X
13. Ejecutar instalación del cluster

Comprobar sintaxis:

ansible-playbook -i hosts.ini backend.yml --syntax-check

Ejecutar el playbook.

Caso A: con claves SSH configuradas
ansible-playbook -i hosts.ini backend.yml -K
Caso B: sin claves SSH configuradas
ansible-playbook -i hosts.ini backend.yml -k -K

Explicación:

-k  -> pide contraseña SSH
-K  -> pide contraseña sudo

Resultado esperado:

backend1 : failed=0
backend2 : failed=0
14. Verificar el cluster en backend1

Desde Jumpstart:

ssh <USUARIO_VM>@10.10.10.20

Ejecutar:

sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_status';"
sudo mysql -e "SHOW STATUS LIKE 'wsrep_ready';"
sudo mysql -e "SHOW DATABASES LIKE 'wordpress_db';"
sudo mysql -e "SELECT user, host FROM mysql.user WHERE user='wordpress_user';"

Resultado esperado:

wsrep_cluster_size     2
wsrep_cluster_status   Primary
wsrep_ready            ON
wordpress_db
wordpress_user         %

Salir:

exit
15. Verificar el cluster en backend2

Desde Jumpstart:

ssh <USUARIO_VM>@10.10.10.21

Ejecutar:

sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_status';"
sudo mysql -e "SHOW STATUS LIKE 'wsrep_ready';"
sudo mysql -e "SHOW DATABASES LIKE 'wordpress_db';"

Resultado esperado:

wsrep_cluster_size     2
wsrep_cluster_status   Primary
wsrep_ready            ON
wordpress_db

Salir:

exit
16. Probar replicación

Crear una tabla de prueba en backend1:

ssh <USUARIO_VM>@10.10.10.20
sudo mysql -e "USE wordpress_db; CREATE TABLE IF NOT EXISTS prueba_galera (id INT PRIMARY KEY, mensaje VARCHAR(100)); INSERT INTO prueba_galera VALUES (1, 'replicacion correcta') ON DUPLICATE KEY UPDATE mensaje='replicacion correcta';"

Salir:

exit

Leer la tabla desde backend2:

ssh <USUARIO_VM>@10.10.10.21
sudo mysql -e "SELECT * FROM wordpress_db.prueba_galera;"

Resultado esperado:

+----+----------------------+
| id | mensaje              |
+----+----------------------+
|  1 | replicacion correcta |
+----+----------------------+

Esto confirma que la replicación funciona.

17. Error corregido

Durante las pruebas apareció este error:

E: No se ha podido localizar el paquete libhtml-parser-perl
E: No se ha podido localizar el paquete libcgi-pm-perl
E: El paquete «libhtml-template-perl» no tiene un candidato para la instalación
E: No se ha podido localizar el paquete libcgi-fast-perl

La causa era que backend.yml intentaba instalar esos paquetes, pero preparar_jumpstart.yml no los descargaba en el repositorio offline.

Se solucionó añadiendo estos paquetes a preparar_jumpstart.yml:

libhtml-parser-perl
libcgi-pm-perl
libhtml-template-perl
libcgi-fast-perl
