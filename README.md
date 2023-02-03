# k8s-ec2-from-scratch
Build a AWS K8s cluster from free tier EC2

// TODO add comments, style, AWS configs



### Clone project
```
git clone https://github.com/Mattsface/k8s-ec2-from-scratch.git
```

### Deploy terraform infrastructure
```
cd terraform
terraform init
terraform plan
terraform apply
```

### Provision certs
```
cd certs
./make_certs.sh
```

### Provision configs
```
cd configs
./make_configs.sh
```

### Encryption 
```
cd encryption
./make_encryption.sh
```

### Build workers and controllers
```
cd nodes
./make_controllers.sh
./make_workers.sh
```

### Setup Kubernetes context
```
./set_context.sh
```

### Setup network for pods and services
```
cd network
./setup_network.sh
```
