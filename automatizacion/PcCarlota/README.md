# Automatización para PcCarlota en UTM

Esta carpeta contiene la versión UTM de `automatizacion/VirtualBox`.

## Redes usadas

- Red compartida de UTM: salida a Internet por DHCP.
- Red `main`: `192.168.50.0/24`.
- Red `internal`: `10.10.10.0/24`.

En UTM normalmente las interfaces aparecen así:

- `enp0s1`: red compartida / NAT.
- `enp0s2`: segunda tarjeta, normalmente `main` o `internal` según la máquina.
- `enp0s3`: tercera tarjeta, normalmente `internal`.

Los scripts detectan las interfaces automáticamente usando la ruta por defecto para encontrar la red compartida. Aun así, conviene comprobar antes con:

```bash
ip a
ip route
```

## Plan de IPs

```text
jumpstart main     192.168.50.10
jumpstart internal 10.10.10.1
frontend1          192.168.50.30
frontend2          192.168.50.31
balanceador        192.168.50.20
backend1           10.10.10.10
backend2           10.10.10.11
router-linux main  192.168.50.254
router-linux int   10.10.10.254
VIP main           192.168.50.100
VIP internal       10.10.10.100
```

## Scripts

Ejecutar cada script dentro de su máquina correspondiente:

```bash
sudo ./scripts/configurar_jumpstart.sh jumpstart
sudo ./scripts/configurar_frontend.sh frontend1 192.168.50.30
sudo ./scripts/configurar_frontend.sh frontend2 192.168.50.31
sudo ./scripts/configurar_backend_red.sh backend1 10.10.10.10
sudo ./scripts/configurar_backend_red.sh backend2 10.10.10.11
sudo ./scripts/configurar_balanceador.sh balanceador
sudo ./scripts/configurar_router_linux.sh router-linux
```

Para preparar claves SSH e inventario desde `jumpstart`:

```bash
./scripts/preparar_ansible.sh carlotamo
```

Cambia `carlotamo` por tu usuario real si es distinto.

## Playbooks

Desde `jumpstart`:

```bash
ansible -i hosts.ini all -m ping
ansible-playbook -i hosts.ini playbooks/backend_nginx.yml -K
ansible-playbook playbooks/preparar_jumpstart.yml -K
ansible-playbook -i hosts.ini playbooks/backend.yml -K
ansible-playbook -i hosts.ini playbooks/frontend_wordpress.yml -K
```

Si todavía no has copiado claves SSH, añade `-k` para que Ansible pida contraseña SSH.
