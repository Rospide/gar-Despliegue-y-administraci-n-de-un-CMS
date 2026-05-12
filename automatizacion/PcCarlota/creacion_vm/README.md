# Creación de máquinas en UTM

En `automatizacion/VirtualBox/creacion_vm` hay scripts basados en `VBoxManage`, que solo sirven para VirtualBox.

En UTM las máquinas se crean y clonan desde la interfaz gráfica:

1. Crear `base-ubuntu` con red compartida.
2. Apagar `base-ubuntu`.
3. Clonar la máquina para:
   - `frontend1`
   - `frontend2`
   - `backend1`
   - `backend2`
   - `balanceador`
   - `jumpstart`
   - `router-linux`
4. Añadir los adaptadores necesarios en cada clon.
5. Ejecutar dentro de cada VM el script correspondiente de `../scripts`.

Los scripts de configuración UTM están en:

```text
automatizacion/PcCarlota/scripts/
```

Las guías paso a paso están en:

```text
guia_instalacion/PcCarlota/
```
