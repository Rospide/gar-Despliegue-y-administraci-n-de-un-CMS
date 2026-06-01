# Guía de instalación

Esta carpeta contiene la guía final preparada para la entrega del proyecto.

Su objetivo es reunir una versión ordenada del proceso de despliegue, con los pasos principales y los archivos necesarios para ejecutar la instalación de forma guiada.

## Contenido

| Ruta | Descripción |
|---|---|
| [`Instalacion/`](Instalacion/) | Guía resumida por fases para ejecutar el despliegue final. |
| [`Instalacion/Archivos/`](Instalacion/Archivos/) | Scripts principales numerados para crear VMs, preparar `jumpstart`, desplegar servicios y comprobar el resultado. |
| [`Scripts/`](Scripts/) | Scripts auxiliares, playbooks e inventario usados durante la instalación. |
| [`creacion_manual/`](creacion_manual/) | Guías manuales detalladas para crear y configurar cada máquina o servicio paso a paso. |

## Orden recomendado

| Paso | Documento o carpeta | Uso |
|---:|---|---|
| 1 | [`../docs/datos_entrada.md`](../docs/datos_entrada.md) | Revisar redes, IPs, puertos y credenciales. |
| 2 | [`Instalacion/Pasos.md`](Instalacion/Pasos.md) | Seguir el despliegue automatizado. |
| 3 | [`creacion_manual/`](creacion_manual/) | Usar como apoyo cuando sea necesario revisar la configuración detallada de una máquina. |
| 4 | [`../docs/manual_administracion.md`](../docs/manual_administracion.md) | Consultar mantenimiento, monitorización y ampliaciones. |
