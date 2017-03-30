#!/bin/bash 

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

echo "what's the cluster's name: "
read CLUSTER_NAME

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"

ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd crush add-bucket $(hostname -s) host
ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd crush move $(hostname -s) root=default


exit 0