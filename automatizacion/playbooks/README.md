# playbooks

Esta carpeta contiene los playbooks de Ansible usados para automatizar la configuración de servicios.

Contenido:

- `preparar_jumpstart.yml`: preparación inicial de `jumpstart`.
- `backend.yml`: configuración de backends y MariaDB Galera.
- `backend_nginx.yml`: configuración auxiliar de Nginx en backend cuando corresponde.
- `frontend_wordpress.yml`: instalación y configuración de WordPress en los frontends.
- `zabbix_server_backend1.yml`: instalación del servidor Zabbix.
- `zabbix_agents.yml`: despliegue de agentes Zabbix en las máquinas.
- `configurar_apt_proxy_backends.yml`: configuración de proxy o repositorio para paquetes en backends.
- `limpiar_bloqueos_apt.yml`: limpieza de bloqueos de `apt`.
- `limpiar_galera_backends.yml`: limpieza de estados previos de Galera.

Estos playbooks se ejecutan con el inventario `automatizacion/hosts.ini`.
