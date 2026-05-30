# Archivos

Esta carpeta agrupa los scripts principales de la instalación final.

Los scripts están numerados para indicar el orden de ejecución:

- `01_crear_y_configurar_vms.sh`: crea las máquinas virtuales y configura la parte inicial del entorno.
- `02_preparar_jumpstart.sh`: prepara la máquina `jumpstart` para ejecutar la automatización.
- `03_desplegar_todo.sh`: despliega Galera, WordPress, Zabbix y los agentes necesarios.
- `04_comprobar_despliegue.sh`: verifica el estado del despliegue y comprueba los servicios.
- `reset_fase4.sh`: limpia estados parciales si hay que repetir la fase de despliegue.

Antes de ejecutarlos, dar permisos con:

```bash
chmod +x *.sh
```
