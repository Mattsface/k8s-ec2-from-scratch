#!/bin/bash

# Script to scp certs to their locations
# WIP
CA_KEYS_DIR="ca-keys"
ADMIN_KEYS_DIR="admin-keys"
WORKER_KEYS_DIR="worker-keys"
KUBE_KEYS_DIR="kube-keys"
SERVICE_ACCOUNT_DIR="service-account-keys"

# TODO Add a indenty key, and update scp to accept finger print
# Send worker keys to workers
for INSTANCE in worker-0 worker-1 worker-2; do
    WORKER_EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    scp "${CA_KEYS_DIR}/ca.pem" "${WORKER_KEYS_DIR}/${INSTANCE}-key.pem" "${WORKER_KEYS_DIR}/${INSTANCE}.pem" ubuntu@${WORKER_EXTERNAL_IP}:~/
done

for INSTANCE in controller-0 controller-1 controller-2; do
    CONTROLLER_EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    scp "${CA_KEYS_DIR}/ca.pem" "${CA_KEYS_DIR}/ca-key.pem" "${KUBE_KEYS_DIR}/kubernetes-key.pem" "${KUBE_KEYS_DIR}/kubernetes.pem" "${SERVICE_ACCOUNT_DIR}/service-account-key.pem" "${SERVICE_ACCOUNT_DIR}/service-account.pem" ubuntu@${CONTROLLER_EXTERNAL_IP}:~/
done