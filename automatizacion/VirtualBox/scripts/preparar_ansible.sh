#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: ./preparar_ansible.sh <usuario_vm>"
  echo "Ejemplo: ./preparar_ansible.sh alumno"
  exit 1
fi

ANSIBLE_USER="$1"
SSH_KEY="$HOME/.ssh/id_ed25519"
INVENTORY="hosts.ini"

FRONTENDS=(
  "10.0.0.10"
  "10.0.0.11"
)

BACKENDS=(
  "10.10.10.20"
  "10.10.10.21"
)

ALL_NODES=(
  "${FRONTENDS[@]}"
  "${BACKENDS[@]}"
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
10.0.0.10
10.0.0.11

[backends]
10.10.10.20
10.10.10.21

[all:vars]
ansible_user=${ANSIBLE_USER}
ansible_ssh_private_key_file=${SSH_KEY}
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
