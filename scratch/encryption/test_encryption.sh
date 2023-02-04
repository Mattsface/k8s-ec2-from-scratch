#!/bin/bash


kubectl create secret generic kubernetes-from-scratch --from-literal="mykey=mydata"
EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=controller-0" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
ssh ubuntu@${EXTERNAL_IP} "sudo ETCDCTL_API=3 etcdctl get --endpoints=https://127.0.0.1:2379 --cacert=/etc/etcd/ca.pem --cert=/etc/etcd/kubernetes.pem --key=/etc/etcd/kubernetes-key.pem /registry/secrets/default/kubernetes-from-scratch | hexdump -C"
kubectl delete secrets kubernetes-from-scratch