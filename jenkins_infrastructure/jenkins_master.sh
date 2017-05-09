#!/bin/bash

# Create the jenkins server used in the infrastructure

name=pipe_jenkins
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

# Install docker on remote machine
echo "Installing docker"
ssh ubuntu@$ip '
	git clone https://github.com/includeos/includeos-tools.git 
	cd includeos-tools/install 
	./install_docker.sh
	'

echo Installing Jenkins
ssh ubuntu@$ip '
	mkdir ~/jenkins
	cd includeos-tools/install
	sudo docker run --name jenkins_includeos -d -p 8080:8080 -v /home/ubuntu/jenkins:/var/jenkins_home jenkins
	'
