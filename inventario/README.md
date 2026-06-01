# Inventario común de Ansible

---

El archivo [`hosts.ini`](hosts.ini) es el inventario común que debe usarse con Ansible según la configuración acordada por el grupo.

El inventario sigue la misma estructura que [`automatizacion/hosts.ini`](../automatizacion/hosts.ini):

## Estructura del inventario

| Grupo | Descripción |
|---|---|
| `frontends` | servidores WordPress. |
| `backends` | nodos MariaDB Galera. |
| `infra` | balanceador y router Linux. |
| `zabbix_server` | nodo que aloja Zabbix Server. |
| `zabbix_agent_nodes` | nodos monitorizados con Zabbix Agent. |

## Configuración actual

| Parámetro | Valor |
|---|---|
| Usuario Ansible | `alejandroro` |
| Clave SSH | `/home/alejandroro/.ssh/id_ed25519` |

## Comprobación desde `jumpstart`

```bash
ansible all -i inventario/hosts.ini -m ping
