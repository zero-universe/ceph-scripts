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

echo "name of new user:"
read USERNAME

echo "caps for mon: (r w x *)"
read MONCAPS

echo "caps for osd: (r w x *)"
read OSDCAPS

echo "caps for mds: (r w x *)"
read MDSCAPS

ceph --cluster ${CLUSTER_NAME} osd lspools -f json-pretty
echo "which pool should be accessible by ${USERNAME} ?"
read POOL

ceph --cluster ${CLUSTER_NAME} auth get-or-create client.${USERNAME} mon "allow ${MONCAPS}" osd "allow ${OSDCAPS} pool=${POOL}" mds "allow" -o client.${USERNAME}.keyring
#ceph auth caps client.${USERNAME} mon 'allow rw' osd 'allow rwx pool=liverpool'


echo "${USERNAME} has been created:"
ceph --cluster ${CLUSTER_NAME} auth get client.${USERNAME}


exit 0