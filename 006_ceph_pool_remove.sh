#!/bin/bash

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

set -o nounset
set -o errexit
set -o noclobber
set -o noglob


if [ $# -ne 1 ]; then
	echo "Usage: $0 <cluster_name>" 
	echo "Example: $0 ceph-test"
	exit 1
fi


CLUSTER_NAME=$1


echo "this script removes a ceph pool"


# list pools
ceph --cluster ${CLUSTER_NAME} osd lspools -f json-pretty

echo "which pool od you intend to delete ?"
echo "just give the poolname"
read POOL_NAME


# remove pool
ceph --cluster ${CLUSTER_NAME} osd pool delete ${POOL_NAME} ${POOL_NAME} --yes-i-really-really-mean-it


# list pools again
ceph --cluster ${CLUSTER_NAME} osd lspools -f json-pretty


exit 0