#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./preparar_ansible.sh <usuario_vm>"
  echo "Ejemplo: ./preparar_ansible.sh carlotamo"
  exit 1
fi

ANSIBLE_USER="$1"
SSH_KEY="$HOME/.ssh/id_ed25519"
INVENTORY="hosts.ini"

FRONTENDS=(
  "192.168.50.30"
  "192.168.50.31"
)

BACKENDS=(
  "10.10.10.10"
  "10.10.10.11"
)

BALANCEADOR=(
  "192.168.50.20"
)

ALL_NODES=(
  "${FRONTENDS[@]}"
  "${BACKENDS[@]}"
  "${BALANCEADOR[@]}"
)

echo "[1/5] Comprobando clave SSH..."

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ ! -f "$SSH_KEY" ]]; then
  echo "No existe clave SSH. Generando clave nueva..."
  ssh-keygen -t ed25519 -f "$SSH_KEY" -N ""
else
  echo "La clave SSH ya existe: $SSH_KEY"
fi

echo
echo "[2/5] Creando inventario Ansible: $INVENTORY"

cat > "$INVENTORY" <<EOF
[frontends]
frontend1 ansible_host=192.168.50.30
frontend2 ansible_host=192.168.50.31

[frontend]
frontend1 ansible_host=192.168.50.30
frontend2 ansible_host=192.168.50.31

[backends]
backend1 ansible_host=10.10.10.10
backend2 ansible_host=10.10.10.11

[backend]
backend1 ansible_host=10.10.10.10
backend2 ansible_host=10.10.10.11

[balanceador]
balanceador ansible_host=192.168.50.20

[all:vars]
ansible_user=${ANSIBLE_USER}
ansible_ssh_private_key_file=${SSH_KEY}
ansible_python_interpreter=/usr/bin/python3
EOF

echo "Inventario creado:"
cat "$INVENTORY"

echo
echo "[3/5] Copiando clave SSH a los nodos..."

for NODE in "${ALL_NODES[@]}"; do
  echo
  echo "Copiando clave a ${ANSIBLE_USER}@${NODE}..."

  ssh-keygen -R "$NODE" >/dev/null 2>&1 || true

  ssh-copy-id \
    -i "${SSH_KEY}.pub" \
    -o StrictHostKeyChecking=accept-new \
    "${ANSIBLE_USER}@${NODE}"
done

echo
echo "[4/5] Probando SSH sin contraseña..."

for NODE in "${ALL_NODES[@]}"; do
  echo "Probando SSH con ${NODE}..."
  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    "${ANSIBLE_USER}@${NODE}" \
    "hostname"
done

echo
echo "[5/5] Probando Ansible..."

ansible all -i "$INVENTORY" -m ping

echo
echo "Preparación de Ansible completada correctamente."
