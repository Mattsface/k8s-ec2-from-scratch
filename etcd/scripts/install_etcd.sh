#!/bin/bash

# Add tests
echo "Downloading etcd-v3.4.15"
wget -q --timestamping "https://github.com/etcd-io/etcd/releases/download/v3.4.15/etcd-v3.4.15-linux-amd64.tar.gz"
echo "Extracting etcd-v3.4.15"
tar -xvf etcd-v3.4.15-linux-amd64.tar.gz
echo "Moving etcd-v3.4.15 to /usr/local/bin"
sudo mv etcd-v3.4.15-linux-amd64/etcd* /usr/local/bin/