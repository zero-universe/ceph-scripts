#!/bin/bash

set -o nounset
set -o errexit
set -o noclobber
set -o noglob

if [ $# -ne 1 ]; then
	echo "Usage: $0 <cluster_name>" 
	echo "Example: $0 ceph-test " 
	exit 1
fi


CLUSTER_NAME=$1


ceph --cluster ${CLUSTER_NAME} auth list

echo "which entity should be deleted:"
read ENTITY

ceph --cluster ${CLUSTER_NAME} auth del ${ENTITY} 

echo "${ENTITY} has been created:"

ceph --cluster ${CLUSTER_NAME} auth get ${ENTITY}


exit 0
