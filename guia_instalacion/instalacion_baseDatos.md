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

<img width="896" height="468" alt="imagen" src="https://github.com/user-attachments/assets/72072daf-b7b5-4bee-9e09-d73f73021a35" />


---

Donde backend1 y backend2 es el nombre de la máquina, todos tenemos que seguir de manera estricta los pasos anteriores de instalacion y configuracion de cada maquina (en este caso backend1 backend2 y jumpstart).

Tienen que hacer ping entre ellos y bien configurada como se ha indicado en las instalaciones de las máquinas.

---

# 💻 Acceso a Jumpstart

En jumpstart usa el comando que veras a continuación, pero con tu usuario correspondiente:

<img width="710" height="78" alt="imagen" src="https://github.com/user-attachments/assets/7bcc6ff2-1839-4e2b-8f6a-9f2ee12bde4b" />

Comprueba que se ven estos dos scripts:

<img width="995" height="85" alt="imagen" src="https://github.com/user-attachments/assets/e5914335-dc0f-45f4-9bec-0c4f2787c705" />


## Llevar los ejecutables desde servidor a máquina local

Desde la maquina virtual local, con el * es para llevar al local todo lo que tienes dentro del servidor: scp -r tuUsuario@tbworkers4.esi.uclm.es:~/* .

POr ejemplo:

```
scp -r sandraro@tbworkers4.esi.uclm.es:~/* .
```
Una vez lo ejecutas vuelve a LOCAL y comprueba que tienes los archivos "preparar_jumpstart.yml y backend.yml"


<img width="995" height="107" alt="imagen" src="https://github.com/user-attachments/assets/d9bec42d-d592-4210-94ea-1c739642fb63" />

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

Si no os sale verde, como en mi captura, y os sale amarillo no pasa nada, es porque lo estáis ejecutando por primera vez. 

```
ansible-playbook preparar_jumpstart.yml -K
```

<img width="1247" height="677" alt="imagen" src="https://github.com/user-attachments/assets/b3e723d9-9f58-4ef3-889f-dfb7b3e95344" />



    Nota: La opción -K te pedirá la contraseña de sudo (Become password).

### B. Instalar y Configurar el Cluster

Este comando ejecutará la instalación de MariaDB y la configuración de Galera en los backends.
Bash
```
ansible-playbook -i hosts.ini backend.yml -K

```
    -K: Te pedirá la contraseña de sudo.

Una vez salga todo correcto

<img width="1254" height="873" alt="imagen" src="https://github.com/user-attachments/assets/9e2bc85d-5045-4a95-8d7c-bff8a857ff3f" />



### Verificar el Cluster (En cualquier Backend)

Entra en backend1 o backend2 (da igual cual, están sincronizados) y ejecuta el siguiente comando para comprobar el tamaño del cluster:

```
sudo mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
```
Resultado esperado:
Si todo está bien, deberías ver un valor de 2, tanto como en el backend1 y backend2:

<img width="624" height="135" alt="imagen" src="https://github.com/user-attachments/assets/e6b8a78a-f936-4076-af40-474438b24314" />


### Verificar que está todo correcto

Ejecuta esto en cualquiera de los dos backends, si te sale lo mismo que aquí, HAS TERMINADO!!

<img width="808" height="428" alt="imagen" src="https://github.com/user-attachments/assets/67d8d672-560f-42c1-9e25-34bf6c8dd8a4" />

---

> [!CAUTION]
> ### ⚠️ ADVERTENCIA
> **Cualquier duda o error, contactad conmigo.** 
>
> Cuando realicé las pruebas el despliegue me salio de manera correcta; sin embargo, debido a la gran cantidad de comandos, es posible que algún detalle se haya escapado en la automatización final.
