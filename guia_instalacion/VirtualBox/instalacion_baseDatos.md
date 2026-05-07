# Cluster de Base de Datos (Backend1 y Backend2)

Esta guía detalla el proceso para desplegar el cluster de MariaDB Galera utilizando Ansible. Es fundamental que las conexiones entre **backend1**, **backend2** y **jumpstart** sean correctas antes de empezar.

---

## 📋 Requisitos Previos Generales

Para que la instalación sea exitosa, se deben cumplir estrictamente los siguientes puntos:

1.  **Configuración de Máquinas:** Haber completado los pasos previos de instalación y configuración de cada máquina (`backend1`, `backend2` y `jumpstart`).
2.  **Conectividad:** Las tres máquinas deben tener visibilidad total entre ellas (comprobar mediante `ping`).
3.  **SSH:** Tener configurado el acceso SSH y el archivo `hosts.ini` correctamente.

### Configuración del Inventario (`hosts.ini`)
El archivo `hosts.ini` debe seguir esta estructura estrictamente, sustituyendo las IPs por las correspondientes a cada entorno:
```
[backends]
backend1 ansible_host=10.10.10.20
backend2 ansible_host=10.10.10.21
```

<img width="895" height="419" alt="imagen" src="https://github.com/user-attachments/assets/0ef4dac0-4286-4018-8d11-7e20250082f2" />

---

Donde backend1 y backend2 es el nombre de la máquina, todos tenemos que seguir de manera estricta los pasos anteriores de instalacion y configuracion de cada maquina (en este caso backend1 backend2 y jumpstart).

Tienen que hacer ping entre ellos y bien configurada como se ha indicado en las instalaciones de las máquinas.

---

# 💻 Acceso a Jumpstart

En jumpstart usa el comando que veras a continuación, pero con tu usuario correspondiente:

<img width="710" height="78" alt="imagen" src="https://github.com/user-attachments/assets/7bcc6ff2-1839-4e2b-8f6a-9f2ee12bde4b" />

Una vez dentro comprueba que se ven estos dos scripts:

<img width="710" height="78" alt="imagen" src="https://github.com/user-attachments/assets/910c9ef2-4942-42c1-a3a3-ae498e44c34b" />

Comprueba que dentro tienes estos dos archivos:

<img width="667" height="75" alt="imagen" src="https://github.com/user-attachments/assets/9e24aac4-0a89-45f6-8dc6-9b8bb584ecb4" />

## Instalación de Ansible (Solo en Jumpstart)

Comprobar que estáis fuera del tbworkers para realizar lo que viene a continuación. 

Ansible no viene instalado por defecto en Ubuntu. Debes instalarlo **únicamente en la máquina Jumpstart**, ya que es desde donde controlaremos a los backends.

Ejecuta estos comandos en tu Jumpstart:
```
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y
```

## ⚙️ Paso 2: Ejecución del Despliegue

Sigue este orden exacto para evitar errores de dependencias o permisos:

### A. Preparar el Entorno Local

Este comando instalará las herramientas necesarias (como sshpass) y descargará los paquetes necesarios para la instalación offline.
Bash
```
ansible-playbook preparar_jumpstart.yml -K
```

<img width="1331" height="740" alt="imagen" src="https://github.com/user-attachments/assets/2d273300-b19c-4507-81fb-c2bd4a7e0900" />


    Nota: La opción -K te pedirá la contraseña de sudo (Become password).

### B. Instalar y Configurar el Cluster

Este comando ejecutará la instalación de MariaDB y la configuración de Galera en los backends.
Bash
```
ansible-playbook -i hosts.ini backend.yml -u TU_USUARIO -k -K

```


    -u TU_USUARIO: El usuario que usas para conectar a los backends.

    -k: Te pedirá la contraseña de SSH.

    -K: Te pedirá la contraseña de sudo.

Una vez salga todo correcto

<img width="1000" height="412" alt="imagen" src="https://github.com/user-attachments/assets/e960ee46-5365-40ef-af69-940f6f29592f" />


### Verificar el Cluster (En cualquier Backend)

Entra en backend1 o backend2 (da igual cual, están sincronizados) y ejecuta el siguiente comando para comprobar el tamaño del cluster:

```
sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
```
Resultado esperado:
Si todo está bien, deberías ver un valor de 2, tanto como en el backend1 y backend2:

<img width="1000" height="412" alt="imagen" src="https://github.com/user-attachments/assets/ed79ccbd-db85-4fec-ba01-2cf97a09cb49" />

---

> [!CAUTION]
> ### ⚠️ ADVERTENCIA
> **Cualquier duda o error, contactad conmigo.** 
>
> Cuando realicé las pruebas el despliegue me salio de manera correcta; sin embargo, debido a la gran cantidad de comandos, es posible que algún detalle se haya escapado en la automatización final.
