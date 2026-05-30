# Inventario comun de Ansible

El archivo `hosts.ini` es el inventario común que debe usarse con Ansible según la configuración acordada por el grupo.

El inventario sigue la misma estructura que `automatizacion/hosts.ini`:

- `frontends`: servidores WordPress.
- `backends`: nodos MariaDB Galera.
- `infra`: balanceador y router Linux.
- `zabbix_server`: nodo que aloja Zabbix Server.
- `zabbix_agent_nodes`: nodos monitorizados con Zabbix Agent.

Actualmente usa el usuario Ansible `alejandroro` y la clave `/home/alejandroro/.ssh/id_ed25519`.

Comprobación desde `jumpstart`:

```bash
ansible all -i inventario/hosts.ini -m ping
```
