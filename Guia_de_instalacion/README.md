# Guia de instalacion

Esta carpeta contiene la guía final preparada para la entrega del proyecto.

Su objetivo es reunir una versión ordenada del proceso de despliegue, con los pasos principales y los archivos necesarios para ejecutar la instalación de forma guiada.

## Contenido

- `Instalacion/`: guía resumida por fases para ejecutar el despliegue final.
- `Instalacion/Archivos/`: scripts principales numerados para crear VMs, preparar `jumpstart`, desplegar servicios y comprobar el resultado.
- `Scripts/`: scripts auxiliares, playbooks e inventario usados durante la instalación.
- `creacion_manual/`: guías manuales detalladas para crear y configurar cada máquina o servicio paso a paso.

## Orden recomendado

1. Revisar `../docs/datos_entrada.md` para conocer redes, IPs, puertos y credenciales.
2. Seguir `Instalacion/Pasos.md` si se quiere hacer el despliegue automatizado.
3. Usar `creacion_manual/` como apoyo cuando sea necesario revisar la configuración detallada de una máquina.
4. Consultar `../docs/manual_administracion.md` para mantenimiento, monitorización y ampliaciones.
