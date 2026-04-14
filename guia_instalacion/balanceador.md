CLONAR IGUAL QUE LAS ANTERIORES LA MAQUINA



Adaptador 2 (RED INTERNA)
Tipo: Red interna
Nombre: internal
3. Configuración de red en Ubuntu

Editar netplan:

sudo nano /etc/netplan/00-installer-config.yaml

Configurar:



network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: yes

    enp0s8:
      dhcp4: no
      addresses:
        - 10.10.10.30/24




Aplicar cambios:

sudo netplan apply

Comprobar:

ip a
4. Comprobación de conectividad

Verificar conexión con los backends:

ping 10.10.10.20
ping 10.10.10.21
5. Instalación de Nginx
sudo apt update
sudo apt install nginx -y
6. Configuración del balanceador

Editar archivo:

sudo nano /etc/nginx/sites-available/default

Contenido:

upstream backend_servers {
    server 10.10.10.20;
    server 10.10.10.21;
}

server {
    listen 80;

    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
7. Verificación de configuración
sudo nginx -t
8. Reinicio del servicio
sudo systemctl restart nginx
9. Prueba de funcionamiento
curl http://localhost

Debe alternar entre los servidores backend:

SOY BACKEND1
SOY BACKEND2
10. Conclusión

El balanceador queda configurado como punto de entrada al sistema, permitiendo distribuir el tráfico entre los nodos backend de la red interna sin exponerlos directamente.
