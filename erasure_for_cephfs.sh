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



echo "where should we enable ec_coded_cephfs ?"

# list pools
ceph --cluster ${CLUSTER_NAME} osd lspools -f json-pretty
read ECPOOL

# enable overwrites -> for rbd or cephfs
ceph osd pool set ${ECPOOL} allow_ec_overwrites true

# enable cephfs
ceph osd pool application enable ${ECPOOL} cephfs


exit 0