#!/bin/bash

# BASH script to build certs for k8s deployment


# VARS
# cert and key dirs
CA_KEYS_DIR="ca-keys"
ADMIN_KEYS_DIR="admin-keys"
WORKER_KEYS_DIR="worker-keys"
KUBE_KEYS_DIR="kube-keys"
SERVICE_ACCOUNT_DIR="service-account-keys"

# CA config
CA_CONFIG="ca-config.json"

# CSRS
CSR_DIR="csrs"
ADMIN_CSR="${CSR_DIR}/admin-csr.json"
CA_CSR="${CSR_DIR}/ca-csr.json"
KUBE_CONTROLLER_CSR="${CSR_DIR}/kube-controller-manager-csr.json"
KUBE_PROXY_CSR="${CSR_DIR}/kube-proxy-csr.json"
KUBE_SCHEDULER_CSR="${CSR_DIR}/kube-scheduler-csr.json"
KUBE_CSR="$CSR_DIR/kubernetes-csr.json"
SERVER_ACCOUNT_CSR="$CSR_DIR/kube-service-account-csr.json"

# Host names

# Create key and cert dirs
if [ ! -d ${CA_KEYS_DIR} ]; then
    mkdir "${CA_KEYS_DIR}"
fi

if [ ! -d ${ADMIN_KEYS_DIR} ]; then
    mkdir "${ADMIN_KEYS_DIR}"
fi

if [ ! -d ${WORKER_KEYS_DIR} ]; then
    mkdir "${WORKER_KEYS_DIR}"
fi

if [ ! -d ${KUBE_KEYS_DIR} ]; then
    mkdir "${KUBE_KEYS_DIR}"
fi

if [ ! -d ${SERVICE_ACCOUNT_DIR} ]; then
    mkdir ${SERVICE_ACCOUNT_DIR}
fi

# generate certs
if [ -f "${CA_CSR}" ]; then
    cfssl gencert -initca ${CA_CSR} | cfssljson -bare "${CA_KEYS_DIR}/ca"
fi

if [ -f "${ADMIN_CSR}" ] && [ -f "${CA_CONFIG}" ]; then
    cfssl gencert -ca="${CA_KEYS_DIR}/ca.pem" -ca-key="${CA_KEYS_DIR}/ca-key.pem" -config="${CA_CONFIG}" -profile=kubernetes "${ADMIN_CSR}" | cfssljson -bare "${ADMIN_KEYS_DIR}/admin"
fi

for i in 0 1 2; do
    if [ -f "${CSR_DIR}/${i}-csr.json" ] && [ -f "$CA_CONFIG" ]; then
        INSTANCE="worker-${i}"
        INSTANCE_HOSTNAME="ip-10-0-1-2${i}"
        EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
        INTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PrivateIpAddress')
        cfssl gencert -ca="${CA_KEYS_DIR}/ca.pem" -ca-key="${CA_KEYS_DIR}/ca-key.pem" -config="${CA_CONFIG}" -hostname=${INSTANCE_HOSTNAME},${EXTERNAL_IP},${INTERNAL_IP} -profile=kubernetes "${CSR_DIR}/${i}-csr.json" | cfssljson -bare "${WORKER_KEYS_DIR}/worker-${i}"
    fi
done

if [ -f "${KUBE_CONTROLLER_CSR}" ]; then
    cfssl gencert -ca="${CA_KEYS_DIR}/ca.pem" -ca-key="${CA_KEYS_DIR}/ca-key.pem" -config="${CA_CONFIG}" -profile="kubernetes" "${KUBE_CONTROLLER_CSR}" | cfssljson -bare "${KUBE_KEYS_DIR}/kube-controller-manager"
fi

if [ -f "${KUBE_PROXY_CSR}" ]; then
    cfssl gencert -ca="${CA_KEYS_DIR}/ca.pem" -ca-key="${CA_KEYS_DIR}/ca-key.pem" -config="${CA_CONFIG}" -profile="kubernetes" "${KUBE_PROXY_CSR}" | cfssljson -bare "${KUBE_KEYS_DIR}/kube-proxy"
fi

if [ -f "${KUBE_SCHEDULER_CSR}" ]; then
    cfssl gencert -ca="${CA_KEYS_DIR}/ca.pem" -ca-key="${CA_KEYS_DIR}/ca-key.pem" -config="${CA_CONFIG}" -profile="kubernetes" "${KUBE_SCHEDULER_CSR}" | cfssljson -bare "${KUBE_KEYS_DIR}/kube-scheduler"
fi

if [ -f "${KUBE_CSR}" ]; then
    KUBE_LB_DNS=$(aws elbv2 describe-load-balancers --names k8s-nlb --output text --query 'LoadBalancers[].DNSName')
    KUBERNETES_HOSTNAMES="kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local"

    cfssl gencert -ca="${CA_KEYS_DIR}/ca.pem" -ca-key="${CA_KEYS_DIR}/ca-key.pem" -config="${CA_CONFIG}" -hostname=10.32.0.1,10.0.1.10,10.0.1.11,10.0.1.12,${KUBE_LB_DNS},127.0.0.1,${KUBERNETES_HOSTNAMES} -profile="kubernetes" "${KUBE_CSR}" | cfssljson -bare "${KUBE_KEYS_DIR}/kubernetes"
fi

if [ -f "${SERVER_ACCOUNT_CSR}" ]; then
    cfssl gencert -ca="${CA_KEYS_DIR}/ca.pem" -ca-key="${CA_KEYS_DIR}/ca-key.pem" -config="${CA_CONFIG}" -profile=kubernetes ${SERVER_ACCOUNT_CSR} | cfssljson -bare "${SERVICE_ACCOUNT_DIR}/service-account"
fi