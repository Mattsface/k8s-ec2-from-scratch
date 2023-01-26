#!/bin/bash

# TODO Add a y/n prompt 


CERTS_DIR="certs"
CONFIGS_DIR="configs"

# Certs
if [ -d "${CERTS_DIR}/admin-keys" ]; then
    rm -r "${CERTS_DIR}/admin-keys"
fi

if [ -d "${CERTS_DIR}/ca-keys" ]; then
    rm -r "${CERTS_DIR}/ca-keys"
fi

if [ -d "${CERTS_DIR}/kube-keys" ]; then
    rm -r "${CERTS_DIR}/kube-keys"
fi

if [ -d "${CERTS_DIR}/worker-keys" ]; then
    rm -r "${CERTS_DIR}/worker-keys"
fi

if [ -d "${CERTS_DIR}/service-account-keys" ]; then
    rm -r "${CERTS_DIR}/service-account-keys"
fi

# Configs
if [ -d "${CONFIGS_DIR}/workers" ]; then
    rm -r "${CONFIGS_DIR}/workers"
fi

if [ -d "${CONFIGS_DIR}/kube-proxy" ]; then
    rm -r "${CONFIGS_DIR}/kube-proxy"
fi

if [ -d "${CONFIGS_DIR}/kube-controller" ]; then
    rm -r "${CONFIGS_DIR}/kube-controller"
fi

if [ -d "${CONFIGS_DIR}/kube-scheduler" ]; then
    rm -r "${CONFIGS_DIR}/kube-scheduler"
fi

if [ -d "${CONFIGS_DIR}/admin" ]; then
    rm -rf "${CONFIGS_DIR}/admin"
fi

