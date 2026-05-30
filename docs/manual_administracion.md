# Manual de administracion

Este manual resume las operaciones principales para desplegar, revisar, ampliar y sustituir componentes de la infraestructura.

## Despliegue completo

Ejecutar desde la carpeta `Guia_de_instalacion/Instalacion/Archivos`.

1. Dar permisos a los scripts:

```bash
chmod +x *.sh
```

2. Crear y configurar las maquinas virtuales desde el PC anfitrion:

```bash
./01_crear_y_configurar_vms.sh <usuario_vm> <nombre_vm_base>
```

Si no se indica `<nombre_vm_base>`, se usa `base-ubuntu`.

3. Configurar `backend1` y `backend2` desde la consola de VirtualBox usando la carpeta compartida `CompartidaVM`:

```bash
sudo mkdir -p /mnt/compartida
sudo mount -t vboxsf CompartidaVM /mnt/compartida
bash /mnt/compartida/01_crear_y_configurar_vms.sh --backend1-local
```

En `backend2`:

```bash
sudo mkdir -p /mnt/compartida
sudo mount -t vboxsf CompartidaVM /mnt/compartida
bash /mnt/compartida/01_crear_y_configurar_vms.sh --backend2-local
```

4. Preparar `jumpstart` desde el anfitrion:

```bash
./02_preparar_jumpstart.sh <usuario_vm>
```

5. Entrar en `jumpstart`:

```bash
ssh -p 2225 <usuario_vm>@127.0.0.1
```

6. Ejecutar el despliegue de servicios:

```bash
./03_desplegar_todo.sh <usuario_vm>
```

7. Comprobar el despliegue:

```bash
./04_comprobar_despliegue.sh <usuario_vm>
```

8. Acceder a los servicios:

- WordPress por el balanceador: `http://127.0.0.1:8080` desde el anfitrion.
- Zabbix: `http://192.168.56.20/zabbix`.

## Examinar la monitorizacion

1. Abrir `http://192.168.56.20/zabbix`.
2. Entrar con `Admin` / `zabbix`.
3. Ir a `Monitoring -> Hosts` para comprobar el estado de los nodos monitorizados.
4. Revisar que aparecen al menos `frontend1`, `frontend2`, `backend2`, `balanceador` y `router-linux` como agentes.
5. Revisar `Monitoring -> Problems` para ver alertas activas.
6. Revisar `Monitoring -> Latest data` para consultar metricas recientes por host.

Comprobaciones desde consola:

```bash
systemctl status zabbix-server --no-pager
systemctl status zabbix-agent --no-pager
curl -I http://localhost/zabbix
```

En nodos monitorizados:

```bash
systemctl status zabbix-agent --no-pager
grep -E '^(Server|ServerActive|Hostname)=' /etc/zabbix/zabbix_agentd.conf
```

Si se anade un nodo nuevo, instalar `zabbix-agent`, configurar `Server=10.10.10.20` y `ServerActive=10.10.10.20`, abrir el puerto `10050/tcp` y crear el host correspondiente en la interfaz de Zabbix.

## Ampliar puestos hot-desk

Los puestos hot-desk deben conectarse a la red `main` (`10.0.0.0/24`).

Pasos recomendados:

1. Crear o clonar la VM del nuevo puesto.
2. Conectar su adaptador de red a la red interna `main`.
3. Asignar una IP libre dentro de `10.0.0.0/24`, evitando las direcciones ya usadas:
   - `10.0.0.1` balanceador
   - `10.0.0.10` y `10.0.0.11` frontales
   - `10.0.0.100` VIP de encaminamiento
   - `10.0.0.254` router
4. Configurar la puerta de enlace hacia el router/VIP definido para la red `main`.
5. Comprobar conectividad:

```bash
ping 10.0.0.1
ping 10.0.0.10
curl -I http://10.0.0.1
```

6. Si el puesto debe estar monitorizado, instalar `zabbix-agent`, configurar el servidor Zabbix `10.10.10.20` y anadirlo en la interfaz web.

## Sustituir o aumentar frontales web

Para sustituir un frontal existente:

1. Crear la nueva VM desde la base.
2. Conectarla a NAT y a la red interna `main`.
3. Asignarle el hostname del frontal sustituido o uno nuevo si se esta ampliando.
4. Configurar una IP libre en `10.0.0.0/24`.
5. Asegurar la ruta hacia `10.10.10.0/24` usando `10.0.0.100`.
6. Anadir o actualizar el nodo en `automatizacion/hosts.ini` y `Guia_de_instalacion/Scripts/hosts.ini`.
7. Ejecutar el playbook de WordPress:

```bash
ansible-playbook -i automatizacion/hosts.ini automatizacion/playbooks/frontend_wordpress.yml -K
```

8. Editar la configuracion de Nginx en el balanceador para incluir o sustituir el servidor en el bloque `upstream wordpress_frontends`.
9. Validar y recargar Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

10. Instalar o actualizar el agente Zabbix del nuevo frontal.
11. Comprobar balanceo:

```bash
curl -I http://10.0.0.1
curl -I http://127.0.0.1:8080
```

## Sustituir o aumentar nodos de base de datos

Para sustituir `backend1` o `backend2`:

1. Crear la nueva VM desde la base.
2. Conectarla a la red interna `internal`.
3. Configurar IP y hostname. Si sustituye a un nodo, reutilizar su IP para no cambiar `wsrep_cluster_address`.
4. Configurar la ruta hacia `10.0.0.0/24` usando `10.10.10.100`.
5. Actualizar los inventarios si cambia el nombre o la IP:
   - `automatizacion/hosts.ini`
   - `Guia_de_instalacion/Scripts/hosts.ini`
6. Si el nodo sustituido tenia datos corruptos, ejecutar el playbook de limpieza:

```bash
ansible-playbook -i automatizacion/hosts.ini automatizacion/playbooks/limpiar_galera_backends.yml -K
```

7. Ejecutar el playbook de backend/Galera:

```bash
ansible-playbook -i automatizacion/hosts.ini automatizacion/playbooks/backend.yml -K
```

8. Comprobar el estado del cluster:

```bash
sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
sudo mysql -e "SHOW STATUS LIKE 'wsrep_ready';"
```

Para aumentar el numero de nodos:

1. Reservar una nueva IP en `10.10.10.0/24`.
2. Anadir el host al grupo `[backends]` del inventario.
3. Actualizar la plantilla de Galera para incluir la nueva IP en `wsrep_cluster_address`.
4. Ejecutar el playbook de backend.
5. Confirmar que `wsrep_cluster_size` aumenta al numero esperado.
6. Instalar el agente Zabbix y anadir el host al panel.

## Comprobaciones operativas

Servicios principales:

```bash
systemctl status apache2 --no-pager
systemctl status nginx --no-pager
systemctl status mariadb --no-pager
systemctl status zabbix-server --no-pager
systemctl status zabbix-agent --no-pager
```

Red y rutas:

```bash
ip -br a
ip route
ping 10.0.0.1
ping 10.10.10.20
```

WordPress y balanceador:

```bash
curl -I http://10.0.0.10
curl -I http://10.0.0.11
curl -I http://10.0.0.1
```
