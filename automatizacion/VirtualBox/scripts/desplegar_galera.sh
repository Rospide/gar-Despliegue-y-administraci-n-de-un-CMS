#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./desplegar_galera.sh <usuario_vm>"
  echo "Ejemplo: ./desplegar_galera.sh alejandroro"
  exit 1
fi

USUARIO_VM="$1"

FRONTEND1_IP="10.0.0.10"
FRONTEND2_IP="10.0.0.11"
BACKEND1_IP="10.10.10.20"
BACKEND2_IP="10.10.10.21"
BALANCEADOR_IP="10.0.0.1"
ROUTER_LINUX_IP="10.0.0.254"

INVENTORY="hosts.ini"
PREP_PLAYBOOK="preparar_jumpstart.yml"
BACKEND_PLAYBOOK="backend.yml"

echo "=========================================="
echo " Despliegue automático de MariaDB Galera"
echo "=========================================="
echo
echo "Usuario VM: ${USUARIO_VM}"
echo "Frontend1: ${FRONTEND1_IP}"
echo "Frontend2: ${FRONTEND2_IP}"
echo "Backend1: ${BACKEND1_IP}"
echo "Backend2: ${BACKEND2_IP}"
echo "Balanceador: ${BALANCEADOR_IP}"
echo "Router-Linux: ${ROUTER_LINUX_IP}"
echo

echo "[1/9] Comprobando que estamos en jumpstart..."
hostname

echo
echo "[2/9] Instalando herramientas necesarias en jumpstart..."
sudo apt update
sudo apt install ansible sshpass apt-rdepends dpkg-dev -y

echo
echo "[3/9] Comprobando conectividad con backend1 y backend2..."
ping -c 3 "${BACKEND1_IP}"
ping -c 3 "${BACKEND2_IP}"

echo
echo "[4/9] Creando hosts.ini completo..."

cat > "${INVENTORY}" <<EOF
[frontends]
frontend1 ansible_host=${FRONTEND1_IP}
frontend2 ansible_host=${FRONTEND2_IP}

[backends]
backend1 ansible_host=${BACKEND1_IP}
backend2 ansible_host=${BACKEND2_IP}

[infra]
balanceador ansible_host=${BALANCEADOR_IP}
router-linux ansible_host=${ROUTER_LINUX_IP}

[zabbix_server]
backend1 ansible_host=${BACKEND1_IP}

[zabbix_agent_nodes]
frontend1 ansible_host=${FRONTEND1_IP}
frontend2 ansible_host=${FRONTEND2_IP}
backend2 ansible_host=${BACKEND2_IP}
balanceador ansible_host=${BALANCEADOR_IP}
router-linux ansible_host=${ROUTER_LINUX_IP}

[all:vars]
ansible_user=${USUARIO_VM}
ansible_ssh_private_key_file=/home/${USUARIO_VM}/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
EOF

cat "${INVENTORY}"

echo
echo "[5/9] Comprobando que existen los playbooks..."

if [[ ! -f "${PREP_PLAYBOOK}" ]]; then
  echo "ERROR: No existe ${PREP_PLAYBOOK}"
  exit 1
fi

if [[ ! -f "${BACKEND_PLAYBOOK}" ]]; then
  echo "ERROR: No existe ${BACKEND_PLAYBOOK}"
  exit 1
fi

ls -l "${PREP_PLAYBOOK}" "${BACKEND_PLAYBOOK}"

echo
echo "[6/9] Probando Ansible con clave SSH..."

ASK_PASS=""

if ansible -i "${INVENTORY}" backends -m ping; then
  echo "Ansible funciona con clave SSH."
else
  echo
  echo "No ha funcionado con clave SSH."
  echo "Se usará contraseña SSH con -k."
  ASK_PASS="-k"
  ansible -i "${INVENTORY}" backends -m ping ${ASK_PASS}
fi

echo
echo "[7/9] Preparando repositorio offline en jumpstart..."
ansible-playbook -i localhost, -c local "${PREP_PLAYBOOK}" -K

echo
echo "Comprobando repositorio offline..."

REPO_DIR="/home/${USUARIO_VM}/mariadb_offline"
TEMPLATE_FILE="/home/${USUARIO_VM}/template/60-galera.cnf.j2"

ls -lh "${REPO_DIR}/Packages.gz"
ls -lh "${TEMPLATE_FILE}"

ls -lh "${REPO_DIR}"/libhtml-parser-perl*.deb
ls -lh "${REPO_DIR}"/libcgi-pm-perl*.deb
ls -lh "${REPO_DIR}"/libhtml-template-perl*.deb
ls -lh "${REPO_DIR}"/libcgi-fast-perl*.deb

echo
echo "[8/9] Comprobando sintaxis de backend.yml..."
ansible-playbook -i "${INVENTORY}" "${BACKEND_PLAYBOOK}" --syntax-check

echo
echo "[9/9] Desplegando MariaDB Galera en los backends..."
ansible-playbook -i "${INVENTORY}" "${BACKEND_PLAYBOOK}" ${ASK_PASS} -K

echo
echo "=========================================="
echo " Despliegue terminado"
echo "=========================================="
echo
echo "Comprobaciones:"
echo
echo "ssh ${USUARIO_VM}@${BACKEND1_IP}"
echo "sudo mysql -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\""
echo "sudo mysql -e \"SHOW STATUS LIKE 'wsrep_cluster_status';\""
echo "sudo mysql -e \"SHOW STATUS LIKE 'wsrep_ready';\""
echo
echo "Comprobar que hosts.ini conserva todos los grupos:"
echo "ansible -i hosts.ini all -m ping"
echo
echo "Resultado esperado:"
echo "wsrep_cluster_size = 2"
echo "wsrep_cluster_status = Primary"
echo "wsrep_ready = ON"
