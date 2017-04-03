#!/bin/bash

# read http://docs.ceph.com/docs/master/install/manual-deployment/ for better understanding

if [ $# -ne 2 ]; then
	echo "Usage: $0 <cluster_name> <pool_name_to_add>" 
	echo "Example: $0 ceph-test data"
	exit 1
fi


CLUSTER_NAME=$1
POOL_NAME=$2

CPWD="/etc/ceph"
CLUSTER_CONF="${CPWD}/${CLUSTER_NAME}.conf"
MON_KEYRING="${CPWD}/${CLUSTER_NAME}.mon.keyring"


# find out pg_num

echo "PG_NUM = (Total_number_of_OSD * 100) / max_replication_count"
#echo "PGP_NUM = (Total_number_of_OSD * 100) / max_replication_count / all_pools"
echo ""
echo "How many osds do you have?"
read OSD_NUM
echo ""
echo "How many replica do you have?"
read REPLICA_NUM
echo ""
#echo "How many pools do you have?"
#read POOL_NUM

echo $((${OSD_NUM} * 100 / ${REPLICA_NUM}))
echo "now round it up to the next power of 2 - what is it:"
read PG_NUM
# in my usecase there is only one pool, so pg_num and pgp_num are identical!

# if you have more than one pool this is how you calculate pgp_num
# echo "How many pools will you have?"
# echo $((${OSD_NUM} * 100 / ${REPLICA_NUM} / ${POOL_NUM}))
# echo "now round it up to the next power of 2 - what is it:"
# read PGP_NUM


# add pool
ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd pool create ${POOL_NAME} ${PG_NUM} ${PG_NUM} replicated
# ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd pool create ${POOL_NAME} ${PG_NUM} ${PGP_NUM} replicated


# list pools
ceph --cluster ${CLUSTER_NAME} -c ${CLUSTER_CONF} osd lspool -f json-pretty



exit 0