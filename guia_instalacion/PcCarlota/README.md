# Guías para PcCarlota en UTM

Esta carpeta contiene las guías adaptadas para las máquinas de PcCarlota usando UTM.

Usa estas guías si estás montando el laboratorio en UTM:

- `base_utm.md`
- `frontend1_utm.md`
- `frontend2_utm.md`
- `backend1_utm.md`
- `backend2_utm.md`
- `balanceador_utm.md`
- `jumpstart_utm.md`
- `router-linux_utm.md`
- `instalacion_baseDatos_utm.md`

Las redes esperadas en UTM son:

- `Red compartida` para salida a Internet
- `Sólo host` para la red `main`
- `Sólo host` para la red `internal`

No mezclar estas guías con las de la carpeta `VirtualBox`, porque cambian los adaptadores y los nombres habituales de interfaz.

Equivalencias principales de red:

- En VirtualBox se usan nombres típicos como `enp0s3`, `enp0s8` y `enp0s9`.
- En UTM normalmente se usan `enp0s1`, `enp0s2` y `enp0s3`.
- Comprueba siempre los nombres reales con `ip a` antes de aplicar un netplan.

Plan de IPs usado en PcCarlota:

- `jumpstart`: `192.168.50.10` en `main` y `10.10.10.1` en `internal`
- `frontend1`: `192.168.50.30`
- `frontend2`: `192.168.50.31`
- `balanceador`: `192.168.50.20`
- `backend1`: `10.10.10.10`
- `backend2`: `10.10.10.11`
- `router-linux`: `192.168.50.254` en `main` y `10.10.10.254` en `internal`
