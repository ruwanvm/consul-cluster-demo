#!/bin/sh

CURRENT_CONSUL_VERSION=$(cat consul_cluster.version)
CONSUL_SERVERS=3
CONSUL_CLIENTS=3
re='^[0-9]+$'

if [ "$CURRENT_CONSUL_VERSION" = "0.00.0" ]; then
    echo "######################################################################"
    echo "Consul cluster not running"
    echo "######################################################################"
    exit 0
else
    echo "######################################################################"
    echo "Scale Consul cluster running with ${CURRENT_CONSUL_VERSION}"
    echo "######################################################################"
    read -p "Consul servers: " CONSUL_SERVERS
    read -p "Consul clients: " CONSUL_CLIENTS
fi

if [ $? -eq 0 ]; then
    echo "######################################################################"
    echo "Scaling Consul servers to ${CONSUL_SERVERS}"
    echo "######################################################################"
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name consul_servers_auto_scaling_group --desired-capacity ${CONSUL_SERVERS} --profile "${AWS_PROFILE}"
    echo "######################################################################"
    echo "Scaling Consul clients to ${CONSUL_CLIENTS}"
    echo "######################################################################"
    aws autoscaling update-auto-scaling-group --auto-scaling-group-name consul_clients_auto_scaling_group --desired-capacity ${CONSUL_CLIENTS} --profile "${AWS_PROFILE}"
fi
