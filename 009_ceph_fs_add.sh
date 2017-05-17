#!/bin/bash

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

set -o nounset
set -o errexit
set -o noclobber
set -o noglob


if [ $# -ne 4 ]; then
	echo "Usage: $0 <cluster_name> <fs_name> <metadata> <data>" 
	echo "Example: $0 ceph-test fancy-name-for-fs pool_metadata pool_data"
	exit 1
fi

CLUSTER_NAME=$1
FS_NAME=$2
METADATA_POOL=$3
DATA_POOL=$4

CPWD="/etc/ceph"
CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="${CPWD}/${CLUSTER_NAME}.mon.keyring"


# create new cephfs
ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} fs new ${FS_NAME} ${METADATA_POOL} ${DATA_POOL}


# list cepfs
ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} fs ls -f json-pretty




exit 0