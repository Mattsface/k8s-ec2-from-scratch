#!/bin/bash

# BASH script to build certs for k8s deployment

# CSR locations
ADMIN_CSR="admin-csr.json"
CA_CSR="ca-csr.json"
CA_CONFIG="ca-config.json"
WORKER_CSRS=("0-csr.json" "1-csr.json" "2-csr.json")

if [ -f "$CA_CSR" ]; then
    cfssl gencert -initca ca-csr.json | cfssljson -bare ca
fi

if [ -f "$ADMIN_CSR" ] && [ -f "$CA_CONFIG" ]; then
    cfssl gencert -ca="ca.pem" -ca-key="ca-key.pem" -config="$CA_CONFIG" -profile=kubernetes "$ADMIN_CSR" | cfssljson -bare admin
fi

for WORKER_CSR in "${WORKER_CSRS[@]}"; do
    if [ -f "$WORKER_CSR" ]; then
        echo "$WORKER_CSR"
    fi
done