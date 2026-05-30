# Arquitectura de red

La infraestructura se divide en dos redes internas de VirtualBox y una red host-only para acceder a Zabbix desde el PC anfitrion.

## Redes

| Red | Prefijo | Uso |
| --- | --- | --- |
| `main` | `10.0.0.0/24` | Balanceador, frontales web, router y puestos hot-desk |
| `internal` | `10.10.10.0/24` | Backends, Galera, Zabbix y trafico interno |
| `vboxnet0` | `192.168.56.0/24` | Acceso desde el anfitrion a la interfaz web de Zabbix |

## Direccionamiento

| Nodo | Red `main` | Red `internal` | Host-only | Funcion |
| --- | --- | --- | --- | --- |
| `jumpstart` | DHCP/NAT + acceso a `main` | acceso a `internal` | - | Administracion y ejecucion de Ansible |
| `balanceador` | `10.0.0.1` | - | - | Balanceo HTTP hacia frontales |
| `frontend1` | `10.0.0.10` | ruta hacia `internal` | - | Servidor web WordPress |
| `frontend2` | `10.0.0.11` | ruta hacia `internal` | - | Servidor web WordPress |
| `router-linux` | `10.0.0.254` | `10.10.10.254` | - | Encaminamiento entre redes |
| `backend1` | ruta hacia `main` | `10.10.10.20` | `192.168.56.20` | MariaDB Galera y Zabbix Server |
| `backend2` | ruta hacia `main` | `10.10.10.21` | - | MariaDB Galera |

## VIP y rutas

| Elemento | Direccion | Uso |
| --- | --- | --- |
| `VIP_MAIN` | `10.0.0.100` | Siguiente salto desde `main` hacia `internal` |
| `VIP_INTERNAL` | `10.10.10.100` | Siguiente salto desde `internal` hacia `main` |

Rutas principales:

- Frontales y balanceador alcanzan `10.10.10.0/24` usando `10.0.0.100`.
- Backends alcanzan `10.0.0.0/24` usando `10.10.10.100`.
- `router-linux` tiene interfaces en `main` e `internal` y tiene activado `net.ipv4.ip_forward=1`.
- `backend1` expone Zabbix por la red host-only en `http://192.168.56.20/zabbix`.

## Diagrama de conexiones

```mermaid
flowchart LR
    Host["PC anfitrion<br/>192.168.56.1"] --- ZabbixWeb["backend1 host-only<br/>192.168.56.20<br/>Zabbix Web"]

    subgraph Main["Red main - 10.0.0.0/24"]
        LB["balanceador<br/>10.0.0.1<br/>Nginx"]
        FE1["frontend1<br/>10.0.0.10<br/>Apache + WordPress"]
        FE2["frontend2<br/>10.0.0.11<br/>Apache + WordPress"]
        RMain["router-linux<br/>10.0.0.254<br/>VIP 10.0.0.100"]
        HotDesk["puestos hot-desk<br/>rango reservado"]
    end

    subgraph Internal["Red internal - 10.10.10.0/24"]
        RInternal["router-linux<br/>10.10.10.254<br/>VIP 10.10.10.100"]
        BE1["backend1<br/>10.10.10.20<br/>MariaDB Galera + Zabbix Server"]
        BE2["backend2<br/>10.10.10.21<br/>MariaDB Galera"]
    end

    LB --> FE1
    LB --> FE2
    FE1 --> BE1
    FE2 --> BE1
    BE1 <--> BE2
    RMain <--> RInternal
    FE1 -. ruta a 10.10.10.0/24 .-> RMain
    FE2 -. ruta a 10.10.10.0/24 .-> RMain
    BE1 -. ruta a 10.0.0.0/24 .-> RInternal
    BE2 -. ruta a 10.0.0.0/24 .-> RInternal
```
