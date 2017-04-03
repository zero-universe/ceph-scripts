#!/bin/bash

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

if [ $# -ne 1 ]; then
	echo "Usage: $0 <cluster_name>" 
	echo "Example: $0 ceph-test"
	exit 1
fi


CLUSTER_NAME=$1

LMON=$(hostname -s)

CPWD="/etc/ceph"
CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="${CPWD}/${CLUSTER_NAME}.mon.keyring"

CMUNITF="ceph-mds@.service"
UNITDIR="/usr/lib/systemd/system/"


# create dirs
mkdir -p /var/lib/ceph/mds/${CLUSTER_NAME}-${LMON}


# create keyring
ceph-authtool --create-keyring /var/lib/ceph/mds/${CLUSTER_NAME}-${LMON}/keyring --gen-key -n mds.${LMON}


# import keyring and set caps
ceph auth add mds.${LMON} osd "allow rwx" mds "allow" mon "allow profile mds" -i /var/lib/ceph/mds/${CLUSTER_NAME}-${LMON}/keyring


# add to config
echo "[mds.{id}]" >> ${CLUSTER_CONF}
echo "host = ${LMON}" >> ${CLUSTER_CONF}
echo -n -e "\n" >> ${CLUSTER_CONF}


# set rights
chown -R ceph. /var/lib/ceph/mds/${CLUSTER_NAME}-${LMON}


# copy unit-files and replace clustername
sed -i "s/CLUSTER=ceph/CLUSTER=${CLUSTER_NAME}/g" ${UNITDIR}${CMUNITF} 

systemctl daemon-reload

systemctl start ceph-mds@${LMON}.service
systemctl enable ceph-mds@${LMON}.service


exit 0