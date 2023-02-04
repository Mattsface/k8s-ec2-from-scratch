#!/bin/bash

# WIP

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

# send encrpytion-config to controllers
for INSTANCE in controller-0 controller-1 controller-2; do
    EXTERNAL_IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${INSTANCE}" "Name=instance-state-name,Values=running" --output text --query 'Reservations[].Instances[].PublicIpAddress')
    if ! scp ${SSH_OPTIONS} encryption-config.yaml ubuntu@${EXTERNAL_IP}:~/; then
      echo "Failed to scp encryption-config to ${INSTANCE}"
      exit 1 
    fi
done