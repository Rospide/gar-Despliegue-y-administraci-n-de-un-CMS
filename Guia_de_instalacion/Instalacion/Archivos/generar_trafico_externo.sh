#!/usr/bin/env bash

PETICIONES=30
URL="http://127.0.0.1:8080/wp-admin/install.php"

echo "=========================================="
echo " Generando tráfico externo"
echo " URL: $URL"
echo " Peticiones: $PETICIONES"
echo "=========================================="
echo

for i in $(seq 1 $PETICIONES); do
    curl -s "$URL" > /dev/null

    if [ $? -eq 0 ]; then
        echo "Petición externa $i OK"
    else
        echo "Petición externa $i ERROR"
    fi

    sleep 1
done

echo
echo "TrafficMix externo terminado."
