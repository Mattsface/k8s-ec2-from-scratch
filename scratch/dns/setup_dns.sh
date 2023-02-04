#!/bin/bash


kubectl apply -f "https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml"
sleep 15

kubectl get pods -l k8s-app="kube-dns" -n kube-system

echo "Test DNS"
kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
sleep 15
POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
echo "Testing DNS resolution"
kubectl exec -ti "${POD_NAME}" -- nslookup kubernetes
kubectl delete pod ${POD_NAME}
