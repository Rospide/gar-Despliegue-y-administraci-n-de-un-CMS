#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./04_desplegar_todo.sh <usuario_vm>"
  echo "Ejemplo: ./04_desplegar_todo.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"
FRONTEND1_IP="10.0.0.10"
FRONTEND2_IP="10.0.0.11"
BACKEND1_IP="10.10.10.20"
BACKEND2_IP="10.10.10.21"
BALANCEADOR_IP="10.0.0.1"
ROUTER_LINUX_IP="10.0.0.254"
INVENTORY="hosts.ini"

if [[ "$(hostname)" != "jumpstart" ]]; then
  echo "ERROR: este script debe ejecutarse dentro de jumpstart."
  echo "Entra con: ssh -p 2225 ${USUARIO_VM}@127.0.0.1"
  exit 1
fi

write_inventory() {
cat > "$INVENTORY" <<EOF
[frontends]
frontend1 ansible_host=${FRONTEND1_IP}
frontend2 ansible_host=${FRONTEND2_IP}

[backends]
backend1 ansible_host=${BACKEND1_IP}
backend2 ansible_host=${BACKEND2_IP}

[infra]
balanceador ansible_host=${BALANCEADOR_IP}
router-linux ansible_host=${ROUTER_LINUX_IP}

[zabbix_server]
backend1 ansible_host=${BACKEND1_IP}

[zabbix_agent_nodes]
frontend1 ansible_host=${FRONTEND1_IP}
frontend2 ansible_host=${FRONTEND2_IP}
backend2 ansible_host=${BACKEND2_IP}
balanceador ansible_host=${BALANCEADOR_IP}
router-linux ansible_host=${ROUTER_LINUX_IP}

[all:vars]
ansible_user=${USUARIO_VM}
ansible_ssh_private_key_file=/home/${USUARIO_VM}/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
EOF
}

