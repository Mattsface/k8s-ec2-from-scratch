#!/bin/bash
SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

for INSTANCE in worker-0 worker-1 worker-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    if ! scp ${SSH_OPTIONS} "scripts/configure_worker.sh" ubuntu@${EXTERNAL_IP}:~/; then
        echo "failed to scp configure_worker.sh to ${INSTANCE}"
    fi
    ssh ${SSH_OPTIONS} ubuntu@$EXTERNAL_IP "~/configure_worker.sh"
done

# sleep for 10 for cluster to get up
sleep 10

for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    ssh ${SSH_OPTIONS} ubuntu@${EXTERNAL_IP} "kubectl get nodes --kubeconfig admin.kubeconfig"
done