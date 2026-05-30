# Datos de entrada del despliegue

Este documento recoge los valores que deben estar definidos antes de ejecutar el despliegue.

## Parametros generales

| Dato | Valor por defecto | Donde se usa |
| --- | --- | --- |
| Usuario de las VMs | `alejandroro` en el inventario; parametro `<usuario_vm>` en scripts | SSH, Ansible y claves |
| VM base | `base-ubuntu` si no se indica otra | Clonado de VMs con VirtualBox |
| Carpeta compartida para backends | `CompartidaVM` | Configuracion local de `backend1` y `backend2` |
| Interfaz host-only | `vboxnet0` | Acceso web a Zabbix desde el anfitrion |

## Redes

| Red | Prefijo | Nombre en VirtualBox | Uso |
| --- | --- | --- | --- |
| `main` | `10.0.0.0/24` | `main` | Balanceador, frontales, router y hot-desk |
| `internal` | `10.10.10.0/24` | `internal` | Backends, Zabbix y trafico interno |
| Host-only | `192.168.56.0/24` | `vboxnet0` | Acceso desde anfitrion a Zabbix |

## Direcciones IP

| Nodo | IP |
| --- | --- |
| `balanceador` | `10.0.0.1` |
| `frontend1` | `10.0.0.10` |
| `frontend2` | `10.0.0.11` |
| `router-linux` en `main` | `10.0.0.254` |
| `router-linux` en `internal` | `10.10.10.254` |
| `backend1` | `10.10.10.20` |
| `backend2` | `10.10.10.21` |
| Zabbix web host-only | `192.168.56.20` |
| VIP `main` | `10.0.0.100` |
| VIP `internal` | `10.10.10.100` |

## Puertos NAT del anfitrion

| VM | Puerto anfitrion | Puerto invitado | Uso |
| --- | ---: | ---: | --- |
| `frontend1` | `2210` | `22` | SSH temporal |
| `frontend2` | `2211` | `22` | SSH temporal |
| `jumpstart` | `2225` | `22` | SSH hacia administracion |
| `balanceador` | `2226` | `22` | SSH temporal |
| `router-linux` | `2227` | `22` | SSH temporal |
| `balanceador` | `8080` | `80` | Acceso HTTP al balanceador |

## Direcciones MAC

Las direcciones MAC no se fijan manualmente. Los scripts ejecutan `VBoxManage modifyvm ... --macaddressX auto` para regenerarlas al clonar cada VM.

Recomendacion de administracion:

- Mantener MAC automatica salvo que el profesor o el entorno de laboratorio exija reservas fijas.
- Si se fija una MAC, documentarla en esta tabla antes de la entrega.

| VM | Adaptador | Red | MAC |
| --- | --- | --- | --- |
| `jumpstart` | 1 | NAT | automatica |
| `jumpstart` | 2 | `main` | automatica |
| `jumpstart` | 3 | `internal` | automatica |
| `balanceador` | 1 | NAT | automatica |
| `balanceador` | 2 | `main` | automatica |
| `frontend1` | 1 | NAT | automatica |
| `frontend1` | 2 | `main` | automatica |
| `frontend2` | 1 | NAT | automatica |
| `frontend2` | 2 | `main` | automatica |
| `backend1` | 1 | `internal` | automatica |
| `backend1` | 2 | `vboxnet0` | automatica |
| `backend2` | 1 | `internal` | automatica |
| `router-linux` | 1 | NAT | automatica |
| `router-linux` | 2 | `main` | automatica |
| `router-linux` | 3 | `internal` | automatica |

## Credenciales y variables de aplicacion

| Servicio | Variable | Valor |
| --- | --- | --- |
| WordPress DB | Base de datos | `wordpress_db` |
| WordPress DB | Usuario | `wordpress_user` |
| WordPress DB | Contrasena | `wordpress_pass` |
| WordPress DB | Host | `10.10.10.20` |
| Zabbix Web | Usuario inicial | `Admin` |
| Zabbix Web | Contrasena inicial | `zabbix` |
| Zabbix DB | Base de datos | `zabbix` |
| Zabbix DB | Usuario | `zabbix` |
| Zabbix DB | Contrasena | `zabbix` |

## Archivos donde se modifican estos datos

- `Guia_de_instalacion/Instalacion/Archivos/01_crear_y_configurar_vms.sh`
- `Guia_de_instalacion/Scripts/hosts.ini`
- `automatizacion/hosts.ini`
- `automatizacion/templates/wp-config.php.j2`
- `automatizacion/playbooks/frontend_wordpress.yml`
- `automatizacion/playbooks/zabbix_server_backend1.yml`
- `automatizacion/playbooks/zabbix_agents.yml`
