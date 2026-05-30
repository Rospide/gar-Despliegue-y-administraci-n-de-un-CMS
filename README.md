# Despliegue y administración de un CMS

Este proyecto documenta y automatiza el despliegue de una infraestructura completa para alojar un CMS WordPress en alta disponibilidad dentro de un entorno de laboratorio con VirtualBox.

La infraestructura incluye:

- Un nodo `jumpstart` usado como máquina de administración y punto desde el que se ejecutan los despliegues.
- Dos frontales web, `frontend1` y `frontend2`, que sirven WordPress.
- Un balanceador con Nginx para repartir el tráfico entre los frontales.
- Dos nodos backend con MariaDB Galera para la base de datos replicada.
- Monitorización con Zabbix Server y agentes en las máquinas del entorno.
- Scripts y playbooks de Ansible para reducir la configuración manual y facilitar la repetición del despliegue.

## Estructura del repositorio

- `Guia_de_instalacion/Instalacion/`: guía resumida de despliegue final y scripts principales por fases.
- `Guia_de_instalacion/Scripts/`: scripts y playbooks preparados para copiar o ejecutar durante la instalación.
- `automatizacion/`: inventario, scripts, plantillas y playbooks de Ansible usados por la automatización.
- `guia_instalacion/`: guías detalladas de instalación y configuración por máquina o servicio.
- `docs/`: documentación de entrega, arquitectura, datos de entrada, administración y software baseline.
- `inventario/`: inventario base del laboratorio.

## Documentación de entrega

- `docs/datos_entrada.md`: prefijos de red, IPs, puertos NAT, MACs, credenciales y variables necesarias para configurar el despliegue.
- `docs/arquitectura.md`: diagrama de conexiones, redes y rutas de los nodos.
- `docs/manual_administracion.md`: pasos de despliegue, monitorización, ampliación de hot-desk, sustitución/ampliación de frontales y nodos de base de datos.
- `docs/software_baseline.md`: lista del software utilizado, versiones objetivo, origen y comandos para registrar versiones reales.

## Flujo general de despliegue

1. Crear las máquinas virtuales desde una VM base.
2. Configurar las interfaces de red, hostnames y accesos SSH.
3. Preparar `jumpstart` con las herramientas necesarias para administrar el entorno.
4. Desplegar MariaDB Galera en los backends.
5. Desplegar WordPress en los frontends.
6. Configurar el balanceador para exponer el servicio.
7. Instalar Zabbix y comprobar el estado de los nodos.
8. Verificar el acceso a WordPress, el balanceo y la monitorización.

## Tecnologías usadas

- VirtualBox
- Ubuntu Server
- Bash
- Ansible
- MariaDB Galera
- WordPress
- Nginx
- Zabbix

## Participantes

- Sandra Rodriguez Sánchez-Gil
- Alonso Antonio Zamora Zamora
- Steven Tipantuña Aquieta
- Alejandro Rospide Álvarez
- Carlota Moreno Tirado
