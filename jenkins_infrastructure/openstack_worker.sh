#!/bin/bash

# Create the build server used in the infrastructure

name=pipe_openstack
flavor=small
image=ubuntu16.04
key_name=master

# Boot server
openstack server create --flavor $flavor --image $image --key-name $key_name $name --wait
ip=$(openstack server show $name -c addresses -f value | cut -d " " -f 2)

timeout=0
until ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $ip exit 
do
	sleep 1
	timeout=$((timeout+1))
	if [ "$timeout" -gt 30 ]; then
		echo No connection made to instance, Exiting
		exit 1
	fi
done

# Copy jenkins key over to new server
echo "Copying ssh keys"
jen_pub_key=$(cat jenkins_public_key.txt)
ssh ubuntu@$ip "echo $jen_pub_key >> .ssh/authorized_keys"

# Install Jenkins java dependencies
echo "Installing java"
ssh ubuntu@$ip 'sudo apt-get update; sudo apt-get install -y openjdk-9-jre-headless'

# Install openstack dependencies
echo "Installing Openstack"
ssh ubuntu@$ip 'sudo apt-get install -y python-openstackclient'
