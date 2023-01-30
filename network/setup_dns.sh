#!/bin/bash


kubectl apply -f "https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml"
sleep 15

kubectl get pods -l k8s-app="kube-dns" -n kube-system

echo "Test DNS"
echo ""
echo ""
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
echo "$POD_NAME"
