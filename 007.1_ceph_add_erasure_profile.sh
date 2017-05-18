#!/bin/bash

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding
# http://docs.ceph.com/docs/master/rados/operations/erasure-code-profile/
# http://docs.ceph.com/docs/master/rados/operations/erasure-code/

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


echo "profile name:"
read EPNAME

echo "value of k"
read DASK

echo "value of m"
read DASM

ceph --cluster ${CLUSTER_NAME} osd erasure-code-profile set ${EPNAME} ${DASK} ${DASM} ruleset-failure-domain=host
#ceph --cluster ${CLUSTER_NAME} osd erasure-code-profile set ${EPNAME} ${DASK} ${DASM} ruleset-failure-domain=rack