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

echo "crush-failure-domain: host or osd ?"
read CFD

echo "crush-device-class: hdd or ssd ?"
read CDC

#ceph --cluster ${CLUSTER_NAME} osd erasure-code-profile set ${EPNAME} plugin=jerasure k=${DASK} m=${DASM} technique=reed_sol_van ruleset-failure-domain=host
##ceph --cluster ${CLUSTER_NAME} osd erasure-code-profile set ${EPNAME} k=${DASK} m=${DASM} crush-failure-domain=host crush-device-class=hdd
ceph --cluster ${CLUSTER_NAME} osd erasure-code-profile set ${EPNAME} k=${DASK} m=${DASM} crush-failure-domain=${CFD} plugin=jerasure crush-device-class=${CDC}
#ceph --cluster ${CLUSTER_NAME} osd erasure-code-profile set ${EPNAME} k=${DASK} m=${DASM} ruleset-failure-domain=rack

#technique={reed_sol_van|reed_sol_r6_op|cauchy_orig|cauchy_good|liberation|blaum_roth|liber8tion}

exit 0
