#!/bin/bash 

# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

echo "what's the cluster's name: "
read CLUSTER_NAME

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"

ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd crush add-bucket $(hostname -s) host
ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd crush move $(hostname -s) root=default


echo "cluster=${CLUSTER_NAME}" > /etc/sysconfig/ceph


# set systemd files

COUNITF="ceph-osd@.service"
CKUNITF="ceph-create-keys@.service"
UNITDIR="/usr/lib/systemd/system/"


# copy unit-files and replace clustername
sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${UNITDIR}${COUNITF} 
sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${UNITDIR}${CKUNITF}

systemctl daemon-reload


exit 0