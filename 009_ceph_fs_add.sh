#!/bin/bash

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

set -o nounset
set -o errexit
set -o noclobber
set -o noglob


#if [ $# -ne 4 ]; then
	#echo "Usage: $0 <cluster_name> <fs_name> <metadata> <data>" 
	#echo "Example: $0 ceph-test fancy-name-for-fs pool_metadata pool_data"
	#exit 1
#fi

if [ $# -ne 1 ]; then
	echo "Usage: $0 <cluster_name>" 
	echo "Example: $0 ceph-test"
	exit 1
fi

CLUSTER_NAME=$1
#FS_NAME=$2
#METADATA_POOL=$3
#DATA_POOL=$4


# list pools
ceph --cluster ${CLUSTER_NAME} osd lspools -f json-pretty

echo "which is the pool for meta_data?"
read METAPOOL

echo "which is the pool for data?"
read POOLDATA

echo "what's the cephfs's name?"
read FS_NAME

# create new cephfs
ceph --cluster ${CLUSTER_NAME} fs new ${FS_NAME} ${METAPOOL} ${POOLDATA}


# list cepfs
ceph --cluster ${CLUSTER_NAME} fs ls -f json-pretty




exit 0