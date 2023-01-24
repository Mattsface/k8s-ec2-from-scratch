#!/bin/bash

# BASH script to build certs for k8s deployment

# CSR locations
ADMIN_CSR="admin-csr.json"
CA_CSR="ca-csr.json"
CA_CONFIG="ca-config.json"
KUBE_CONTROLLER_CSR="kube-controller-manager-csr.json"
KUBE_PROXY_CSR="kube-proxy-csr.json"
KUBE_SCHEDULER_CSR="kube-scheduler-csr.json"

# TODO: add folders to hold different certs
if [ -f "$CA_CSR" ]; then
    cfssl gencert -initca ca-csr.json | cfssljson -bare ca
fi

if [ -f "$ADMIN_CSR" ] && [ -f "$CA_CONFIG" ]; then
    cfssl gencert -ca="ca.pem" -ca-key="ca-key.pem" -config="$CA_CONFIG" -profile=kubernetes "$ADMIN_CSR" | cfssljson -bare admin
fi

for i in 0 1 2; do
    if [ -f "${i}-csr.json" ]; then
        INSTANCE="worker-${i}"
        INSTANCE_HOSTNAME="ip-10-0-1-2${i}"
        EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
        INTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PrivateIpAddress')
        cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${INSTANCE_HOSTNAME},${EXTERNAL_IP},${INTERNAL_IP} -profile=kubernetes ${i}-csr.json | cfssljson -bare worker-${i}
    fi
done

if [ -f "$KUBE_CONTROLLER_CSR" ]; then
    cfssl gencert -ca="ca.pem" -ca-key=ca-key.pem -config="ca-config.json" -profile="kubernetes" "$KUBE_CONTROLLER_CSR" | cfssljson -bare kube-controller-manager
fi

if [ -f "$KUBE_PROXY_CSR" ]; then
    cfssl gencert -ca="ca.pem" -ca-key="ca-key.pem" -config="ca-config.json" -profile="kubernetes" "$KUBE_PROXY_CSR" | cfssljson -bare kube-proxy
fi

if [ -f "$KUBE_SCHEDULER_CSR"]; then
    cfssl gencert -ca="ca.pem" -ca-key="ca-key.pem" -config="ca-config.json" -profile="kubernetes" "$KUBE_SCHEDULER_CSR" | cfssljson -bare kube-scheduler
fi