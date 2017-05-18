#!/bin/bash

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

set -o nounset
set -o errexit
set -o noclobber
set -o noglob

# all mds must be disabled before deleting cephfs!

if [ $# -ne 2 ]; then
	echo "Usage: $0 <cluster_name> <fs_name>" 
	echo "Example: $0 ceph-test fancy-name-for-fs"
	exit 1
fi

CLUSTER_NAME=$1
FS_NAME=$2


# create new cephfs
ceph --cluster ${CLUSTER_NAME} fs rm ${FS_NAME} --yes-i-really-mean-it


# list cepfs
ceph --cluster ${CLUSTER_NAME} fs ls -f json-pretty




exit 0