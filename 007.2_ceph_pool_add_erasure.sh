#!/bin/bash

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding


set -o nounset
set -o errexit
set -o noclobber
set -o noglob


if [ $# -ne 2 ]; then
	echo "Usage: $0 <cluster_name> <pool_name_to_add>" 
	echo "Example: $0 ceph-test data"
	exit 1
fi


CLUSTER_NAME=$1
POOL_NAME=$2


## find out pg_num
echo "take a look at this page: http://ceph.com/pgcalc/"

echo "desired pg_num"
read PG_NUM

echo "whats the name of your erasure profile"
ceph --cluster ${CLUSTER_NAME} osd erasure-code-profile ls
read EPNAME

# add pool
ceph --cluster ${CLUSTER_NAME} osd pool create ${POOL_NAME} ${PG_NUM} ${PG_NUM} erasure ${EPNAME}


# list pools
ceph --cluster ${CLUSTER_NAME} osd lspools -f json-pretty



exit 0