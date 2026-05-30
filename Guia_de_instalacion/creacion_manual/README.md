# Creacion manual

Esta carpeta contiene las guías manuales detalladas para montar el laboratorio en VirtualBox.

Se mantienen como documentación de apoyo al despliegue automatizado. Son útiles para revisar cómo se configuró cada máquina, repetir una parte concreta a mano o resolver incidencias.

## Orden recomendado de lectura

1. `base.md`: creación de la VM base.
2. `Router-Linux.md`: configuración del router Linux y encaminamiento.
3. `jumpstart.md`: preparación de la máquina de administración.
4. `backend1.md` y `backend2.md`: configuración de backends.
5. `instalacion_baseDatos.md` o `instalacion_basededatos_rospide.md`: despliegue de MariaDB Galera.
6. `frontend1.md` y `frontend2.md`: configuración de frontales WordPress.
7. `balanceador.md`: configuración del balanceador.
8. `zabbix.md`: instalación y revisión de monitorización.

## Guías por máquina

- `base.md`
- `jumpstart.md`
- `Router-Linux.md`
- `balanceador.md`
- `frontend1.md`
- `frontend2.md`
- `backend1.md`
- `backend2.md`

## Guías por servicio

- `instalacion_baseDatos.md`
- `instalacion_basededatos_rospide.md`
- `zabbix.md`

## Guías antiguas por VM

- `maquinas_virtuales/`: documentación más extensa de configuración inicial máquina por máquina.

Estas guías usan conceptos propios de VirtualBox, como `NAT`, `Red interna`, red host-only y redirección de puertos.
