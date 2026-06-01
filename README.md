<div align="center">
  <img src="https://capman.es/sites/default/files/styles/large/public/images/centers/logos/logo_uclm_0.png?itok=vPHw4UqY" alt="Logo de la UCLM" width="350">
</div>

---

# Despliegue y administración de un CMS

Este proyecto documenta y automatiza el despliegue de una infraestructura completa para alojar un CMS WordPress en alta disponibilidad dentro de un entorno de laboratorio con VirtualBox.

Incluye la creación y configuración de máquinas virtuales, el despliegue de servicios web y de base de datos, la configuración de un balanceador de carga, la monitorización del entorno y la automatización de tareas mediante scripts y playbooks de Ansible.

---

<div align="center">

  <a href="#participantes">
    <img src="https://img.shields.io/badge/Participantes-01-blue?style=for-the-badge" alt="Participantes">
  </a>

  <a href="#descripción-de-la-infraestructura">
    <img src="https://img.shields.io/badge/Descripci%C3%B3n%20de%20la%20infraestructura-02-green?style=for-the-badge" alt="Descripción de la infraestructura">
  </a>

  <a href="#estructura-del-repositorio">
    <img src="https://img.shields.io/badge/Estructura%20del%20repositorio-03-orange?style=for-the-badge" alt="Estructura del repositorio">
  </a>

  <br>

  <a href="#documentación-de-entrega">
    <img src="https://img.shields.io/badge/Documentaci%C3%B3n%20de%20entrega-04-red?style=for-the-badge" alt="Documentación de entrega">
  </a>

  <a href="#flujo-general-de-despliegue">
    <img src="https://img.shields.io/badge/Flujo%20general%20de%20despliegue-05-purple?style=for-the-badge" alt="Flujo general de despliegue">
  </a>

  <a href="#tecnologías-utilizadas">
    <img src="https://img.shields.io/badge/Tecnolog%C3%ADas%20utilizadas-06-lightgrey?style=for-the-badge" alt="Tecnologías utilizadas">
  </a>

</div>
   
## 1. Participantes

| Nº | Nombre |
|---:|---|
| 1 | Sandra Rodriguez Sánchez-Gil |
| 2 | Alonso Antonio Zamora Zamora |
| 3 | Steven Tipantuña Aquieta |
| 4 | Alejandro Rospide Álvarez |
| 5 | Carlota Moreno Tirado |

## 2. Descripción de la infraestructura

La infraestructura desplegada está formada por los siguientes nodos y servicios:

| Elemento | Descripción |
|---|---|
| `jumpstart` | Máquina de administración desde la que se ejecutan los despliegues y tareas de configuración. |
| `frontend1` y `frontend2` | Servidores web encargados de alojar WordPress. |
| `Balanceador` | Nodo con Nginx encargado de repartir el tráfico entre los servidores frontales. |
| `backend1` y `backend2` | Nodos de base de datos configurados con MariaDB Galera para proporcionar replicación. |
| `Zabbix` | Sistema de monitorización del entorno, compuesto por servidor y agentes. |
| `Ansible` | Herramienta utilizada para automatizar la configuración y el despliegue de servicios. |

## 3. Estructura del repositorio

| Ruta | Contenido |
|---|---|
| [`Guia_de_instalacion/Instalacion/`](Guia_de_instalacion/Instalacion/) | Guía resumida del despliegue final y scripts principales organizados por fases. |
| [`Guia_de_instalacion/Scripts/`](Guia_de_instalacion/Scripts/) | Scripts y playbooks preparados para copiar o ejecutar durante la instalación. |
| [`Guia_de_instalacion/creacion_manual/`](Guia_de_instalacion/creacion_manual/) | Guías manuales de creación y configuración por máquina o servicio. |
| [`automatizacion/`](automatizacion/) | Inventario, scripts, plantillas y playbooks de Ansible utilizados en la automatización. |
| [`docs/`](docs/) | Documentación de entrega, arquitectura, datos de entrada, administración y software base. |
| [`inventario/`](inventario/) | Inventario base del laboratorio. |

## 4. Documentación de entrega

| Documento | Descripción |
|---|---|
| [`docs/datos_entrada.md`](docs/datos_entrada.md) | Prefijos de red, direcciones IP, puertos NAT, direcciones MAC, credenciales y variables necesarias para configurar el despliegue. |
| [`docs/arquitectura.md`](docs/arquitectura.md) | Diagrama de conexiones, redes y rutas de los nodos. |
| [`docs/manual_administracion.md`](docs/manual_administracion.md) | Pasos de despliegue, monitorización, ampliación de hot-desk, sustitución o ampliación de frontales y nodos de base de datos. |
| [`docs/software_baseline.md`](docs/software_baseline.md) | Software utilizado, versiones objetivo, origen y comandos para registrar las versiones reales. |

## 5. Flujo general de despliegue

1. Crear las máquinas virtuales a partir de una máquina base.
2. Configurar las interfaces de red, nombres de host y accesos SSH.
3. Preparar el nodo `jumpstart` con las herramientas necesarias para administrar el entorno.
4. Desplegar MariaDB Galera en los nodos backend.
5. Desplegar WordPress en los nodos frontend.
6. Configurar el balanceador con Nginx para exponer el servicio.
7. Instalar y configurar Zabbix para monitorizar los nodos.
8. Verificar el acceso a WordPress, el balanceo de carga y el estado de la monitorización.

## 6. Tecnologías utilizadas

| Tecnología | Uso principal |
|---|---|
| VirtualBox | Creación y gestión de máquinas virtuales. |
| Ubuntu Server | Sistema operativo base de los nodos. |
| Bash | Automatización mediante scripts. |
| Ansible | Despliegue y configuración automatizada. |
| MariaDB Galera | Base de datos replicada en alta disponibilidad. |
| WordPress | CMS desplegado en los servidores frontales. |
| Nginx | Balanceo de carga entre los servidores web. |
| Zabbix | Monitorización de la infraestructura. |
