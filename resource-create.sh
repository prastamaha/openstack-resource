#!/bin/bash

# SOURCE ADMIN-OPENRC

source ~/admin-openrc

# PROVIDER NET

openstack network create  --share --external \
  --provider-physical-network provider \
  --provider-network-type flat public-net

# PROVIDER SUBNET

PROVIDER_START_IP_ADDRESS=10.20.150.10
PROVIDER_END_IP_ADDRESS=10.20.150.254
PROVIDER_NETWORK_GATEWAY=10.20.150.1
DNS_RESOLVER=8.8.8.8
PROVIDER_NETWORK_CIDR=10.20.150.0/24

openstack subnet create --network public-net \
  --allocation-pool start=$PROVIDER_START_IP_ADDRESS,end=$PROVIDER_END_IP_ADDRESS \
  --dns-nameserver $DNS_RESOLVER --gateway $PROVIDER_NETWORK_GATEWAY \
  --subnet-range $PROVIDER_NETWORK_CIDR public-subnet

# OVERLAY NET

openstack network create private-net

# OVERLAY SUBNET

PRIVATE_NETWORK_CIDR=192.168.100.0/24
PRIVATE_START_IP_ADDRESS=192.168.100.10
PRIVATE_END_IP_ADDRESS=192.168.100.254
PRIVATE_NETWORK_GATEWAY=192.168.100.1
DNS_RESOLVER=8.8.8.8

openstack subnet create --network private-net \
  --allocation-pool start=$PRIVATE_START_IP_ADDRESS,end=$PRIVATE_END_IP_ADDRESS \
  --dns-nameserver $DNS_RESOLVER --gateway $PRIVATE_NETWORK_GATEWAY \
  --subnet-range $PRIVATE_NETWORK_CIDR private-subnet

#  CREATE ROUTER

openstack router create myrouter
openstack router set --external-gateway public-net myrouter
openstack router add subnet myrouter private-subnet

# DOWNLOAD CIRROS IMAGE

wget http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

# CREATE IMAGE

openstack image create --disk-format qcow2 --container-format bare \
  --public --file ./cirros-0.5.1-x86_64-disk.img cirros-0.5.1-x86_64-disk

openstack image create --disk-format qcow2 --container-format bare \
  --public --file ./bionic-server-cloudimg-amd64.img bionic-server-cloudimg-amd64

# CREATE FLAVOR

openstack flavor create --ram 512 --disk 5 --vcpus 1 --public small
openstack flavor create --ram 1024 --disk 10 --vcpus 2 --public medium

# CREATE SEC GROUP

openstack security group create allow-all-traffic --description 'Allow All Ingress Traffic'
openstack security group rule create --protocol icmp allow-all-traffic
openstack security group rule create --protocol tcp  allow-all-traffic
openstack security group rule create --protocol udp  allow-all-traffic

# CREATE KEYPAIR

openstack keypair create --public-key ~/.ssh/id_rsa.pub controller-key

# CREATE INSTANCE

openstack server create --flavor small \
  --image cirros-0.5.1-x86_64-disk \
  --key-name controller-key \
  --security-group allow-all-traffic \
  --network private-net \
  cirros0

openstack server create --flavor medium \
  --image bionic-server-cloudimg-amd64 \
  --key-name controller-key \
  --security-group allow-all-traffic \
  --network private-net \
  ubuntu0