#!/bin/bash

ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=k8s-rt" --output text --query 'RouteTables[].RouteTableId')

for INSTANCE in worker-0 worker-1 worker-2; do
    INSTANCE_ID_IP="$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" --output text --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress]')"
    INSTANCE_ID="$(echo "${INSTANCE_ID_IP}" | cut -f1)"
    INSTANCE_IP="$(echo "${INSTANCE_ID_IP}" | cut -f2)"
    POD_CIDR="$(aws ec2 describe-instance-attribute --instance-id "${INSTANCE_ID}" --attribute userData --output text --query 'UserData.Value' | base64 --decode | tr "|" "\n" | grep "^pod-cidr" | cut -d'=' -f2)"
    echo "${INSTANCE_IP} ${POD_CIDR}"
    aws ec2 create-route --route-table-id "${ROUTE_TABLE_ID}" --destination-cidr-block "${POD_CIDR}" --instance-id "${INSTANCE_ID}" --output text --no-cli-pager
done

aws ec2 describe-route-tables --route-table-ids "${ROUTE_TABLE_ID}" --query 'RouteTables[].Routes' --output text --no-cli-pager
