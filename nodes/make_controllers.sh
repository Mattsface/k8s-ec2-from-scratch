#!/bin/bash

# WIP ssh etcd build commands to control nodes

SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers --load-balancer-arns ${LOAD_BALANCER_ARN} --output text --query 'LoadBalancers[].DNSName')


for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')

    # install etc from tar
    if ! scp ${SSH_OPTIONS} "scripts/configure_etcd.sh" ubuntu@${EXTERNAL_IP}:~/; then
        echo "failed to scp configure_controller.sh to ${INSTANCE}"
        exit 1
    fi

    if ! ssh ${SSH_OPTIONS} ubuntu@$EXTERNAL_IP "~/configure_etcd.sh"; then
        echo "configure_etcd.sh failed on ${INSTANCE}"
    fi

    
    # ssh ${SSH_OPTIONS} ubuntu@${EXTERNAL_IP} "screen -d -m sudo systemctl start etcd" &

done

for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    echo ""
    sleep 2
    ssh ${SSH_OPTIONS} ubuntu@$EXTERNAL_IP "sudo systemctl status etcd; sudo ETCDCTL_API=3 etcdctl member list --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/kubernetes.pem --key=/etc/etcd/kubernetes-key.pem"
    echo ""
done

for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')

    # install etc from tar
    if ! scp ${SSH_OPTIONS} "scripts/configure_controller.sh" ubuntu@${EXTERNAL_IP}:~/; then
        echo "failed to scp configure_controller.sh to ${INSTANCE}"
        exit 1
    fi

    if ! ssh ${SSH_OPTIONS} ubuntu@$EXTERNAL_IP "~/configure_controller.sh ${KUBERNETES_PUBLIC_ADDRESS}"; then
        echo "configure_controller.sh failed on ${INSTANCE}"
        exit 1
    fi
done

for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    ssh ${SSH_OPTIONS} ubuntu@$EXTERNAL_IP "sudo systemctl status kube-apiserver"
    ssh ${SSH_OPTIONS} ubuntu@$EXTERNAL_IP "sudo systemctl status kube-controller-manager"
    ssh ${SSH_OPTIONS} ubuntu@$EXTERNAL_IP "sudo systemctl status kube-scheduler"
    ssh ${SSH_OPTIONS} ubuntu@$EXTERNAL_IP "kubectl cluster-info --kubeconfig admin.kubeconfig"
done


sleep 10
curl -k --cacert ../certs/ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}/version