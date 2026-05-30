# Scripts

Esta carpeta contiene los scripts, playbooks e inventario usados por la guía final de instalación.

Contenido principal:

- Scripts `crear_*`: creación de máquinas virtuales.
- Scripts `configurar_*`: configuración de red, hostname y servicios base.
- Scripts `fase*`: ejecución agrupada de fases del despliegue.
- Playbooks `.yml`: automatización con Ansible para backends, frontends, Zabbix y tareas auxiliares.
- `hosts.ini`: inventario de Ansible usado por los playbooks.
- Scripts de comprobación y reparación, como `comprobar_despliegue_final.sh`, `probar_balanceador.sh`, `reset_fase4.sh` y `reparar_zabbix_db.sh`.

Estos archivos están pensados para ejecutarse siguiendo el orden indicado en `Guia_de_instalacion/Instalacion/Pasos.md`.
