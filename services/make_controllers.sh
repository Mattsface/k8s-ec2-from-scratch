#!/bin/bash

# WIP ssh etcd build commands to control nodes

for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')

    # install etc from tar
    if ! scp "scripts/install_etcd.sh" ubuntu@${EXTERNAL_IP}:~/; then
        echo "failed to scp install_etcd.sh to ${INSTANCE}"
        exit 1
    fi
    ssh ubuntu@$EXTERNAL_IP "~/install_etcd.sh"

    # configure etcd
    if ! scp "scripts/configure_etcd.sh" ubuntu@${EXTERNAL_IP}:~/; then
        echo "failed to scp configured_etcd.sh to ${INSTANCE}"
        exit 1
    fi
    ssh ubuntu@$EXTERNAL_IP "~/configure_etcd.sh"

    
done

# check cluster status
for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    echo ""
    sleep 2
    ssh ubuntu@$EXTERNAL_IP "sudo ETCDCTL_API=3 etcdctl member list --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/kubernetes.pem --key=/etc/etcd/kubernetes-key.pem"
    echo ""
done

KUBERNETES_PUBLIC_ADDRESS=$(aws elbv2 describe-load-balancers --load-balancer-arns ${LOAD_BALANCER_ARN} --output text --query 'LoadBalancers[].DNSName')

for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    if ! scp "scripts/kubernetes_control.sh" ubuntu@${EXTERNAL_IP}:~/; then
        echo "failed to scp kubernetes_control.sh to ${INSTANCE}"
        exit 1
    fi
    ssh ubuntu@$EXTERNAL_IP "~/kubernetes_control.sh ${KUBERNETES_PUBLIC_ADDRESS}"
done

for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    echo "${INSTANCE} kube-apiserver kube-controller-manager kube-scheduler status"
    echo "------------------------------------------------------------------------"
    sleep 5
    ssh ubuntu@$EXTERNAL_IP "sudo systemctl status kube-apiserver"
    ssh ubuntu@$EXTERNAL_IP "sudo systemctl status kube-controller-manager"
    ssh ubuntu@$EXTERNAL_IP "sudo systemctl status kube-scheduler"
    ssh ubuntu@$EXTERNAL_IP "kubectl cluster-info --kubeconfig admin.kubeconfig"
done

sleep 5
for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    if ! scp "scripts/configure_rbac.sh" ubuntu@${EXTERNAL_IP}:~/; then
        echo "failed to scp configure_rbac.sh to ${INSTANCE}"
        exit 1
    fi
    ssh ubuntu@$EXTERNAL_IP "~/configure_rbac.sh"
done
sleep 10
curl -k --cacert ../certs/ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}/version