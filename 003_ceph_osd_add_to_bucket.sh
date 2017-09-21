#!/bin/bash 

set -o nounset
set -o errexit
set -o noclobber
set -o noglob


if [ $# -ne 1 ]; then
	echo "Usage: $0 <cluster_name>" 
	echo "Example: $0 ceph-test"
	exit 1
fi


# go to ceph config dir
CPWD="/etc/ceph"
cd ${CPWD}

CLUSTER_NAME=$1

CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"

ceph --cluster ${CLUSTER_NAME} osd crush add-bucket $(hostname -s) host
ceph --cluster ${CLUSTER_NAME} osd crush move $(hostname -s) root=default


if [ -d /etc/sysconfig ]; then
	echo "cluster=${CLUSTER_NAME}" >> /etc/sysconfig/ceph
fi


# set systemd files

COUNITF="ceph-osd@.service"
#CKUNITF="ceph-create-keys@.service"
UNITDIR="/usr/lib/systemd/system/"


# copy unit-files and replace clustername
sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${UNITDIR}${COUNITF} 
#sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${UNITDIR}${CKUNITF}

systemctl daemon-reload


exit 0
