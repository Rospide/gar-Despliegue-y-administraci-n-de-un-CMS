## Justificación
Se han definido dos redes privadas independientes del entorno del laboratorio:
- main, para balanceador, frontales web y puestos hot-desk
- internal, para base de datos, monitorización y servicios internos

Estas redes no dependen de la red del servidor del laboratorio (172.20.48.0/24), evitando conflictos y permitiendo un control completo de la infraestructura.

## Redes
- main: 192.168.50.0/24
- internal: 10.10.10.0/24

## Propuesta de IPs
- jumpstart: 192.168.50.10
- balanceador: 192.168.50.20
- frontend1: 192.168.50.30
- frontend2: 192.168.50.31
- hotdesk1-8: 192.168.50.100-107

- backend1: 10.10.10.10
- backend2: 10.10.10.11
- master1: 10.10.10.12
- master2: 10.10.10.13
- worker1: 10.10.10.14
- worker2: 10.10.10.15
- monitor: 10.10.10.20
