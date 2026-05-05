# Inventario común de Ansible

El archivo `hosts.ini` es el inventario común que debe usarse con Ansible según la configuración acordada por el grupo.

Actualmente usa:

```ini
ansible_user=alejandroro
```

Comprobación desde `jumpstart`:

```bash
ansible all -i inventario/hosts.ini -m ping
```
