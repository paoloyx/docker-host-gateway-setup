#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo -e "Usage \n\n ./set-docker-network.sh [DOCKER_CIDR_FROM] [OUTPUT_NIC_DEV] [OUTPUT_NIC_IP_ADDRESS] \n\n Example: ./set-docker-network.sh 172.17.0.0/16 enp0s8 192.168.1.36"
    exit 1
fi

DOCKER_CIDR_FROM=$1
OUTPUT_NIC_DEV=$2
OUTPUT_NIC_IP_ADDRESS=$3

# clean up previous resources
echo -e "Cleaning resources on startup"
sed -i -e 's/1 docker//g' -e '/^$/d' /etc/iproute2/rt_tables
echo -e "Cleaned /etc/iproute2/rt_tables file\n"
while $(ip rule list | grep -q "$DOCKER_CIDR_FROM lookup docker"); do ip rule del from $DOCKER_CIDR_FROM lookup docker; done
echo -e "Cleaned ip rules"
ip route del default via $OUTPUT_NIC_IP_ADDRESS dev $OUTPUT_NIC_DEV table docker
echo -e "Cleaned ip routes"


# Create a new routing table just for docker
echo "1 docker" >> /etc/iproute2/rt_tables
echo "Added new 'docker' routing table\n"

# Add a rule stating any traffic from the docker0 bridge interface should use 
# the newly added docker routing table
echo -e "All traffic from $DOCKER_CIDR_FROM will be routed through 'docker' table"
ip rule add from $DOCKER_CIDR_FROM table docker
ip rule list
echo -e "\n"

# Add a route to the newly added docker routing table that dictates all traffic
# go out the $OUTPUT_NIC_IP_ADDRESS interface on $OUTPUT_NIC_DEV
ip route add default via $OUTPUT_NIC_IP_ADDRESS dev $OUTPUT_NIC_DEV table docker
echo -e "All traffic from 'docker' table will be forwarded to $OUTPUT_NIC_DEV device (ip address: $OUTPUT_NIC_IP_ADDRESS)"
ip route list table docker
echo -e "\n"

# Flush the route cache
ip route flush cache
echo -e "Flushed route cache\n"

# Manage masquerading
iptables -t nat -D POSTROUTING 1
iptables -t nat -A POSTROUTING -s $DOCKER_CIDR_FROM -j SNAT --to-source $OUTPUT_NIC_IP_ADDRESS
echo -e "Masquerade traffic from $DOCKER_CIDR_FROM using ip address: $OUTPUT_NIC_IP_ADDRESS"
iptables -t nat -vnL POSTROUTING
echo -e "\n"

# Set default ip address to which docker daemon should bind to --> $OUTPUT_NIC_IP_ADDRESS
echo -e "{\"ip\":\"$OUTPUT_NIC_IP_ADDRESS\"}" > /etc/docker/daemon.json
echo -e "New docker daemon config:"
cat /etc/docker/daemon.json
echo -e "\n"

# Restart the Docker daemon so it uses the correct network settings
# Note, I do this as I found Docker containers often won't be able
# to connect out if any changes to the network are made while it's     
# running

echo -e "Restarting Docker"
systemctl restart docker
echo -e "Done"