write_playbooks() {
cat > preparar_jumpstart.yml <<'PLAYBOOK_PREPARAR'
---
- name: Preparar jumpstart para isntalacion offline
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

         apt-rdepends mariadb-server mariadb-client galera-3 socat tinyca liburi-perl libhttp-message-perl liblwp-mediatypes-perl libio-html-perl libhttp-date-perl libencode-locale-perl \
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
PLAYBOOK_PREPARAR

cat > backend.yml <<'PLAYBOOK_BACKEND'
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
PLAYBOOK_BACKEND

cat > frontend_wordpress.yml <<'PLAYBOOK_FRONTEND'
---
- name: Desplegar WordPress en frontend1 y frontend2
  hosts: frontends
  become: yes

  vars:
    wp_db_name: wordpress_db
    wp_db_user: wordpress_user
    wp_db_pass: wordpress_pass
    wp_db_host: 10.10.10.20

    wp_download_url: https://wordpress.org/latest.tar.gz
    wp_local_tar: /tmp/wordpress-latest.tar.gz
    wp_web_root: /var/www/html

  pre_tasks:
    - name: Comprobar si WordPress ya esta descargado correctamente en jumpstart
      shell: |
        if [ -f "{{ wp_local_tar }}" ]; then
          tar -tzf "{{ wp_local_tar }}" >/dev/null 2>&1
        else
          exit 1
        fi
      register: wp_tar_check
      delegate_to: localhost
      become: no
      run_once: true
      changed_when: false
      failed_when: false

    - name: Eliminar descarga corrupta de WordPress si existe
      file:
        path: "{{ wp_local_tar }}"
        state: absent
      delegate_to: localhost
      become: no
      run_once: true
      when: wp_tar_check.rc != 0

    - name: Descargar WordPress en jumpstart con reintentos
      shell: |
        wget --tries=5 --timeout=60 -O "{{ wp_local_tar }}" "{{ wp_download_url }}"
      delegate_to: localhost
      become: no
      run_once: true
      when: wp_tar_check.rc != 0

    - name: Verificar descarga de WordPress
      shell: |
        tar -tzf "{{ wp_local_tar }}" >/dev/null
      delegate_to: localhost
      become: no
      run_once: true
      changed_when: false

  tasks:
    - name: Detener servicios automaticos de APT
      shell: |
        systemctl stop unattended-upgrades 2>/dev/null || true
        systemctl stop apt-daily.service 2>/dev/null || true
        systemctl stop apt-daily-upgrade.service 2>/dev/null || true
        systemctl stop apt-daily.timer 2>/dev/null || true
        systemctl stop apt-daily-upgrade.timer 2>/dev/null || true
        systemctl disable apt-daily.timer 2>/dev/null || true
        systemctl disable apt-daily-upgrade.timer 2>/dev/null || true
      changed_when: false
      ignore_errors: yes

    - name: Esperar a que no haya bloqueos de APT
      shell: |
        timeout 180 bash -c '
        while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
              fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
              fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
          echo "Esperando a que termine apt/dpkg..."
          sleep 5
        done
        ' || true
      changed_when: false

    - name: Limpiar posibles bloqueos antiguos de APT
      shell: |
        rm -f /var/lib/dpkg/lock-frontend
        rm -f /var/lib/dpkg/lock
        rm -f /var/cache/apt/archives/lock
        dpkg --configure -a || true
        apt clean || true
      changed_when: false

    - name: Instalar Apache, PHP y cliente MySQL
      apt:
        name:
          - apache2
          - php
          - libapache2-mod-php
          - php-mysql
          - php-curl
          - php-gd
          - php-mbstring
          - php-xml
          - php-xmlrpc
          - php-soap
          - php-intl
          - php-zip
          - unzip
          - tar
          - mysql-client
        state: present
        update_cache: yes

    - name: Activar Apache al arrancar
      systemd:
        name: apache2
        enabled: yes
        state: started

    - name: Limpiar instalación web anterior
      shell: |
        rm -rf {{ wp_web_root }}/*
        rm -rf /tmp/wordpress
      ignore_errors: yes

    - name: Copiar y descomprimir WordPress en frontend
      unarchive:
        src: "{{ wp_local_tar }}"
        dest: /tmp/
        remote_src: no

    - name: Copiar WordPress a /var/www/html
      shell: |
        cp -a /tmp/wordpress/. {{ wp_web_root }}/
        chown -R www-data:www-data {{ wp_web_root }}
        find {{ wp_web_root }} -type d -exec chmod 755 {} \;
        find {{ wp_web_root }} -type f -exec chmod 644 {} \;

    - name: Crear wp-config.php
      copy:
        dest: "{{ wp_web_root }}/wp-config.php"
        owner: www-data
        group: www-data
        mode: "0644"
        content: |
          <?php
          define( 'DB_NAME', '{{ wp_db_name }}' );
          define( 'DB_USER', '{{ wp_db_user }}' );
          define( 'DB_PASSWORD', '{{ wp_db_pass }}' );
          define( 'DB_HOST', '{{ wp_db_host }}' );
          define( 'DB_CHARSET', 'utf8' );
          define( 'DB_COLLATE', '' );

          define( 'AUTH_KEY',         'proyecto-auth-key' );
          define( 'SECURE_AUTH_KEY',  'proyecto-secure-auth-key' );
          define( 'LOGGED_IN_KEY',    'proyecto-logged-in-key' );
          define( 'NONCE_KEY',        'proyecto-nonce-key' );
          define( 'AUTH_SALT',        'proyecto-auth-salt' );
          define( 'SECURE_AUTH_SALT', 'proyecto-secure-auth-salt' );
          define( 'LOGGED_IN_SALT',   'proyecto-logged-in-salt' );
          define( 'NONCE_SALT',       'proyecto-nonce-salt' );

          $table_prefix = 'wp_';

          define( 'WP_DEBUG', false );

          if ( ! defined( 'ABSPATH' ) ) {
              define( 'ABSPATH', __DIR__ . '/' );
          }

          require_once ABSPATH . 'wp-settings.php';

    - name: Configurar Apache para WordPress
      copy:
        dest: /etc/apache2/sites-available/000-default.conf
        owner: root
        group: root
        mode: "0644"
        content: |
          <VirtualHost *:80>
              ServerAdmin webmaster@localhost
              DocumentRoot /var/www/html

              <Directory /var/www/html>
                  AllowOverride All
                  Require all granted
              </Directory>

              ErrorLog ${APACHE_LOG_DIR}/error.log
              CustomLog ${APACHE_LOG_DIR}/access.log combined
          </VirtualHost>

    - name: Activar mod_rewrite
      command: a2enmod rewrite
      register: rewrite_result
      changed_when: "'Enabling module rewrite' in rewrite_result.stdout or 'To activate the new configuration' in rewrite_result.stdout"
      failed_when: false

    - name: Reiniciar Apache
      systemd:
        name: apache2
        state: restarted

    - name: Comprobar conexión con la base de datos
      shell: |
        mysql -h {{ wp_db_host }} -u {{ wp_db_user }} -p{{ wp_db_pass }} -e "SHOW DATABASES;"
      register: db_check
      changed_when: false

    - name: Mostrar resultado de conexión a la base de datos
      debug:
        var: db_check.stdout_lines
PLAYBOOK_FRONTEND

cat > zabbix_server_backend1.yml <<'PLAYBOOK_ZSERVER'
---
- name: Preparar jumpstart como proxy APT para Zabbix
  hosts: localhost
  connection: local
  become: yes

  tasks:
    - name: Instalar apt-cacher-ng en jumpstart
      apt:
        name: apt-cacher-ng
        state: present
        update_cache: yes

    - name: Limpiar cache antigua de apt-cacher-ng
      shell: |
        systemctl stop apt-cacher-ng || true
        rm -rf /var/cache/apt-cacher-ng/*
        systemctl start apt-cacher-ng

    - name: Activar apt-cacher-ng
      service:
        name: apt-cacher-ng
        state: restarted
        enabled: yes

    - name: Abrir proxy APT para la red interna
      shell: |
        ufw allow 3142/tcp || true
        ufw allow from 10.10.10.0/24 to any port 3142 proto tcp || true
        ufw reload || true
      ignore_errors: yes

    - name: Descargar repositorio Zabbix en jumpstart
      get_url:
        url: "https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_6.0+ubuntu20.04_all.deb"
        dest: "/tmp/zabbix-release_latest_6.0+ubuntu20.04_all.deb"
        mode: "0644"


- name: Instalar y configurar Zabbix Server en backend1
  hosts: zabbix_server
  become: yes

  vars:
    zabbix_db_name: zabbix
    zabbix_db_user: zabbix
    zabbix_db_pass: zabbix
    zabbix_web_ip: "192.168.56.20"
    zabbix_server_name: "Zabbix-GAR"

  tasks:
    - name: Configurar IP solo anfitrion para acceso web a Zabbix
      copy:
        dest: /etc/netplan/02-hostonly.yaml
        owner: root
        group: root
        mode: "0644"
        content: |
          network:
            version: 2
            ethernets:
              enp0s8:
                dhcp4: false
                optional: true
                addresses:
                  - {{ zabbix_web_ip }}/24

    - name: Aplicar netplan para host-only
      shell: |
        netplan generate
        netplan apply

    - name: Configurar proxy APT hacia jumpstart
      copy:
        dest: /etc/apt/apt.conf.d/01proxy
        owner: root
        group: root
        mode: "0644"
        content: |
          Acquire::http::Proxy "http://10.10.10.10:3142";
          Acquire::https::Proxy "false";

    - name: Detener servicios automaticos de APT
      shell: |
        systemctl stop unattended-upgrades 2>/dev/null || true
        systemctl stop apt-daily.service 2>/dev/null || true
        systemctl stop apt-daily-upgrade.service 2>/dev/null || true
        systemctl stop apt-daily.timer 2>/dev/null || true
        systemctl stop apt-daily-upgrade.timer 2>/dev/null || true
        systemctl disable apt-daily.timer 2>/dev/null || true
        systemctl disable apt-daily-upgrade.timer 2>/dev/null || true
      changed_when: false
      ignore_errors: yes

    - name: Esperar a que no haya bloqueos de APT
      shell: |
        timeout 60 bash -c '
        while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
              fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
              fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
          echo "Esperando a que termine apt/dpkg..."
          sleep 5
        done
        ' || true
      changed_when: false

    - name: Limpiar posibles bloqueos antiguos de APT
      shell: |
        rm -f /var/lib/dpkg/lock-frontend
        rm -f /var/lib/dpkg/lock
        rm -f /var/cache/apt/archives/lock
        dpkg --configure -a || true
        apt clean || true
      changed_when: false

    - name: Restaurar repositorios oficiales de Ubuntu
      copy:
        dest: /etc/apt/sources.list
        owner: root
        group: root
        mode: "0644"
        content: |
          deb http://es.archive.ubuntu.com/ubuntu focal main restricted universe multiverse
          deb http://es.archive.ubuntu.com/ubuntu focal-updates main restricted universe multiverse
          deb http://es.archive.ubuntu.com/ubuntu focal-backports main restricted universe multiverse
          deb http://es.archive.ubuntu.com/ubuntu focal-security main restricted universe multiverse

    - name: Eliminar repositorio local de MariaDB si existe
      file:
        path: /etc/apt/sources.list.d/mariadb-local.list
        state: absent

    - name: Limpiar listas APT antiguas
      shell: |
        apt clean
        rm -rf /var/lib/apt/lists/*

    - name: Copiar paquete de repositorio Zabbix desde jumpstart
      copy:
        src: /tmp/zabbix-release_latest_6.0+ubuntu20.04_all.deb
        dest: /tmp/zabbix-release_latest_6.0+ubuntu20.04_all.deb
        mode: "0644"

    - name: Instalar repositorio Zabbix
      apt:
        deb: /tmp/zabbix-release_latest_6.0+ubuntu20.04_all.deb

    - name: Cambiar repositorio Zabbix de HTTPS a HTTP
      shell: |
        sed -i 's|https://repo.zabbix.com|http://repo.zabbix.com|g' /etc/apt/sources.list.d/zabbix.list || true

    - name: Desactivar repositorio innecesario zabbix-agent2-plugins
      shell: |
        mv /etc/apt/sources.list.d/zabbix-agent2-plugins.list /etc/apt/sources.list.d/zabbix-agent2-plugins.list.disabled 2>/dev/null || true
        sed -i 's|^deb .*zabbix-agent2-plugins|#&|g' /etc/apt/sources.list.d/*.list 2>/dev/null || true
        sed -i 's|^deb-src .*zabbix-agent2-plugins|#&|g' /etc/apt/sources.list.d/*.list 2>/dev/null || true

    - name: Actualizar cache APT
      shell: |
        apt clean
        rm -rf /var/lib/apt/lists/*
        apt update

    - name: Instalar paquetes base para Zabbix
      apt:
        name:
          - apache2
          - php
          - php-mysql
          - netcat-openbsd
          - locales
        state: present

    - name: Instalar paquetes de Zabbix
      apt:
        name:
          - zabbix-server-mysql
          - zabbix-frontend-php
          - zabbix-sql-scripts
          - zabbix-agent
        state: latest
        update_cache: yes

    - name: Comprobar que existe algun esquema SQL de Zabbix
      shell: |
        find /usr/share /usr/share/doc -iname "*.sql.gz" | grep -i zabbix || true
      register: zabbix_sql_files
      changed_when: false

    - name: Mostrar esquemas SQL encontrados
      debug:
        var: zabbix_sql_files.stdout_lines

    - name: Comprobar MariaDB/Galera activo
      shell: |
        mysqladmin ping
        mysql -e "SHOW STATUS LIKE 'wsrep_ready';"
      changed_when: false

    - name: Crear usuario y base de datos Zabbix si no existen
      shell: |
        mysql -e "CREATE DATABASE IF NOT EXISTS {{ zabbix_db_name }} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
        mysql -e "CREATE USER IF NOT EXISTS '{{ zabbix_db_user }}'@'localhost' IDENTIFIED BY '{{ zabbix_db_pass }}';"
        mysql -e "GRANT ALL PRIVILEGES ON {{ zabbix_db_name }}.* TO '{{ zabbix_db_user }}'@'localhost';"
        mysql -e "FLUSH PRIVILEGES;"

    - name: Comprobar si existe tabla dbversion
      shell: |
        mysql -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='{{ zabbix_db_name }}' AND table_name='dbversion';"
      register: zabbix_schema
      changed_when: false

    - name: Limpiar base de datos Zabbix si el esquema no existe
      shell: |
        mysql -e "DROP DATABASE IF EXISTS {{ zabbix_db_name }};"
        mysql -e "CREATE DATABASE {{ zabbix_db_name }} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
        mysql -e "DROP USER IF EXISTS '{{ zabbix_db_user }}'@'localhost';"
        mysql -e "CREATE USER '{{ zabbix_db_user }}'@'localhost' IDENTIFIED BY '{{ zabbix_db_pass }}';"
        mysql -e "GRANT ALL PRIVILEGES ON {{ zabbix_db_name }}.* TO '{{ zabbix_db_user }}'@'localhost';"
        mysql -e "FLUSH PRIVILEGES;"
      when: zabbix_schema.stdout | int == 0

    - name: Importar esquema Zabbix segun ruta disponible
      shell: |
        set -e

        if [ -f /usr/share/zabbix-sql-scripts/mysql/server.sql.gz ]; then
          echo "Importando esquema Zabbix desde /usr/share/zabbix-sql-scripts/mysql/server.sql.gz"
          zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 {{ zabbix_db_name }}

        elif [ -f /usr/share/zabbix-server-mysql/schema.sql.gz ]; then
          echo "Importando esquema Zabbix desde /usr/share/zabbix-server-mysql/"
          zcat /usr/share/zabbix-server-mysql/schema.sql.gz | mysql --default-character-set=utf8mb4 {{ zabbix_db_name }}
          zcat /usr/share/zabbix-server-mysql/images.sql.gz | mysql --default-character-set=utf8mb4 {{ zabbix_db_name }}
          zcat /usr/share/zabbix-server-mysql/data.sql.gz | mysql --default-character-set=utf8mb4 {{ zabbix_db_name }}

        elif [ -f /usr/share/doc/zabbix-server-mysql/create.sql.gz ]; then
          echo "Importando esquema Zabbix desde /usr/share/doc/zabbix-server-mysql/create.sql.gz"
          zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql --default-character-set=utf8mb4 {{ zabbix_db_name }}

        else
          echo "ERROR: No se ha encontrado el esquema SQL de Zabbix."
          find /usr/share /usr/share/doc -iname "*.sql.gz" | grep -i zabbix || true
          exit 1
        fi
      when: zabbix_schema.stdout | int == 0

    - name: Comprobar version de la base de datos Zabbix
      shell: |
        mysql -e "SELECT mandatory, optional FROM {{ zabbix_db_name }}.dbversion;"
      changed_when: false

    - name: Configurar zabbix_server.conf
      lineinfile:
        path: /etc/zabbix/zabbix_server.conf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      loop:
        - { regexp: '^#?DBName=', line: 'DBName=zabbix' }
        - { regexp: '^#?DBUser=', line: 'DBUser=zabbix' }
        - { regexp: '^#?DBPassword=', line: 'DBPassword=zabbix' }
        - { regexp: '^#?AllowUnsupportedDBVersions=', line: 'AllowUnsupportedDBVersions=1' }
        - { regexp: '^#?PidFile=', line: 'PidFile=/run/zabbix/zabbix_server.pid' }
        - { regexp: '^#?LogFile=', line: 'LogFile=/var/log/zabbix/zabbix_server.log' }

    - name: Crear directorio web de Zabbix
      file:
        path: /etc/zabbix/web
        state: directory
        owner: www-data
        group: www-data
        mode: "0755"

    - name: Crear configuracion web de Zabbix
      copy:
        dest: /etc/zabbix/web/zabbix.conf.php
        owner: www-data
        group: www-data
        mode: "0640"
        content: |
          <?php
          $DB['TYPE']     = 'MYSQL';
          $DB['SERVER']   = 'localhost';
          $DB['PORT']     = '0';
          $DB['DATABASE'] = 'zabbix';
          $DB['USER']     = 'zabbix';
          $DB['PASSWORD'] = 'zabbix';

          $DB['SCHEMA'] = '';
          $DB['ENCRYPTION'] = false;
          $DB['KEY_FILE'] = '';
          $DB['CERT_FILE'] = '';
          $DB['CA_FILE'] = '';
          $DB['VERIFY_HOST'] = false;
          $DB['CIPHER_LIST'] = '';

          $ZBX_SERVER      = 'localhost';
          $ZBX_SERVER_PORT = '10051';
          $ZBX_SERVER_NAME = '{{ zabbix_server_name }}';

          $IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;

    - name: Copiar configuracion web a ruta alternativa de Zabbix
      copy:
        src: /etc/zabbix/web/zabbix.conf.php
        dest: /etc/zabbix/zabbix.conf.php
        remote_src: yes
        owner: www-data
        group: www-data
        mode: "0640"

    - name: Configurar zabbix-agent local en backend1
      lineinfile:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      loop:
        - { regexp: '^Server=', line: 'Server=127.0.0.1,10.10.10.20' }
        - { regexp: '^ServerActive=', line: 'ServerActive=127.0.0.1,10.10.10.20' }
        - { regexp: '^Hostname=', line: 'Hostname=Zabbix server' }
        - { regexp: '^#?ListenPort=', line: 'ListenPort=10050' }

    - name: Abrir puertos de Zabbix y Apache
      shell: |
        ufw allow 80/tcp || true
        ufw allow 443/tcp || true
        ufw allow 10051/tcp || true
        ufw allow 10050/tcp || true
        ufw reload || true
      ignore_errors: yes

    - name: Preparar directorios runtime/log de Zabbix
      shell: |
        install -d -m 0755 -o zabbix -g zabbix /run/zabbix
        install -d -m 0755 -o zabbix -g zabbix /var/log/zabbix

    - name: Crear configuracion Apache para Zabbix
      copy:
        dest: /etc/apache2/conf-available/zabbix.conf
        owner: root
        group: root
        mode: "0644"
        content: |
          Alias /zabbix /usr/share/zabbix

          <Directory /usr/share/zabbix>
              Options FollowSymLinks
              AllowOverride None
              Require all granted
          </Directory>

    - name: Activar configuracion Apache de Zabbix
      command: a2enconf zabbix
      register: zabbix_apache_conf
      changed_when: "'Enabling conf zabbix' in zabbix_apache_conf.stdout"
      failed_when: false

    - name: Configurar parametros PHP para Zabbix
      lineinfile:
        path: /etc/php/7.4/apache2/php.ini
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      loop:
        - { regexp: '^post_max_size =', line: 'post_max_size = 16M' }
        - { regexp: '^max_execution_time =', line: 'max_execution_time = 300' }
        - { regexp: '^max_input_time =', line: 'max_input_time = 300' }
        - { regexp: '^;?date.timezone =', line: 'date.timezone = Europe/Madrid' }

    - name: Instalar y generar locale en_US.UTF-8 para Zabbix
      shell: |
        locale-gen en_US.UTF-8
        update-locale LANG=en_US.UTF-8
      changed_when: false

    - name: Reiniciar servicios Zabbix y Apache
      service:
        name: "{{ item }}"
        state: restarted
        enabled: yes
      loop:
        - zabbix-server
        - zabbix-agent
        - apache2

    - name: Comprobar servicios
      shell: |
        systemctl is-active zabbix-server
        systemctl is-active zabbix-agent
        systemctl is-active apache2
        curl -I http://localhost/zabbix
      changed_when: false
PLAYBOOK_ZSERVER

cat > zabbix_agents.yml <<'PLAYBOOK_ZAGENTS'
---
- name: Instalar y configurar Zabbix Agent en nodos monitorizados
  hosts: zabbix_agent_nodes
  become: yes

  vars:
    zabbix_server_ip: "10.10.10.20"

  tasks:
    - name: Limpiar cache antigua de apt-cacher-ng en jumpstart
      shell: |
        systemctl stop apt-cacher-ng || true
        rm -rf /var/cache/apt-cacher-ng/*
        systemctl start apt-cacher-ng || true
      delegate_to: localhost
      become: yes
      run_once: true

    - name: Configurar proxy APT hacia jumpstart en backend2
      copy:
        dest: /etc/apt/apt.conf.d/01proxy
        content: |
          Acquire::http::Proxy "http://10.10.10.10:3142";
          Acquire::https::Proxy "false";
      when: inventory_hostname == "backend2"

    - name: Restaurar repositorios oficiales de Ubuntu en backend2
      copy:
        dest: /etc/apt/sources.list
        owner: root
        group: root
        mode: "0644"
        content: |
          deb http://es.archive.ubuntu.com/ubuntu focal main restricted universe multiverse
          deb http://es.archive.ubuntu.com/ubuntu focal-updates main restricted universe multiverse
          deb http://es.archive.ubuntu.com/ubuntu focal-backports main restricted universe multiverse
          deb http://es.archive.ubuntu.com/ubuntu focal-security main restricted universe multiverse
      when: inventory_hostname == "backend2"

    - name: Eliminar repositorio local de MariaDB en backend2
      file:
        path: /etc/apt/sources.list.d/mariadb-local.list
        state: absent
      when: inventory_hostname == "backend2"

    - name: Limpiar cache APT en backend2
      shell: |
        apt clean
        rm -rf /var/lib/apt/lists/*
        rm -rf /var/cache/apt/archives/partial/*
      when: inventory_hostname == "backend2"

    - name: Actualizar cache APT
      shell: |
        apt update
      register: apt_update_result
      retries: 3
      delay: 5
      until: apt_update_result.rc == 0

    - name: Instalar Zabbix Agent
      apt:
        name: zabbix-agent
        state: present

    - name: Configurar Server
      lineinfile:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: '^Server='
        line: "Server={{ zabbix_server_ip }}"

    - name: Configurar ServerActive
      lineinfile:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: '^ServerActive='
        line: "ServerActive={{ zabbix_server_ip }}"

    - name: Configurar Hostname
      lineinfile:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: '^Hostname='
        line: "Hostname={{ inventory_hostname }}"

    - name: Configurar ListenPort
      lineinfile:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: '^#?ListenPort='
        line: "ListenPort=10050"

    - name: Permitir Zabbix Agent en firewall
      shell: |
        ufw allow from {{ zabbix_server_ip }} to any port 10050 proto tcp || true
        ufw reload || true
      ignore_errors: yes

    - name: Reiniciar y habilitar Zabbix Agent
      service:
        name: zabbix-agent
        state: restarted
        enabled: yes

    - name: Comprobar estado del agente
      shell: systemctl is-active zabbix-agent
      register: agent_status
      changed_when: false

    - name: Mostrar resultado
      debug:
        msg: "{{ inventory_hostname }} -> zabbix-agent {{ agent_status.stdout }}"
PLAYBOOK_ZAGENTS
}

echo "=============================================="
echo " FASE 4: Despliegue completo con Ansible"
echo " Usuario VM: ${USUARIO_VM}"
echo "=============================================="
echo

echo "[1/8] Instalando herramientas en jumpstart..."
sudo apt update
sudo apt install ansible sshpass apt-rdepends dpkg-dev -y

echo
echo "[2/8] Creando inventario y playbooks temporales..."
write_inventory
write_playbooks
cat "$INVENTORY"

echo
echo "[3/8] Comprobando conectividad con backend1/backend2..."
ping -c 3 "$BACKEND1_IP"
ping -c 3 "$BACKEND2_IP"

echo
echo "[4/8] Probando Ansible..."
ASK_PASS=""
if ansible -i "$INVENTORY" backends -m ping; then
  echo "Ansible funciona con clave SSH."
else
  echo "No ha funcionado con clave SSH. Se usará -k."
  ASK_PASS="-k"
  ansible -i "$INVENTORY" backends -m ping $ASK_PASS
fi

echo
echo "[5/8] Preparando repositorio offline y desplegando Galera..."
ansible-playbook -i localhost, -c local preparar_jumpstart.yml -K
ansible-playbook -i "$INVENTORY" backend.yml --syntax-check
ansible-playbook -i "$INVENTORY" backend.yml $ASK_PASS -K

echo
echo "[6/8] Desplegando WordPress..."
ansible-playbook -i "$INVENTORY" frontend_wordpress.yml --syntax-check
ansible-playbook -i "$INVENTORY" frontend_wordpress.yml -K

echo
echo "[7/8] Desplegando Zabbix Server..."
ansible-playbook -i "$INVENTORY" zabbix_server_backend1.yml --syntax-check
ansible-playbook -i "$INVENTORY" zabbix_server_backend1.yml -K

echo
echo "[8/8] Desplegando agentes Zabbix..."
ansible-playbook -i "$INVENTORY" zabbix_agents.yml --syntax-check
ansible-playbook -i "$INVENTORY" zabbix_agents.yml -K

echo
echo "=============================================="
echo " FASE 4 completada correctamente"
echo "=============================================="
echo "Comprueba con: ./05_comprobar_despliegue.sh ${USUARIO_VM}"
echo "Zabbix: http://192.168.56.20/zabbix  Admin / zabbix"
