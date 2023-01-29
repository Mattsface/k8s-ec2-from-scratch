#!/bin/bash


# script to provision configs for worker nodes
# WIP

# Config dirs
WORKERS_CONFIG_DIR="workers"
KUBE_PROXY_DIR="kube-proxy"
KUBE_CONTROLLER_DIR="kube-controller"
KUBE_SCHEDULE_DIR="kube-scheduler"
ADMIN_DIR="admin"

# WIP TODO Clean up pathing
CA_KEYS_DIR="../certs/ca-keys"
ADMIN_KEYS_DIR="../certs/admin-keys"
WORKER_KEYS_DIR="../certs/worker-keys"
KUBE_KEYS_DIR="../certs/kube-keys"
SERVICE_ACCOUNT_DIR="../certs/service-account-keys"

if [ ! -d "${WORKERS_CONFIG_DIR}" ]; then
    mkdir "${WORKERS_CONFIG_DIR}"
fi

if [ ! -d "${KUBE_PROXY_DIR}" ]; then
    mkdir "${KUBE_PROXY_DIR}"
fi 

if [ ! -d "${KUBE_CONTROLLER_DIR}" ]; then
    mkdir "${KUBE_CONTROLLER_DIR}"
fi

if [ ! -d "${KUBE_SCHEDULE_DIR}" ]; then
    mkdir "${KUBE_SCHEDULE_DIR}"
fi

if [ ! -d "${ADMIN_DIR}" ]; then
    mkdir "${ADMIN_DIR}"
fi

KUBE_LB_DNS=$(aws elbv2 describe-load-balancers --names k8s-nlb --output text --query 'LoadBalancers[].DNSName')

# worker configs
for INSTANCE in worker-0 worker-1 worker-2; do
    kubectl config set-cluster kubernetes-from-scratch --certificate-authority="${CA_KEYS_DIR}/ca.pem" --embed-certs="true" --server="https://${KUBE_LB_DNS}:443" --kubeconfig="${WORKERS_CONFIG_DIR}/${INSTANCE}.kubeconfig"
    kubectl config set-credentials "system:node:${INSTANCE}" --client-certificate="${WORKER_KEYS_DIR}/${INSTANCE}.pem" --client-key="${WORKER_KEYS_DIR}/${INSTANCE}-key.pem" --embed-certs="true" --kubeconfig="${WORKERS_CONFIG_DIR}/${INSTANCE}.kubeconfig"
    kubectl config set-context default --cluster="kubernetes-from-scratch" --user="system:node:${INSTANCE}" --kubeconfig="${WORKERS_CONFIG_DIR}/${INSTANCE}.kubeconfig"
    kubectl config use-context default --kubeconfig="${WORKERS_CONFIG_DIR}/${INSTANCE}.kubeconfig"
done

# kube-proxy
kubectl config set-cluster "kubernetes-from-scratch" --certificate-authority="${CA_KEYS_DIR}/ca.pem" --embed-certs="true" --server="https://${KUBE_LB_DNS}:443" --kubeconfig="${KUBE_PROXY_DIR}/kube-proxy.kubeconfig"
kubectl config set-credentials "system:kube-proxy" --client-certificate="${KUBE_KEYS_DIR}/kube-proxy.pem" --client-key="${KUBE_KEYS_DIR}/kube-proxy-key.pem" --embed-certs="true" --kubeconfig="${KUBE_PROXY_DIR}/kube-proxy.kubeconfig"
kubectl config set-context "default" --cluster="kubernetes-from-scratch" --user="system:kube-proxy" --kubeconfig="${KUBE_PROXY_DIR}/kube-proxy.kubeconfig"
kubectl config use-context "default" --kubeconfig="${KUBE_PROXY_DIR}/kube-proxy.kubeconfig"

# kube-controller
kubectl config set-cluster "kubernetes-from-scratch" --certificate-authority="${CA_KEYS_DIR}/ca.pem" --embed-certs="true" --server="https://127.0.0.1:6443" --kubeconfig="${KUBE_CONTROLLER_DIR}/kube-controller-manager.kubeconfig"
kubectl config set-credentials "system:kube-controller-manager" --client-certificate="${KUBE_KEYS_DIR}/kube-controller-manager.pem" --client-key="${KUBE_KEYS_DIR}/kube-controller-manager-key.pem" --embed-certs="true" --kubeconfig="${KUBE_CONTROLLER_DIR}/kube-controller-manager.kubeconfig"
kubectl config set-context "default" --cluster="kubernetes-from-scratch" --user="system:kube-controller-manager" --kubeconfig="${KUBE_CONTROLLER_DIR}/kube-controller-manager.kubeconfig"
kubectl config use-context "default" --kubeconfig="${KUBE_CONTROLLER_DIR}/kube-controller-manager.kubeconfig"

# kube-scheduler
kubectl config set-cluster "kubernetes-from-scratch" --certificate-authority="${CA_KEYS_DIR}/ca.pem" --embed-certs="true" --server="https://127.0.0.1:6443" --kubeconfig="${KUBE_SCHEDULE_DIR}/kube-scheduler.kubeconfig"
kubectl config set-credentials "system:kube-scheduler" --client-certificate="${KUBE_KEYS_DIR}/kube-scheduler.pem" --client-key="${KUBE_KEYS_DIR}/kube-scheduler-key.pem" --embed-certs="true" --kubeconfig="${KUBE_SCHEDULE_DIR}/kube-scheduler.kubeconfig"
kubectl config set-context "default" --cluster="kubernetes-from-scratch" --user="system:kube-scheduler" --kubeconfig="${KUBE_SCHEDULE_DIR}/kube-scheduler.kubeconfig"
kubectl config use-context "default" --kubeconfig="${KUBE_SCHEDULE_DIR}/kube-scheduler.kubeconfig"

# kube admin
kubectl config set-cluster "kubernetes-from-scratch" --certificate-authority="${CA_KEYS_DIR}/ca.pem" --embed-certs="true" --server="https://127.0.0.1:6443" --kubeconfig="${ADMIN_DIR}/admin.kubeconfig"
kubectl config set-credentials "admin" --client-certificate="${ADMIN_KEYS_DIR}/admin.pem" --client-key="${ADMIN_KEYS_DIR}/admin-key.pem" --embed-certs="true" --kubeconfig="${ADMIN_DIR}/admin.kubeconfig"
kubectl config set-context "default" --cluster="kubernetes-from-scratch" --user="admin" --kubeconfig="${ADMIN_DIR}/admin.kubeconfig"
kubectl config use-context "default" --kubeconfig="${ADMIN_DIR}/admin.kubeconfig"


# TODO add scp key
# TODO Add console output 

# scp configs to worker and controller nodes
for INSTANCE in worker-0 worker-1 worker-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    if ! scp "${ADMIN_DIR}/admin.kubeconfig" "${WORKERS_CONFIG_DIR}/${INSTANCE}.kubeconfig" "${KUBE_PROXY_DIR}/kube-proxy.kubeconfig" ubuntu@${EXTERNAL_IP}:~/; then
        echo "Failed to scp configs to ${INSTANCE}"
        exit 1
    fi
done

for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    if ! scp "${ADMIN_DIR}/admin.kubeconfig" "${KUBE_CONTROLLER_DIR}/kube-controller-manager.kubeconfig" "${KUBE_SCHEDULE_DIR}/kube-scheduler.kubeconfig" ubuntu@${EXTERNAL_IP}:~/; then
        echo "Failed to scp configs to ${INSTANCE}"
        exit 1
    fi
done

