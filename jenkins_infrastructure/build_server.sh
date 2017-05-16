#!/bin/bash

# Create the build server used in the infrastructure

name=pipe_build
flavor=large
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

# Install docker on remote machine
echo "Installing docker"
ssh ubuntu@$ip '
	git clone https://github.com/includeos/includeos-tools.git 
	cd includeos-tools/install 
	./install_docker.sh
	'

# Install web server
echo "Installing web server"
ssh ubuntu@$ip 'mkdir /home/ubuntu/file_hosting'
ssh ubuntu@$ip 'sudo docker run --name jenkins-nginx --restart=unless-stopped -v /home/ubuntu/file_hosting:/usr/share/nginx/html:ro -p 8080:80 -d nginx'
