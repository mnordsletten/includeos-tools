#!/bin/bash

# Script for creating the jenkins worker nodes on openstack


# Create names of hosts
number_of_nodes=2
node_prefix="pipe_worker_"
nodes=""
flavor=small
image=ubuntu16.04
key_name=master

for i in `seq 1 $number_of_nodes`
do
	nodes="$nodes $node_prefix$i"
done

# Create new hosts
ips=""
for node in $nodes
do
	openstack server create --flavor $flavor --image $image --key-name $key_name $node --wait
	ips="$ips $(openstack server show $node -c addresses -f value | cut -d " " -f 2)"
done

# Install required packages on hosts
for ip in $ips
do
	# Wait for ssh connection to be ready
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
	jen_pub_key=$(cat jenkins_public_key.txt)
	ssh ubuntu@$ip "echo $jen_pub_key >> .ssh/authorized_keys"

	# Install Jenkins java dependencies
	echo "Installing java"
	ssh ubuntu@$ip 'sudo apt-get update; sudo apt-get install -y openjdk-9-jre-headless'

	# Install puppet and require packages for running tests
	ssh ubuntu@$ip 'git clone https://github.com/includeos/includeos-tools.git; ./includeos-tools/puppet/install_puppet_and_test_client.sh'
done
