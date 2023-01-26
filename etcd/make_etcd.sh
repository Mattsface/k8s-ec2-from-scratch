#!/bin/bash

# WIP ssh etcd build commands to control nodes

for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')

    # install etc from tar
    scp "scripts/install_etcd.sh" ubuntu@${EXTERNAL_IP}:~/
    ssh ubuntu@$EXTERNAL_IP "~/install_etcd.sh"

    # configure etcd
    scp "scripts/configure_etcd.sh" ubuntu@${EXTERNAL_IP}:~/
    ssh ubuntu@$EXTERNAL_IP "~/configure_etcd.sh"

    
done

# check cluster status
for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    echo ""
    ssh ubuntu@$EXTERNAL_IP "etcdctl endpoint health"
    echo ""
done