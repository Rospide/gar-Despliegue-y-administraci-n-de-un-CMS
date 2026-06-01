# Automatización para VirtualBox

Esta carpeta contiene los ficheros de automatización para las máquinas creadas en VirtualBox.

## Estructura 

| Ruta | Descripción |
|---|---|
| [`hosts.ini`](hosts.ini) | Inventario de Ansible para VirtualBox |
| [`base_de_datos/`](base_de_datos/) | Contiene playbooks centrados en la preparación y despliegue de la capa de base de datos con MariaDB Galera. |
| [`creacion_vm/`](creacion_vm/) | Contiene los scripts encargados de crear las máquinas virtuales a partir de una máquina base. |
| [`playbooks/`](playbooks/) | Contiene playbooks generales de Ansible utilizados para configurar servicios y nodos del entorno. |
| [`scripts/`](scripts/) | Contiene scripts para configurar red y hostname de `frontend1`, `frontend2` y `jumpstart` |
| [`templates/`](templates/) | Contiene plantillas utilizadas por Ansible. |


Interfaces habituales en VirtualBox:

- `enp0s3`: NAT
- `enp0s8`: red interna `main`
- `enp0s9`: red interna `internal`


