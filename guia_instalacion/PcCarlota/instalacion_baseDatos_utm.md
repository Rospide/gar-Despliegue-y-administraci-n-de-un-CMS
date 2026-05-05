# Cluster de Base de Datos en UTM

Esta guía resume cómo continuar con el despliegue de MariaDB Galera en `backend1` y `backend2` usando UTM.

La parte de base de datos la harán tus compañeros, así que aquí solo se deja preparado lo necesario desde el punto de vista de red, SSH e inventario.

## 1. Requisitos previos

Antes de ejecutar los playbooks de base de datos:

- `backend1` debe tener `10.10.10.10/24`
- `backend2` debe tener `10.10.10.11/24`
- `jumpstart` debe tener `192.168.50.10/24` en `main`
- `jumpstart` debe tener `10.10.10.1/24` en `internal`
- debe haber conectividad por ping entre `jumpstart`, `backend1` y `backend2`
- SSH debe funcionar desde `jumpstart` hacia los backends

## 2. Inventario común

Usar el inventario común del grupo:

```bash
inventario/hosts.ini
```

Debe contener, como mínimo:

```ini
[backend]
backend1 ansible_host=10.10.10.10
backend2 ansible_host=10.10.10.11
```

## 3. Comprobar conectividad desde `jumpstart`

```bash
ping -c 4 10.10.10.10
ping -c 4 10.10.10.11
ssh alejandroro@10.10.10.10
ssh alejandroro@10.10.10.11
```

Para salir de cada SSH:

```bash
exit
```

## 4. Comprobar Ansible

Desde `jumpstart`:

```bash
ansible backend -i inventario/hosts.ini -m ping
```

Debe devolver:

```bash
SUCCESS
"ping": "pong"
```

## 5. Ejecución del despliegue

Cuando tus compañeros tengan listos los playbooks de base de datos, se ejecutarán desde `jumpstart`.

La guía original de VirtualBox usa comandos de este estilo:

```bash
ansible-playbook preparar_jumpstart.yml -K
ansible-playbook -i hosts.ini backend.yml -u TU_USUARIO -k -K
```

En UTM no cambia la lógica de Ansible. Lo importante es que las IPs, SSH y el inventario sean correctos.

## 6. Verificación del cluster

En `backend1` o `backend2`:

```bash
sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
```

El resultado esperado, cuando el cluster esté bien, es tamaño `2`.
