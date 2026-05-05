# Guía de instalación: máquina base en UTM

Esta guía crea `base-ubuntu`, la máquina plantilla que después se clonará para `frontend1`, `frontend2`, `backend1`, `backend2`, `balanceador` y `jumpstart`.

## 1. Crear máquina virtual

Desde UTM:

- Pulsar `+`
- Elegir `Virtualize`
- Elegir `Linux`
- Usar una ISO de Ubuntu Server compatible con tu equipo
- Nombre: `base-ubuntu`

En Apple Silicon, usar Ubuntu Server ARM64.

## 2. Recursos

Configuración recomendada:

- RAM: `2 GB`
- CPU: `2`
- Disco: `20 GB`

## 3. Red inicial

Para la máquina base basta con una interfaz:

- Tipo: **Red compartida**
- Uso: salida a Internet durante la instalación

Las redes `main` e `internal` se añadirán después en cada clon.

## 4. Instalación de Ubuntu

Durante la instalación:

- elegir idioma y teclado
- usar DHCP en la red
- usar todo el disco
- crear el usuario del laboratorio
- activar `Install OpenSSH server`
- no instalar snaps si no son necesarios

Cuando termine, reiniciar la máquina.

## 5. Actualizar sistema

Entrar en la máquina y ejecutar:

```bash
sudo apt update
sudo apt upgrade -y
```

## 6. Comprobar SSH

```bash
sudo systemctl status ssh
```

Debe aparecer:

```bash
active (running)
```

Para salir de la vista del servicio, pulsar `q`.

## 7. Apagar y clonar

Apagar la máquina:

```bash
sudo poweroff
```

Después, en UTM, clonar `base-ubuntu` para crear las demás máquinas.

## 8. Siguiente paso

Crear las máquinas:

- `frontend1`
- `frontend2`
- `backend1`
- `backend2`
- `balanceador`
- `jumpstart`
