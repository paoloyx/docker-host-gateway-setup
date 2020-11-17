#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo -e "Usage \n\n ./set-docker-masquerading.sh [DOCKER_CIDR_FROM] [OUTPUT_NIC_IP_ADDRESS] \n\n Example: ./set-docker-masquerading.sh 172.17.0.0/16 192.168.1.36"
    exit 1
fi

DOCKER_CIDR_FROM=$1
OUTPUT_NIC_IP_ADDRESS=$3

# Manage masquerading
iptables -t nat -D POSTROUTING 1
iptables -t nat -A POSTROUTING -s $DOCKER_CIDR_FROM -j SNAT --to-source $OUTPUT_NIC_IP_ADDRESS
echo -e "Masquerade traffic from $DOCKER_CIDR_FROM using ip address: $OUTPUT_NIC_IP_ADDRESS"
iptables -t nat -vnL POSTROUTING
echo -e "\n"