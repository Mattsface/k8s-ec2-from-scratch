#!/bin/bash

for INSTANCE in worker-0 worker-1 worker-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    if ! scp "scripts/configure_worker.sh" ubuntu@${EXTERNAL_IP}:~/; then
        echo "failed to scp configure_worker.sh to ${INSTANCE}"
    fi
    ssh ubuntu@$EXTERNAL_IP "~/configure_worker.sh"
done

for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    ssh ubuntu@${external_ip} "kubectl get nodes --kubeconfig admin.kubeconfig"
done