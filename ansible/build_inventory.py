import boto3
import json
import re

ec2 = boto3.client('ec2')
response = ec2.describe_instances(Filters=[
        {
            'Name': 'instance-state-name',
            'Values': [
                'running',
            ]
        },
    ])

hosts = {}
for reservation in response['Reservations']:
    for instance in reservation['Instances']:

        public_ip = instance['PublicIpAddress']

        for tag in instance['Tags']:
            if tag['Key'] == "Name":

                host_name = tag['Value']
                hosts[host_name] = public_ip


with open("inventory", "w") as inventory:
    # Writing data to a file
    inventory.write("[controllers]\n")
    for key, value in hosts.items():
        match = re.search(r'^controller-\d', key)
        if match:
            inventory.write(value + '\n')

    inventory.write("[workers]\n")
    for key, value in hosts.items():
        match = re.search(r'^worker-\d', key)
        if match:
            inventory.write(value + '\n')