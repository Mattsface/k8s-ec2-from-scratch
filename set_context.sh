#!/bin/bash

# WIP

KUBE_LB_DNS=$(aws elbv2 describe-load-balancers --names k8s-nlb --output text --query 'LoadBalancers[].DNSName')

kubectl config set-cluster "kubernetes-from-scratch" --certificate-authority="certs/ca-keys/ca.pem" --embed-certs="true" --server="https://${KUBE_LB_DNS}:443"
kubectl config set-credentials "admin" --client-certificate="certs/admin-keys/admin.pem" --client-key="certs/admin-keys/admin-key.pem"
kubectl config set-context "kubernetes-from-scratch" --cluster="kubernetes-from-scratch" --user="admin"
kubectl config use-context "kubernetes-from-scratch"

echo "Kubenetes Version"
echo "-----------------"
kubectl version
echo "Kubernetes Nodes"
echo "----------------"
kubectl get nodes
echo "Kubernetes config view"
echo "----------------"
kubectl config view