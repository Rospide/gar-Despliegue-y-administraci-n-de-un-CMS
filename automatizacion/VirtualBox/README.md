# Automatización para VirtualBox

Esta carpeta contiene los ficheros de automatización para las máquinas creadas en VirtualBox.

Estructura:

- `hosts.ini`: inventario de Ansible para VirtualBox
- `scripts/`: scripts para configurar red y hostname de `frontend1`, `frontend2` y `jumpstart`
- `playbooks/`: playbooks de Ansible
- `templates/`: plantillas usadas por Ansible

Interfaces habituales en VirtualBox:

- `enp0s3`: NAT
- `enp0s8`: red interna `main`
- `enp0s9`: red interna `internal`

No mezclar esta carpeta con `automatizacion/PcCarlota`, porque esa está pensada para UTM.
